# Hosting SkillPlay on Render

Blueprint for deploying the SkillPlay backend, PostgreSQL database, Redis, code sandbox, and admin panel on [Render](https://render.com).

## Architecture on Render

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter Web    │────▶│  skillplay-api   │────▶│  PostgreSQL     │
│  (static/CDN)   │     │  (Web Service)   │     │  (Render DB)    │
└─────────────────┘     └────────┬─────────┘     └─────────────────┘
┌─────────────────┐              │
│  Admin Panel    │──────────────┤     ┌─────────────────┐
│  (Static Site)  │              ├────▶│  Redis          │
└─────────────────┘              │     │  (Key Value)    │
                                 │     └─────────────────┘
                                 ▼
                        ┌──────────────────┐
                        │  skillplay-      │
                        │  sandbox         │
                        │  (Private Svc)   │
                        └──────────────────┘
```

## Quick deploy (Blueprint)

1. Push this repo to GitHub
2. In Render Dashboard → **Blueprints** → **New Blueprint Instance**
3. Connect the repo — Render reads `render.yaml` at the root
4. Set secret env vars when prompted (JWT secrets)
5. After deploy, run seed once via Render Shell:

```bash
cd backend && npm run db:seed
```

## Services defined in `render.yaml`

| Service | Type | Notes |
|---------|------|-------|
| `skillplay-db` | PostgreSQL | Free/starter tier; connection string auto-injected |
| `skillplay-redis` | Key Value (Redis) | For leaderboard cache |
| `skillplay-sandbox` | Private Web Service | No public URL; Python + Node + Java |
| `skillplay-api` | Web Service | Express API + Socket.IO on same port |
| `skillplay-admin` | Static Site | Vite build from `admin/` |

## Required environment variables

### skillplay-api

| Variable | Source |
|----------|--------|
| `DATABASE_URL` | Linked from `skillplay-db` |
| `REDIS_URL` | Linked from `skillplay-redis` |
| `JWT_SECRET` | Generate: `openssl rand -hex 32` |
| `JWT_REFRESH_SECRET` | Generate: `openssl rand -hex 32` |
| `SANDBOX_URL` | Internal URL of `skillplay-sandbox` |
| `CORS_ORIGIN` | `https://your-admin.onrender.com,https://your-app.web.app` |
| `MOCK_PAYMENTS` | `true` (until Stripe is wired) |
| `NODE_ENV` | `production` |

### skillplay-sandbox

| Variable | Value |
|----------|-------|
| `PORT` | `4001` |
| `MEMORY_LIMIT_MB` | `128` |

### skillplay-admin (build-time)

| Variable | Value |
|----------|-------|
| `VITE_API_URL` | `https://skillplay-api.onrender.com` |

## Database migrations

The backend Dockerfile runs `prisma migrate deploy` on startup. For manual migration:

```bash
# Render Shell on skillplay-api
npx prisma migrate deploy
```

## Custom domains

1. **API**: Render Dashboard → skillplay-api → Settings → Custom Domain → `api.skillplay.dev`
2. **Admin**: skillplay-admin → Custom Domain → `admin.skillplay.dev`
3. Update `CORS_ORIGIN` and Flutter `API_URL` / `WS_URL` dart-defines

## Socket.IO on Render

Render supports WebSockets on web services. Configure Flutter:

```bash
flutter build web \
  --dart-define=API_URL=https://api.skillplay.dev \
  --dart-define=WS_URL=https://api.skillplay.dev
```

Socket.IO path: `/ws` (already configured in backend).

## Sandbox networking

Set `skillplay-sandbox` as a **Private Service** and use Render's internal hostname:

```
SANDBOX_URL=http://skillplay-sandbox:4001
```

Only `skillplay-api` can reach the sandbox — user code never hits the public internet from the runner.

## Cost estimate (starter)

| Service | ~Monthly |
|---------|----------|
| PostgreSQL Starter | $7 |
| Web Service (API) Starter | $7 |
| Private Service (Sandbox) Starter | $7 |
| Static Site (Admin) | Free |
| Key Value (Redis) | $10 |
| **Total** | **~$31/mo** |

Free tiers available for development (DB expires after 90 days on free plan).

## CI/CD with Render

Render auto-deploys on push to `main`. Pair with GitHub Actions (`.github/workflows/ci.yml`) to run tests before merge; Render deploys after merge.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| API can't reach sandbox | Verify private service name in `SANDBOX_URL` |
| WebSocket fails | Ensure using `wss://` with HTTPS custom domain |
| Prisma migrate fails | Check `DATABASE_URL` uses `?sslmode=require` if needed |
| CORS errors | Add exact frontend origin to `CORS_ORIGIN` (no trailing slash) |
| Cold starts | Upgrade to paid tier or use health check cron ping |

## Manual deploy (without Blueprint)

```bash
# 1. Create PostgreSQL on Render, copy Internal Database URL
# 2. Create Web Service for backend:
#    Build: cd backend && npm install && npx prisma generate && npm run build
#    Start: cd backend && npx prisma migrate deploy && npm start
# 3. Create Private Web Service for sandbox:
#    Root: sandbox, Dockerfile path: Dockerfile
# 4. Create Static Site for admin:
#    Build: cd admin && npm install && npm run build
#    Publish: admin/dist
```
