const express = require('express');
const { execFile } = require('child_process');
const { writeFile, mkdir, rm, readFile } = require('fs/promises');
const { join } = require('path');
const { randomUUID } = require('crypto');
const os = require('os');

const app = express();
app.use(express.json({ limit: '512kb' }));

const PORT = process.env.PORT || 4001;
const WORK_DIR = join(os.tmpdir(), 'skillplay-sandbox');
const MEMORY_LIMIT_MB = parseInt(process.env.MEMORY_LIMIT_MB || '128', 10);

const RUNNERS = {
  python: { ext: '.py' },
  javascript: { ext: '.js' },
  java: { ext: '.java', className: 'Solution' },
};

function execWithLimit(cmd, args, opts = {}) {
  const timeout = opts.timeout ?? 5000;
  return new Promise((resolve) => {
    const proc = execFile(cmd, args, {
      timeout,
      maxBuffer: MEMORY_LIMIT_MB * 1024 * 1024,
      cwd: opts.cwd,
      env: { ...process.env, ...opts.env },
    }, (err, stdout, stderr) => {
      resolve({
        actual: stdout?.trim() ?? '',
        error: err ? (stderr || err.message) : undefined,
      });
    });
    if (opts.input != null) {
      proc.stdin?.write(opts.input);
      proc.stdin?.end();
    }
  });
}

async function runPython(filePath, input, timeLimitMs) {
  return execWithLimit('python3', [filePath], { input, timeout: timeLimitMs });
}

async function runJavaScript(filePath, input, timeLimitMs) {
  const code = await readFile(filePath, 'utf8');
  const wrapped = `
const input = ${JSON.stringify(input)};
${code}
if (typeof solve === 'function') {
  try {
    const arr = JSON.parse(input);
    console.log(String(solve(arr)));
  } catch(e) { console.log(String(solve(input))); }
}
`;
  const wrappedPath = filePath.replace('.js', '.wrapped.js');
  await writeFile(wrappedPath, wrapped);
  return execWithLimit('node', [wrappedPath], { timeout: timeLimitMs });
}

function wrapJavaCode(code) {
  if (code.includes('class Solution')) return code;
  return `import java.util.*;
class Solution {
  public static String solve(String input) throws Exception {
    ${code}
  }
  public static void main(String[] args) throws Exception {
    String data = new String(System.in.readAllBytes()).trim();
    System.out.print(solve(data));
  }
}`;
}

async function runJava(jobDir, code, input, timeLimitMs) {
  const sourcePath = join(jobDir, 'Solution.java');
  await writeFile(sourcePath, wrapJavaCode(code));

  const compile = await execWithLimit('javac', [sourcePath], { timeout: timeLimitMs, cwd: jobDir });
  if (compile.error) return compile;

  return execWithLimit('java', ['-cp', jobDir, 'Solution'], { input, timeout: timeLimitMs, cwd: jobDir });
}

function wrapPythonCode(code) {
  return `${code}

import sys, json
if __name__ == "__main__":
    data = sys.stdin.read().strip()
    try:
        arr = json.loads(data) if data.startswith('[') or data.startswith('{') else data
        if data.isdigit() or (data.startswith('-') and data[1:].isdigit()):
            arr = int(data)
        result = solve(arr) if 'solve' in dir() else None
        print(result)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
`;
}

app.post('/run', async (req, res) => {
  const { language, code, testcases, timeLimitMs = 5000 } = req.body;
  if (!language || !code || !testcases?.length) {
    return res.status(400).json({ error: 'language, code, and testcases required' });
  }

  const runner = RUNNERS[language];
  if (!runner) return res.status(400).json({ error: `Unsupported language: ${language}` });

  const jobId = randomUUID();
  const jobDir = join(WORK_DIR, jobId);

  try {
    await mkdir(jobDir, { recursive: true });
    const fileName = language === 'java' ? 'Solution.java' : `solution${runner.ext}`;
    const filePath = join(jobDir, fileName);

    if (language === 'python') {
      await writeFile(filePath, wrapPythonCode(code));
    } else if (language !== 'java') {
      await writeFile(filePath, code);
    }

    const results = [];
    const start = Date.now();

    for (const tc of testcases) {
      let result;
      if (language === 'python') {
        result = await runPython(filePath, tc.input, timeLimitMs);
      } else if (language === 'javascript') {
        result = await runJavaScript(filePath, tc.input, timeLimitMs);
      } else if (language === 'java') {
        result = await runJava(jobDir, code, tc.input, timeLimitMs);
      } else {
        result = { actual: '', error: `Unsupported language: ${language}` };
      }

      const passed = !result.error && String(result.actual) === String(tc.expected);
      results.push({
        input: tc.input,
        expected: tc.expected,
        actual: result.actual,
        passed,
        error: result.error,
      });
    }

    res.json({
      passed: results.every((r) => r.passed),
      results,
      totalRuntimeMs: Date.now() - start,
      language,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  } finally {
    await rm(jobDir, { recursive: true, force: true }).catch(() => {});
  }
});

app.get('/health', (_req, res) => res.json({
  status: 'ok',
  service: 'skillplay-sandbox',
  languages: Object.keys(RUNNERS),
}));

app.listen(PORT, () => console.log(`Sandbox running on http://localhost:${PORT}`));
