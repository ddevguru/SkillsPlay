import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.API_URL || 'http://localhost:3000';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.05'],
  },
};

export function setup() {
  const signup = http.post(`${BASE_URL}/auth/signup`, JSON.stringify({
    name: 'Load Test User',
    email: `loadtest_${Date.now()}@skillplay.dev`,
    password: 'LoadTest123!',
  }), { headers: { 'Content-Type': 'application/json' } });
  const body = signup.json() as { accessToken?: string };
  return { token: body.accessToken };
}

export default function (data: { token?: string }) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${data.token}`,
  };

  const health = http.get(`${BASE_URL}/health`);
  check(health, { 'health ok': (r) => r.status === 200 });

  const tracks = http.get(`${BASE_URL}/tracks`, { headers });
  check(tracks, { 'tracks ok': (r) => r.status === 200 });

  const leaderboard = http.get(`${BASE_URL}/leaderboard/global`);
  check(leaderboard, { 'leaderboard ok': (r) => r.status === 200 });

  sleep(1);
}
