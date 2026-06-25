import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { prisma } from './lib/prisma.js';
import { verifyAccessToken } from './lib/jwt.js';
import { emitRoomEvent, setIo } from './lib/socket.js';
import { errorHandler } from './middleware/validate.js';

import authRoutes from './routes/auth.js';
import trackRoutes from './routes/tracks.js';
import playRoutes from './routes/play.js';
import leaderboardRoutes from './routes/leaderboard.js';
import paymentRoutes from './routes/payments.js';
import adminRoutes from './routes/admin.js';
import roomRoutes from './routes/rooms.js';

const app = express();
const httpServer = createServer(app);
const PORT = parseInt(process.env.PORT || '3000', 10);

const corsOriginEnv = (process.env.CORS_ORIGIN || 'http://localhost:8080,http://localhost:5173').trim();
const allowAllOrigins = corsOriginEnv === '*';
const corsOrigins = allowAllOrigins
  ? true
  : corsOriginEnv.split(',').map((o) => o.trim()).filter(Boolean);

app.use(helmet());
app.use(cors({ origin: corsOrigins, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 500,
    standardHeaders: true,
    legacyHeaders: false,
  })
);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'skillplay-api', timestamp: new Date().toISOString() });
});

app.use('/auth', authRoutes);
app.use('/tracks', trackRoutes);
app.use('/play', playRoutes);
app.use('/leaderboard', leaderboardRoutes);
app.use('/payments', paymentRoutes);
app.use('/admin', adminRoutes);
app.use('/rooms', roomRoutes);

app.use(errorHandler);

const io = new Server(httpServer, {
  cors: {
    origin: allowAllOrigins ? true : corsOrigins,
    credentials: true,
  },
  path: '/ws',
});

io.use((socket, next) => {
  const token = socket.handshake.auth?.token as string | undefined;
  if (!token) return next(new Error('Authentication required'));
  try {
    const payload = verifyAccessToken(token);
    socket.data.userId = payload.sub;
    next();
  } catch {
    next(new Error('Invalid token'));
  }
});

io.on('connection', (socket) => {
  socket.on('room:join', (roomId: string) => {
    socket.join(`room:${roomId}`);
    socket.to(`room:${roomId}`).emit('player:joined', { userId: socket.data.userId });
  });

  socket.on('room:leave', (roomId: string) => {
    socket.leave(`room:${roomId}`);
    socket.to(`room:${roomId}`).emit('player:left', { userId: socket.data.userId });
  });

  socket.on('room:progress', (data: { roomId: string; progress: number }) => {
    socket.to(`room:${data.roomId}`).emit('player:progress', {
      userId: socket.data.userId,
      progress: data.progress,
    });
  });

  socket.on('room:submit', (data: { roomId: string; score: number }) => {
    io.to(`room:${data.roomId}`).emit('player:submitted', {
      userId: socket.data.userId,
      score: data.score,
    });
  });

  socket.on('room:ready', (data: { roomId: string; ready: boolean }) => {
    io.to(`room:${data.roomId}`).emit('player:ready', {
      userId: socket.data.userId,
      ready: data.ready,
    });
  });

  socket.on('room:chat', (data: { roomId: string; message: string }) => {
    io.to(`room:${data.roomId}`).emit('room:chat', {
      userId: socket.data.userId,
      message: data.message,
      at: new Date().toISOString(),
    });
  });
});

setIo(io);

async function main() {
  await prisma.$connect();
  httpServer.listen(PORT, () => {
    console.log(`SkillPlay API running on http://localhost:${PORT}`);
    console.log(`WebSocket path: /ws`);
    console.log(`Mock payments: ${process.env.MOCK_PAYMENTS ?? 'true'}`);
  });
}

main().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});

export { io };
