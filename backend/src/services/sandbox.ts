const SANDBOX_URL = process.env.SANDBOX_URL || 'http://localhost:4001';
const USE_IDENTITY = process.env.SANDBOX_USE_IDENTITY === 'true';

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

async function getGcpIdentityToken(audience: string): Promise<string | null> {
  if (!USE_IDENTITY) return null;
  try {
    const res = await fetch(
      `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=${encodeURIComponent(audience)}`,
      { headers: { 'Metadata-Flavor': 'Google' } }
    );
    if (!res.ok) return null;
    return res.text();
  } catch {
    return null;
  }
}

async function sandboxFetch(body: Record<string, unknown>): Promise<Response> {
  const baseUrl = SANDBOX_URL.replace(/\/$/, '');
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };

  const token = await getGcpIdentityToken(baseUrl);
  if (token) headers.Authorization = `Bearer ${token}`;

  return fetch(`${baseUrl}/run`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
}

export async function runCodeInSandbox(params: {
  language: string;
  code: string;
  testcases: Array<{ input: string; expectedOutput: string }>;
  timeLimitMs?: number;
  memoryLimitMb?: number;
}): Promise<SandboxResult> {
  const response = await sandboxFetch({
    language: params.language,
    code: params.code,
    testcases: params.testcases.map((tc) => ({ input: tc.input, expected: tc.expectedOutput })),
    timeLimitMs: params.timeLimitMs ?? 5000,
    memoryLimitMb: params.memoryLimitMb ?? 128,
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
