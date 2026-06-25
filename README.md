# SkillPlay

A mobile-first, cross-platform gamified learning platform where users pick programming tracks, progress through levels via interactive mini-games and coding challenges, and compete on leaderboards.

## Architecture

```
skillplay/
├── backend/          # Node.js + Express + Prisma + PostgreSQL API
├── frontend/         # Flutter (iOS/Android/Web) with Riverpod
├── sandbox/          # Isolated code execution service
├── docker-compose.yml
└── docs/
```

| Layer | Stack |
|-------|-------|
| Frontend | Flutter, Riverpod, GoRouter, Dio, Socket.IO |
| Backend | Node.js, Express, Prisma, PostgreSQL, Redis, Socket.IO |
| Payments | **Mock gateway** (Stripe/Razorpay ready for production) |
| Sandbox | Docker-isolated Python/JS code runner |

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 22+ (local dev)
- Flutter 3.38+ (mobile/web)

### 1. Start infrastructure

```bash
docker compose up -d postgres redis sandbox
```

### 2. Backend setup

```bash
cd backend
cp .env.example .env
npm install
npx prisma migrate dev --name init
npm run db:seed
npm run dev
```

API runs at `http://localhost:3000`

### 3. Flutter app

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@skillplay.dev | Admin123! |
| User | demo@skillplay.dev | Demo1234! |

## Core Features (MVP)

- **Auth**: Signup, login, JWT refresh, password reset
- **Tracks**: 9 programming tracks with topics and lessons
- **Game types**: Micro-lessons, puzzles, code completion, timed challenges
- **Free plays**: 10 free plays per track; blocked after limit with subscription CTA
- **Mock payments**: Checkout → complete flow without real charges
- **Leaderboards**: Global and friends rankings
- **Multiplayer**: 1v1 rooms (subscription-gated) with WebSocket sync
- **Admin panel**: REST API for content, users, analytics, audit logs
- **Offline**: Lesson caching and attempt queue for sync

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/signup` | Register |
| POST | `/auth/login` | Login |
| GET | `/tracks` | List tracks |
| POST | `/play/start` | Start a game session |
| POST | `/play/submit` | Submit answer/code |
| GET | `/leaderboard/global` | Global rankings |
| POST | `/payments/checkout` | Mock checkout |
| POST | `/payments/mock/complete` | Activate subscription |
| POST | `/rooms/create` | Create multiplayer room |
| GET | `/admin/analytics` | Admin analytics |

Full spec: [docs/openapi.yaml](docs/openapi.yaml)

## Mock Payment Flow

```bash
# 1. Checkout
curl -X POST http://localhost:3000/payments/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"planId":"pro_monthly"}'

# 2. Complete (simulates successful payment)
curl -X POST http://localhost:3000/payments/mock/complete \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"paymentId":"<id>"}'
```

## Docker (full stack)

```bash
docker compose up --build
```

## Testing

```bash
cd backend && npm test
```

## Sprint Roadmap

| Sprint | Focus |
|--------|-------|
| 0 ✅ | Architecture, auth, DB schema, Flutter skeleton |
| 1 | Single-player engine, sandbox, UI flows |
| 2 | Subscriptions, free-play enforcement, leaderboards |
| 3 | Admin panel UI, content import |
| 4 | Multiplayer scale, QA, launch |

## Security Notes

- Passwords hashed with bcrypt (12 rounds)
- JWT access tokens (15m) + refresh tokens (7d)
- Rate limiting on API
- Code sandbox runs in isolated temp dirs with timeouts
- No card data stored (mock payments only in MVP)

## License

Proprietary — SkillPlay
