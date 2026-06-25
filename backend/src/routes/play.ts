import { Router } from 'express';
import { z } from 'zod';
import { AttemptStatus, GameType, Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { validateBody } from '../middleware/validate.js';
import { canPlayLesson, consumeFreePlay } from '../services/subscription.js';
import { calculateXp } from '../services/scoring.js';
import { runCodeInSandbox, validatePuzzleAnswer } from '../services/sandbox.js';

const router = Router();

const startSchema = z.object({
  lessonId: z.string().uuid(),
});

const submitSchema = z.object({
  attemptId: z.string().uuid(),
  answer: z.unknown(),
  code: z.string().optional(),
  language: z.string().optional(),
  timeSeconds: z.number().optional(),
});

router.post('/start', authenticate, validateBody(startSchema), async (req: AuthRequest, res) => {
  const { lessonId } = req.body;
  const userId = req.user!.id;

  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { topic: { include: { track: true } }, testcases: true },
  });
  if (!lesson) return res.status(404).json({ error: 'Lesson not found' });

  const access = await canPlayLesson(userId, lesson.topic.trackId);
  if (!access.allowed) {
    return res.status(402).json({
      error: access.reason,
      code: 'FREE_PLAYS_EXHAUSTED',
      remaining: access.remaining,
    });
  }

  const attempt = await prisma.attempt.create({
    data: { userId, lessonId, status: AttemptStatus.IN_PROGRESS },
  });

  res.json({
    attemptId: attempt.id,
    lesson: {
      id: lesson.id,
      title: lesson.title,
      gameType: lesson.gameType,
      configJson: lesson.configJson,
      content: lesson.content,
      points: lesson.points,
      difficulty: lesson.difficulty,
    },
    remainingFreePlays: access.remaining,
  });
});

router.post('/submit', authenticate, validateBody(submitSchema), async (req: AuthRequest, res) => {
  const { attemptId, answer, code, language, timeSeconds } = req.body;
  const userId = req.user!.id;

  const attempt = await prisma.attempt.findFirst({
    where: { id: attemptId, userId },
    include: {
      lesson: {
        include: { topic: { include: { track: true } }, testcases: true },
      },
    },
  });
  if (!attempt) return res.status(404).json({ error: 'Attempt not found' });
  if (attempt.status !== AttemptStatus.IN_PROGRESS) {
    return res.status(400).json({ error: 'Attempt already submitted' });
  }

  const lesson = attempt.lesson;
  const config = lesson.configJson as Record<string, unknown>;
  let passed = false;
  let score = 0;
  let runtimeInfo: Record<string, unknown> = {};

  const codingTypes: GameType[] = [GameType.CODE_COMPLETION, GameType.TIMED_CHALLENGE];
  if (codingTypes.includes(lesson.gameType) && code && language) {
    const sandboxResult = await runCodeInSandbox({
      language,
      code,
      testcases: lesson.testcases,
      timeLimitMs: (config.timeLimitSeconds as number) ? (config.timeLimitSeconds as number) * 1000 : 5000,
    });
    passed = sandboxResult.passed;
    const passedCount = sandboxResult.results.filter((r) => r.passed).length;
    score = lesson.testcases.length > 0 ? Math.round((passedCount / lesson.testcases.length) * lesson.points) : 0;
    runtimeInfo = { sandbox: sandboxResult };
  } else {
    passed = await validatePuzzleAnswer(config, answer);
    score = passed ? lesson.points : 0;
    runtimeInfo = { answer };
  }

  const user = await prisma.user.findUnique({ where: { id: userId } });
  const xpEarned = calculateXp({
    difficulty: lesson.difficulty,
    score,
    maxScore: lesson.points,
    timeSeconds: timeSeconds ?? 0,
    timeLimitSeconds: (config.timeLimitSeconds as number) ?? 300,
    streakDays: user?.streakDays ?? 0,
    passed,
  });

  const status = passed ? AttemptStatus.PASSED : AttemptStatus.FAILED;

  await prisma.$transaction(async (tx) => {
    await tx.attempt.update({
      where: { id: attemptId },
      data: { score, xpEarned, status, runtimeInfo: runtimeInfo as Prisma.InputJsonValue, submittedAt: new Date(), syncedAt: new Date() },
    });

    if (passed) {
      await tx.user.update({
        where: { id: userId },
        data: { xp: { increment: xpEarned }, lastActiveAt: new Date() },
      });
      await consumeFreePlay(userId, lesson.topic.trackId);
    }
  });

  res.json({
    attemptId,
    passed,
    score,
    xpEarned,
    status,
    runtimeInfo,
  });
});

router.get('/result/:id', authenticate, async (req: AuthRequest, res) => {
  const id = String(req.params.id);
  const attempt = await prisma.attempt.findFirst({
    where: { id, userId: req.user!.id },
    include: { lesson: { select: { title: true, gameType: true, points: true } } },
  });
  if (!attempt) return res.status(404).json({ error: 'Result not found' });
  res.json(attempt);
});

export default router;
