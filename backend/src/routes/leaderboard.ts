import { Router } from 'express';
import { LeaderboardPeriod, LeaderboardScope } from '@prisma/client';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { cacheGet, cacheSet } from '../lib/redis.js';

const router = Router();

async function getLeaderboard(scope: LeaderboardScope, period: LeaderboardPeriod, trackId?: string, friendIds?: string[]) {
  const where: Record<string, unknown> = { scope, period };
  if (trackId) where.trackId = trackId;
  if (friendIds) where.userId = { in: friendIds };

  const entries = await prisma.leaderboardEntry.findMany({
    where,
    orderBy: { score: 'desc' },
    take: 100,
    include: { user: { select: { id: true, name: true, avatarUrl: true, xp: true } } },
  });

  return entries.map((e, i) => ({ ...e, rank: i + 1 }));
}

router.get('/global', async (req, res) => {
  const period = (req.query.period as LeaderboardPeriod) || LeaderboardPeriod.ALL_TIME;
  const cacheKey = `lb:global:${period}`;
  const cached = await cacheGet<unknown>(cacheKey);
  if (cached) return res.json(cached);

  const entries = await getLeaderboard(LeaderboardScope.GLOBAL, period);
  await cacheSet(cacheKey, entries, 60);
  res.json(entries);
});

router.get('/friends', authenticate, async (req: AuthRequest, res) => {
  const userId = req.user!.id;
  const friendships = await prisma.friendship.findMany({
    where: {
      OR: [{ senderId: userId }, { receiverId: userId }],
      status: 'accepted',
    },
  });
  const friendIds = friendships.map((f) => (f.senderId === userId ? f.receiverId : f.senderId));
  friendIds.push(userId);

  const period = (req.query.period as LeaderboardPeriod) || LeaderboardPeriod.WEEKLY;
  const entries = await getLeaderboard(LeaderboardScope.FRIENDS, period, undefined, friendIds);
  res.json(entries);
});

router.get('/track/:id', async (req, res) => {
  const period = (req.query.period as LeaderboardPeriod) || LeaderboardPeriod.ALL_TIME;
  const entries = await getLeaderboard(LeaderboardScope.TRACK, period, req.params.id);
  res.json(entries);
});

export async function updateLeaderboardScore(userId: string, points: number, trackId?: string) {
  const scopes: Array<{ scope: LeaderboardScope; trackId?: string }> = [
    { scope: LeaderboardScope.GLOBAL },
    ...(trackId ? [{ scope: LeaderboardScope.TRACK, trackId }] : []),
  ];

  for (const { scope, trackId: tid } of scopes) {
    for (const period of Object.values(LeaderboardPeriod)) {
      await prisma.leaderboardEntry.upsert({
        where: {
          scope_period_userId_trackId: {
            scope,
            period,
            userId,
            trackId: tid ?? null,
          } as never,
        },
        create: { scope, period, userId, trackId: tid, score: points },
        update: { score: { increment: points } },
      });
    }
  }
}

export default router;
