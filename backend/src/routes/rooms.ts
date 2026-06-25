import { Router } from 'express';
import { z } from 'zod';
import { RoomStatus } from '@prisma/client';
import { prisma } from '../lib/prisma.js';
import { authenticate, requireSubscription, AuthRequest } from '../middleware/auth.js';
import { validateBody } from '../middleware/validate.js';
import { calculateLeaderboardPoints } from '../services/scoring.js';
import { updateLeaderboardScore } from './leaderboard.js';
import { emitRoomEvent } from '../lib/socket.js';

const router = Router();

const pid = (v: string | string[]) => (Array.isArray(v) ? v[0] : v);

function generateRoomCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

const createRoomSchema = z.object({
  lessonId: z.string().uuid().optional(),
  maxPlayers: z.number().int().min(2).max(4).optional(),
});

const joinRoomSchema = z.object({
  roomCode: z.string().length(6),
});

router.post('/create', authenticate, requireSubscription, validateBody(createRoomSchema), async (req: AuthRequest, res) => {
  const userId = req.user!.id;
  let roomCode = generateRoomCode();
  while (await prisma.multiplayerRoom.findUnique({ where: { roomCode } })) {
    roomCode = generateRoomCode();
  }

  const room = await prisma.multiplayerRoom.create({
    data: {
      hostId: userId,
      roomCode,
      lessonId: req.body.lessonId,
      maxPlayers: req.body.maxPlayers ?? 2,
      participants: { create: { userId } },
    },
    include: { participants: { include: { user: { select: { id: true, name: true } } } } },
  });

  res.status(201).json(room);
});

router.post('/join', authenticate, requireSubscription, validateBody(joinRoomSchema), async (req: AuthRequest, res) => {
  const userId = req.user!.id;
  const room = await prisma.multiplayerRoom.findUnique({
    where: { roomCode: req.body.roomCode.toUpperCase() },
    include: { participants: true },
  });

  if (!room) return res.status(404).json({ error: 'Room not found' });
  if (room.status !== RoomStatus.WAITING) return res.status(400).json({ error: 'Room not joinable' });
  if (room.participants.length >= room.maxPlayers) return res.status(400).json({ error: 'Room full' });
  if (room.participants.some((p) => p.userId === userId)) {
    return res.json(room);
  }

  const updated = await prisma.multiplayerRoom.update({
    where: { id: room.id },
    data: { participants: { create: { userId } } },
    include: { participants: { include: { user: { select: { id: true, name: true } } } } },
  });

  emitRoomEvent(room.id, 'player:joined', {
    userId,
    participants: updated.participants.map((p) => ({ id: p.user.id, name: p.user.name })),
  });

  res.json(updated);
});

router.get('/:roomId', authenticate, async (req: AuthRequest, res) => {
  const roomId = pid(req.params.roomId);
  const room = await prisma.multiplayerRoom.findUnique({
    where: { id: roomId },
    include: { participants: { include: { user: { select: { id: true, name: true } } } } },
  });
  if (!room) return res.status(404).json({ error: 'Room not found' });
  res.json(room);
});

router.post('/:roomId/start', authenticate, async (req: AuthRequest, res) => {
  const roomId = pid(req.params.roomId);
  const room = await prisma.multiplayerRoom.findUnique({
    where: { id: roomId },
    include: { participants: true },
  });
  if (!room) return res.status(404).json({ error: 'Room not found' });
  if (room.hostId !== req.user!.id) return res.status(403).json({ error: 'Only host can start' });
  if (room.participants.length < 2) return res.status(400).json({ error: 'Need at least 2 players' });

  const updated = await prisma.multiplayerRoom.update({
    where: { id: room.id },
    data: { status: RoomStatus.IN_PROGRESS, startedAt: new Date() },
  });
  emitRoomEvent(room.id, 'room:started', { roomId: room.id, lessonId: room.lessonId, startedAt: updated.startedAt });
  res.json(updated);
});

router.post('/:roomId/finish', authenticate, async (req: AuthRequest, res) => {
  const { scores } = req.body as { scores: Record<string, number> };
  const roomId = pid(req.params.roomId);
  const room = await prisma.multiplayerRoom.findUnique({
    where: { id: roomId },
    include: { participants: true },
  });
  if (!room || room.status !== RoomStatus.IN_PROGRESS) {
    return res.status(400).json({ error: 'Invalid room state' });
  }

  const entries = Object.entries(scores || {});
  const maxScore = Math.max(...entries.map(([, s]) => s), 0);
  const winners = entries.filter(([, s]) => s === maxScore).map(([id]) => id);

  await prisma.$transaction(async (tx) => {
    for (const p of room.participants) {
      const score = scores?.[p.userId] ?? 0;
      const won = winners.includes(p.userId) && winners.length === 1;
      await tx.roomParticipant.update({
        where: { id: p.id },
        data: { score, isWinner: won },
      });
      const lbPoints = calculateLeaderboardPoints(won, score);
      await updateLeaderboardScore(p.userId, lbPoints);
    }
    await tx.multiplayerRoom.update({
      where: { id: room.id },
      data: { status: RoomStatus.COMPLETED, endedAt: new Date() },
    });
  });

  emitRoomEvent(room.id, 'room:finished', { roomId: room.id, winners });

  res.json({ message: 'Match completed', winners });
});

export default router;
