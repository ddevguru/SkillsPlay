import { Difficulty } from '@prisma/client';

const BASE_XP: Record<Difficulty, number> = {
  BASICS: 10,
  INTERMEDIATE: 25,
  ADVANCED: 50,
};

export function calculateXp(params: {
  difficulty: Difficulty;
  score: number;
  maxScore: number;
  timeSeconds: number;
  timeLimitSeconds: number;
  streakDays: number;
  passed: boolean;
}): number {
  if (!params.passed) return Math.floor(BASE_XP[params.difficulty] * 0.2);

  const correctness = params.maxScore > 0 ? params.score / params.maxScore : 1;
  const speedBonus =
    params.timeLimitSeconds > 0
      ? Math.max(0, 1 - params.timeSeconds / params.timeLimitSeconds) * 0.3
      : 0;
  const streakMultiplier = 1 + Math.min(params.streakDays, 30) * 0.02;

  const xp = BASE_XP[params.difficulty] * correctness * (1 + speedBonus) * streakMultiplier;
  return Math.round(xp);
}

export function calculateLeaderboardPoints(won: boolean, xpEarned: number): number {
  return won ? xpEarned + 50 : Math.floor(xpEarned * 0.3);
}
