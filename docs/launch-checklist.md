# SkillPlay Launch Checklist

## Pre-launch

- [ ] All migrations applied on production DB (`npx prisma migrate deploy`)
- [ ] Seed data loaded (first deploy only)
- [ ] Environment secrets set (JWT, DATABASE_URL, REDIS_URL)
- [ ] CORS_ORIGIN includes Flutter web + admin panel URLs
- [ ] Sandbox service reachable from backend (private network on Render)
- [ ] Mock payments disabled or clearly labeled for beta
- [ ] SSL/TLS enabled on all public endpoints
- [ ] Health checks passing (`/health` on API and sandbox)

## Testing

- [ ] Backend unit tests pass (`npm test`)
- [ ] Flutter tests pass (`flutter test`)
- [ ] Admin panel builds (`cd admin && npm run build`)
- [ ] k6 load test passes against staging (`k6 run load-tests/api-load.js`)
- [ ] E2E: signup → select track → play 10 free games → blocked → subscribe (mock)
- [ ] E2E: two subscribed users → create/join room → start → submit → leaderboard

## Mobile & Web builds

```bash
# Flutter web
flutter build web --dart-define=API_URL=https://your-api.onrender.com --dart-define=WS_URL=https://your-api.onrender.com

# Android
flutter build appbundle --dart-define=API_URL=https://your-api.onrender.com

# iOS
flutter build ipa --dart-define=API_URL=https://your-api.onrender.com
```

## Monitoring

- [ ] Error tracking (Sentry DSN configured)
- [ ] Uptime monitor on `/health`
- [ ] Database backup schedule enabled (Render Postgres auto-backups)
- [ ] Alert channel configured (email/Slack)

## Post-launch

- [ ] Monitor DAU/MAU via admin dashboard
- [ ] Review audit log for admin actions
- [ ] Plan Stripe integration to replace mock payments
- [ ] Scale Render instances based on load test results
