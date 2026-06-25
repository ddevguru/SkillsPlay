import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken, parseExpiresIn } from '../lib/jwt.js';
import { validateBody } from '../middleware/validate.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { initializeFreeCredits } from '../services/subscription.js';

const router = Router();

const signupSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(8).max(128),
  trackIds: z.array(z.string().uuid()).optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

const passwordResetSchema = z.object({
  email: z.string().email(),
});

const passwordResetConfirmSchema = z.object({
  token: z.string(),
  password: z.string().min(8).max(128),
});

router.post('/signup', validateBody(signupSchema), async (req, res) => {
  const { name, email, password, trackIds } = req.body;

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return res.status(409).json({ error: 'Email already registered' });

  const hashedPassword = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: { name, email, hashedPassword },
  });

  if (trackIds?.length) {
    await prisma.userTrack.createMany({
      data: trackIds.map((trackId: string) => ({ userId: user.id, trackId })),
      skipDuplicates: true,
    });
    await initializeFreeCredits(user.id, trackIds);
  }

  const payload = { sub: user.id, email: user.email, role: user.role };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      token: refreshToken,
      expiresAt: parseExpiresIn(process.env.JWT_REFRESH_EXPIRES_IN || '7d'),
    },
  });

  res.status(201).json({
    user: { id: user.id, name: user.name, email: user.email, role: user.role, xp: user.xp },
    accessToken,
    refreshToken,
  });
});

router.post('/login', validateBody(loginSchema), async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user?.hashedPassword) return res.status(401).json({ error: 'Invalid credentials' });
  if (user.isBanned) return res.status(403).json({ error: 'Account banned' });

  const valid = await bcrypt.compare(password, user.hashedPassword);
  if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

  await prisma.user.update({ where: { id: user.id }, data: { lastActiveAt: new Date() } });

  const payload = { sub: user.id, email: user.email, role: user.role };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      token: refreshToken,
      expiresAt: parseExpiresIn(process.env.JWT_REFRESH_EXPIRES_IN || '7d'),
    },
  });

  res.json({
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      xp: user.xp,
      subscriptionStatus: user.subscriptionStatus,
    },
    accessToken,
    refreshToken,
  });
});

router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ error: 'Refresh token required' });

  try {
    const payload = verifyRefreshToken(refreshToken);
    const stored = await prisma.refreshToken.findUnique({ where: { token: refreshToken } });
    if (!stored || stored.expiresAt < new Date()) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    const accessToken = signAccessToken({ sub: payload.sub, email: payload.email, role: payload.role });
    res.json({ accessToken });
  } catch {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

router.post('/logout', authenticate, async (req: AuthRequest, res) => {
  const { refreshToken } = req.body;
  if (refreshToken) {
    await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
  }
  res.json({ message: 'Logged out' });
});

router.post('/password-reset', validateBody(passwordResetSchema), async (req, res) => {
  const user = await prisma.user.findUnique({ where: { email: req.body.email } });
  if (!user) return res.json({ message: 'If the email exists, a reset link was sent' });

  const token = uuidv4();
  await prisma.passwordResetToken.create({
    data: {
      userId: user.id,
      token,
      expiresAt: new Date(Date.now() + 3600000),
    },
  });

  // Mock: return token in dev; production would email it
  res.json({
    message: 'If the email exists, a reset link was sent',
    ...(process.env.NODE_ENV === 'development' ? { resetToken: token } : {}),
  });
});

router.post('/password-reset/confirm', validateBody(passwordResetConfirmSchema), async (req, res) => {
  const reset = await prisma.passwordResetToken.findUnique({ where: { token: req.body.token } });
  if (!reset || reset.used || reset.expiresAt < new Date()) {
    return res.status(400).json({ error: 'Invalid or expired reset token' });
  }

  const hashedPassword = await bcrypt.hash(req.body.password, 12);
  await prisma.$transaction([
    prisma.user.update({ where: { id: reset.userId }, data: { hashedPassword } }),
    prisma.passwordResetToken.update({ where: { id: reset.id }, data: { used: true } }),
  ]);

  res.json({ message: 'Password updated' });
});

router.get('/me', authenticate, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    include: {
      selectedTracks: { include: { track: true } },
      freePlayCredits: true,
      badges: { include: { badge: true } },
    },
  });
  if (!user) return res.status(404).json({ error: 'User not found' });
  const { hashedPassword: _, ...safe } = user;
  res.json(safe);
});

export default router;
