const SANDBOX_URL = process.env.SANDBOX_URL || 'http://localhost:4001';

export interface SandboxResult {
  passed: boolean;
  results: Array<{
    input: string;
    expected: string;
    actual: string;
    passed: boolean;
    runtimeMs?: number;
    error?: string;
  }>;
  totalRuntimeMs: number;
}

export async function runCodeInSandbox(params: {
  language: string;
  code: string;
  testcases: Array<{ input: string; expectedOutput: string }>;
  timeLimitMs?: number;
  memoryLimitMb?: number;
}): Promise<SandboxResult> {
  const response = await fetch(`${SANDBOX_URL}/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      language: params.language,
      code: params.code,
      testcases: params.testcases.map((tc) => ({ input: tc.input, expected: tc.expectedOutput })),
      timeLimitMs: params.timeLimitMs ?? 5000,
      memoryLimitMb: params.memoryLimitMb ?? 128,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Sandbox error: ${err}`);
  }

  return response.json() as Promise<SandboxResult>;
}

export async function validatePuzzleAnswer(config: Record<string, unknown>, answer: unknown): Promise<boolean> {
  const expected = config.expectedAnswer ?? config.correctOrder ?? config.correctMapping;
  return JSON.stringify(answer) === JSON.stringify(expected);
}
