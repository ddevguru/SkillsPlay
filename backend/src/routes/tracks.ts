import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { validateBody } from '../middleware/validate.js';
import { initializeFreeCredits } from '../services/subscription.js';
import { cacheGet, cacheSet } from '../lib/redis.js';

const router = Router();

router.get('/', async (req, res) => {
  const includeTopics = req.query.include === 'topics';
  const cacheKey = includeTopics ? 'tracks:all:topics' : 'tracks:all';
  const cached = await cacheGet<unknown>(cacheKey);
  if (cached) return res.json(cached);

  const tracks = await prisma.track.findMany({
    orderBy: { order: 'asc' },
    include: {
      _count: { select: { topics: true } },
      ...(includeTopics ? { topics: { orderBy: { order: 'asc' }, select: { id: true, title: true, slug: true } } } : {}),
    },
  });

  await cacheSet(cacheKey, tracks, 600);
  res.json(tracks);
});

router.get('/lessons/:id', authenticate, async (req: AuthRequest, res) => {
  const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
  const lesson = await prisma.lesson.findUnique({
    where: { id },
    include: {
      topic: { include: { track: true } },
      testcases: { where: { isHidden: false }, orderBy: { order: 'asc' } },
    },
  });
  if (!lesson) return res.status(404).json({ error: 'Lesson not found' });
  res.json(lesson);
});

router.get('/:trackId/topics/:topicId/lessons', async (req, res) => {
  const lessons = await prisma.lesson.findMany({
    where: { topicId: req.params.topicId },
    orderBy: { order: 'asc' },
    select: {
      id: true, title: true, gameType: true, difficulty: true, points: true, order: true,
    },
  });
  res.json(lessons);
});

router.get('/:id', async (req, res) => {
  const track = await prisma.track.findUnique({
    where: { id: req.params.id },
    include: {
      topics: { orderBy: { order: 'asc' }, include: { _count: { select: { lessons: true } } } },
    },
  });
  if (!track) return res.status(404).json({ error: 'Track not found' });
  res.json(track);
});

router.get('/:id/topics', async (req, res) => {
  const topics = await prisma.topic.findMany({
    where: { trackId: req.params.id },
    orderBy: { order: 'asc' },
    include: { _count: { select: { lessons: true } } },
  });
  res.json(topics);
});

const selectTracksSchema = z.object({
  trackIds: z.array(z.string().uuid()).min(1),
});

router.post('/select', authenticate, validateBody(selectTracksSchema), async (req: AuthRequest, res) => {
  const { trackIds } = req.body;
  const userId = req.user!.id;

  await prisma.userTrack.createMany({
    data: trackIds.map((trackId: string) => ({ userId, trackId })),
    skipDuplicates: true,
  });
  await initializeFreeCredits(userId, trackIds);

  const credits = await prisma.freePlayCredit.findMany({ where: { userId } });
  res.json({ message: 'Tracks selected', credits });
});

export default router;
