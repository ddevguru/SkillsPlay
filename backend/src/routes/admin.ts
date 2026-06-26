import { Router } from 'express';
import { z } from 'zod';
import { UserRole, Difficulty } from '@prisma/client';
import { prisma } from '../lib/prisma.js';
import { authenticate, requireAdmin, AuthRequest } from '../middleware/auth.js';
import { validateBody } from '../middleware/validate.js';
import { cacheDel } from '../lib/redis.js';

const router = Router();
router.use(authenticate, requireAdmin);

const pid = (v: string | string[]) => (Array.isArray(v) ? v[0] : v);

async function invalidateTrackCache() {
  await cacheDel('tracks:all', 'tracks:all:topics');
}

router.get('/users', async (req, res) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
  const [users, total] = await Promise.all([
    prisma.user.findMany({
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true, name: true, email: true, role: true,
        subscriptionStatus: true, xp: true, isBanned: true, createdAt: true,
      },
    }),
    prisma.user.count(),
  ]);
  res.json({ users, total, page, limit });
});

router.put('/user/:id/role', async (req: AuthRequest, res) => {
  const { role } = req.body;
  if (!Object.values(UserRole).includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  const id = pid(req.params.id);
  const user = await prisma.user.update({
    where: { id },
    data: { role },
  });
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'CHANGE_ROLE', target: id, metadata: { role } },
  });
  res.json(user);
});

router.put('/user/:id/ban', async (req: AuthRequest, res) => {
  const { banned } = req.body;
  const id = pid(req.params.id);
  const user = await prisma.user.update({
    where: { id },
    data: { isBanned: !!banned },
  });
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: banned ? 'BAN_USER' : 'UNBAN_USER', target: id },
  });
  res.json(user);
});

router.put('/user/:id/credits', async (req: AuthRequest, res) => {
  const { trackId, remaining } = req.body;
  const id = pid(req.params.id);
  const credit = await prisma.freePlayCredit.upsert({
    where: { userId_trackId: { userId: id, trackId } },
    create: { userId: id, trackId, remaining },
    update: { remaining },
  });
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'SET_CREDITS', target: id, metadata: { trackId, remaining } },
  });
  res.json(credit);
});

const lessonSchema = z.object({
  topicId: z.string().uuid(),
  title: z.string(),
  gameType: z.string(),
  difficulty: z.enum(['BASICS', 'INTERMEDIATE', 'ADVANCED']),
  configJson: z.record(z.unknown()),
  content: z.string(),
  points: z.number().int().positive().optional(),
  order: z.number().int().optional(),
});

router.post('/lessons', validateBody(lessonSchema), async (req: AuthRequest, res) => {
  const lesson = await prisma.lesson.create({ data: req.body });
  await invalidateTrackCache();
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'CREATE_LESSON', target: lesson.id },
  });
  res.status(201).json(lesson);
});

router.get('/lessons', async (req, res) => {
  const topicId = req.query.topicId as string | undefined;
  const lessons = await prisma.lesson.findMany({
    where: topicId ? { topicId } : undefined,
    orderBy: [{ topicId: 'asc' }, { order: 'asc' }],
    include: { topic: { select: { title: true, track: { select: { title: true } } } } },
    take: 200,
  });
  res.json(lessons);
});

router.delete('/lessons/:id', async (req: AuthRequest, res) => {
  const id = pid(req.params.id);
  await prisma.lesson.delete({ where: { id } });
  await invalidateTrackCache();
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'DELETE_LESSON', target: id },
  });
  res.json({ message: 'Lesson deleted' });
});

const trackSchema = z.object({
  slug: z.string().min(2).max(50),
  title: z.string().min(2),
  description: z.string().default(''),
  icon: z.string().optional(),
  isPremium: z.boolean().optional(),
  order: z.number().int().optional(),
});

router.post('/tracks', validateBody(trackSchema), async (req: AuthRequest, res) => {
  const track = await prisma.track.create({ data: req.body });
  await invalidateTrackCache();
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'CREATE_TRACK', target: track.id },
  });
  res.status(201).json(track);
});

const topicSchema = z.object({
  trackId: z.string().uuid(),
  title: z.string().min(2),
  slug: z.string().min(2).optional(),
  description: z.string().default(''),
  difficulty: z.enum(['BASICS', 'INTERMEDIATE', 'ADVANCED']).optional(),
  order: z.number().int().optional(),
});

router.post('/topics', validateBody(topicSchema), async (req: AuthRequest, res) => {
  const slug = req.body.slug || req.body.title.toLowerCase().replace(/\s+/g, '-');
  const topic = await prisma.topic.create({
    data: {
      trackId: req.body.trackId,
      title: req.body.title,
      slug,
      description: req.body.description ?? '',
      difficulty: req.body.difficulty ?? Difficulty.BASICS,
      order: req.body.order ?? 0,
    },
  });
  await invalidateTrackCache();
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'CREATE_TOPIC', target: topic.id },
  });
  res.status(201).json(topic);
});

router.put('/topics/:id', async (req: AuthRequest, res) => {
  const id = pid(req.params.id);
  const topic = await prisma.topic.update({
    where: { id },
    data: {
      title: req.body.title,
      description: req.body.description,
      difficulty: req.body.difficulty,
    },
  });
  await invalidateTrackCache();
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'UPDATE_TOPIC', target: id },
  });
  res.json(topic);
});

router.put('/lessons/:id', async (req: AuthRequest, res) => {
  const id = pid(req.params.id);
  const lesson = await prisma.lesson.update({ where: { id }, data: req.body });
  await invalidateTrackCache();
  await prisma.adminAuditLog.create({
    data: { adminId: req.user!.id, action: 'UPDATE_LESSON', target: id },
  });
  res.json(lesson);
});

router.get('/analytics', async (_req, res) => {
  const now = new Date();
  const dayAgo = new Date(now.getTime() - 86400000);
  const monthAgo = new Date(now.getTime() - 30 * 86400000);

  const [totalUsers, dau, mau, totalAttempts, activeSubscriptions, revenue] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { lastActiveAt: { gte: dayAgo } } }),
    prisma.user.count({ where: { lastActiveAt: { gte: monthAgo } } }),
    prisma.attempt.count(),
    prisma.user.count({ where: { subscriptionStatus: { in: ['BASIC', 'PRO'] } } }),
    prisma.subscriptionPayment.aggregate({
      where: { status: 'ACTIVE' },
      _sum: { amount: true },
    }),
  ]);

  const topTracks = await prisma.attempt.groupBy({
    by: ['lessonId'],
    _count: true,
    orderBy: { _count: { lessonId: 'desc' } },
    take: 10,
  });

  res.json({
    totalUsers,
    dau,
    mau,
    totalAttempts,
    activeSubscriptions,
    revenueCents: revenue._sum.amount ?? 0,
    topLessons: topTracks,
  });
});

router.get('/audit-log', async (req, res) => {
  const logs = await prisma.adminAuditLog.findMany({
    orderBy: { timestamp: 'desc' },
    take: 50,
    include: { admin: { select: { name: true, email: true } } },
  });
  res.json(logs);
});

export default router;
