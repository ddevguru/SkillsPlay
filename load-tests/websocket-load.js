import http from 'k6/http';
import { check, sleep } from 'k6';
import ws from 'k6/ws';

const BASE_URL = __ENV.API_URL || 'http://localhost:3000';
const WS_URL = __ENV.WS_URL || 'ws://localhost:3000';

export const options = {
  vus: 10,
  duration: '1m',
  thresholds: {
    checks: ['rate>0.9'],
  },
};

export function setup() {
  const res = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
    email: 'demo@skillplay.dev',
    password: 'Demo1234!',
  }), { headers: { 'Content-Type': 'application/json' } });
  return { token: (res.json() as { accessToken: string }).accessToken };
}

export default function (data: { token: string }) {
  const url = `${WS_URL}/ws/?EIO=4&transport=websocket`;
  const res = ws.connect(url, { headers: { Authorization: `Bearer ${data.token}` } }, (socket) => {
    socket.on('open', () => {
      socket.send(JSON.stringify({ type: 'auth', token: data.token }));
      socket.send(JSON.stringify({ event: 'room:join', data: 'test-room-id' }));
      sleep(2);
      socket.close();
    });
    socket.on('message', () => {});
    socket.on('close', () => {});
  });

  check(res, { 'ws connected': (r) => r && r.status === 101 });
  sleep(1);
}
