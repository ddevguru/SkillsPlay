const express = require('express');
const { execFile } = require('child_process');
const { writeFile, mkdir, rm } = require('fs/promises');
const { join } = require('path');
const { randomUUID } = require('crypto');
const os = require('os');

const app = express();
app.use(express.json({ limit: '512kb' }));

const PORT = process.env.PORT || 4001;
const WORK_DIR = join(os.tmpdir(), 'skillplay-sandbox');

const RUNNERS = {
  python: { ext: '.py', cmd: 'python', args: [] },
  javascript: { ext: '.js', cmd: 'node', args: [] },
  java: { ext: '.java', cmd: 'java', args: [] },
};

async function runPython(filePath, input, timeLimitMs) {
  return new Promise((resolve) => {
    const proc = execFile('python', [filePath], { timeout: timeLimitMs }, (err, stdout, stderr) => {
      resolve({
        actual: stdout?.trim() ?? '',
        error: err ? (stderr || err.message) : undefined,
        runtimeMs: 0,
      });
    });
    if (input) proc.stdin?.write(input);
    proc.stdin?.end();
  });
}

async function runJavaScript(filePath, input, timeLimitMs) {
  const wrappedPath = filePath.replace('.js', '.wrapped.js');
  const code = await require('fs/promises').readFile(filePath, 'utf8');
  const wrapped = `
const fs = require('fs');
const input = ${JSON.stringify(input)};
${code}
// Auto-invoke solve if exported
if (typeof solve === 'function') {
  try {
    const arr = JSON.parse(input);
    const result = solve(arr);
    console.log(String(result));
  } catch(e) { console.log(solve(input)); }
}
`;
  await writeFile(wrappedPath, wrapped);
  return new Promise((resolve) => {
    execFile('node', [wrappedPath], { timeout: timeLimitMs }, (err, stdout, stderr) => {
      resolve({
        actual: stdout?.trim() ?? '',
        error: err ? (stderr || err.message) : undefined,
        runtimeMs: 0,
      });
    });
  });
}

function wrapPythonCode(code) {
  return `${code}

import sys, json
if __name__ == "__main__":
    data = sys.stdin.read().strip()
    try:
        arr = json.loads(data) if data.startswith('[') else data
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
    const fileName = `solution${runner.ext}`;
    const filePath = join(jobDir, fileName);
    const finalCode = language === 'python' ? wrapPythonCode(code) : code;
    await writeFile(filePath, finalCode);

    const results = [];
    const start = Date.now();

    for (const tc of testcases) {
      let result;
      if (language === 'python') {
        result = await runPython(filePath, tc.input, timeLimitMs);
      } else if (language === 'javascript') {
        result = await runJavaScript(filePath, tc.input, timeLimitMs);
      } else {
        result = { actual: '', error: 'Language runner not implemented in MVP' };
      }

      const passed = !result.error && result.actual === tc.expected;
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
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  } finally {
    await rm(jobDir, { recursive: true, force: true }).catch(() => {});
  }
});

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'skillplay-sandbox' }));

app.listen(PORT, () => console.log(`Sandbox running on http://localhost:${PORT}`));
