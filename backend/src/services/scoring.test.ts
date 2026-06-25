import { describe, it, expect } from 'vitest';
import { calculateXp, calculateLeaderboardPoints } from './scoring.js';
import { Difficulty } from '@prisma/client';

describe('scoring', () => {
  it('awards full XP for perfect fast completion', () => {
    const xp = calculateXp({
      difficulty: Difficulty.BASICS,
      score: 10,
      maxScore: 10,
      timeSeconds: 30,
      timeLimitSeconds: 300,
      streakDays: 5,
      passed: true,
    });
    expect(xp).toBeGreaterThan(10);
  });

  it('awards partial XP on failure', () => {
    const xp = calculateXp({
      difficulty: Difficulty.BASICS,
      score: 0,
      maxScore: 10,
      timeSeconds: 100,
      timeLimitSeconds: 300,
      streakDays: 0,
      passed: false,
    });
    expect(xp).toBe(2);
  });

  it('gives bonus leaderboard points to winner', () => {
    expect(calculateLeaderboardPoints(true, 30)).toBe(80);
    expect(calculateLeaderboardPoints(false, 30)).toBe(9);
  });
});
