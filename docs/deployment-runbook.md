# Deployment Runbook

## Prerequisites

- AWS/GCP account with container registry
- PostgreSQL 16 (RDS/Aurora or Cloud SQL)
- Redis 7 (ElastiCache or Memorystore)
- Domain + TLS certificate

## Environment Variables (Production)

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `JWT_SECRET` | 64+ char random string |
| `JWT_REFRESH_SECRET` | Separate 64+ char random string |
| `SANDBOX_URL` | Internal sandbox service URL |
| `CORS_ORIGIN` | Comma-separated allowed origins |
| `MOCK_PAYMENTS` | Set `false` when enabling Stripe |
| `STRIPE_SECRET_KEY` | Stripe API key (future) |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret (future) |

## Deploy Steps

1. **Database**: Run `npx prisma migrate deploy` against production DB
2. **Seed** (first deploy only): `npm run db:seed`
3. **Backend**: Build Docker image, push to registry, deploy to ECS/EKS/Cloud Run
4. **Sandbox**: Deploy as separate service with no external network access
5. **Flutter Web**: `flutter build web --dart-define=API_URL=https://api.skillplay.dev`
6. **Flutter Mobile**: `flutter build appbundle` / `flutter build ipa`
7. **CDN**: Serve Flutter web build via CloudFront/Cloud CDN
8. **Monitoring**: Configure Sentry DSN, Prometheus scrape on `/health`

## Rollback

- Revert container image tag to previous version
- DB migrations are forward-only; test migrations in staging first

## Backups

- Enable automated RDS snapshots (daily, 7-day retention minimum)
- Export leaderboard data weekly for analytics
