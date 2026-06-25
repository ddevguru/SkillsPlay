# Load Testing

SkillPlay uses [k6](https://k6.io/) for API and WebSocket load tests.

## Install k6

```bash
# Windows (choco)
choco install k6

# macOS
brew install k6

# Docker
docker run --rm -i grafana/k6 run - <load-tests/api-load.js
```

## Run tests

```bash
# API load test (ramps to 50 VUs)
k6 run load-tests/api-load.js

# Against staging
k6 run -e API_URL=https://skillplay-api.onrender.com load-tests/api-load.js

# WebSocket smoke test
k6 run -e API_URL=http://localhost:3000 -e WS_URL=ws://localhost:3000 load-tests/websocket-load.js
```

## Targets (Sprint 4)

| Metric | Target |
|--------|--------|
| p95 API latency | < 500ms @ 50 VUs |
| Error rate | < 5% |
| Health endpoint | 200 OK under load |

## CI integration

Add to GitHub Actions after deploy:

```yaml
- name: Load test staging
  run: k6 run -e API_URL=${{ secrets.STAGING_API_URL }} load-tests/api-load.js
```
