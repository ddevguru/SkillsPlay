import { Request, Response, NextFunction } from 'express';
import { UserRole } from '@prisma/client';
import { verifyAccessToken, JwtPayload } from '../lib/jwt.js';
import { prisma } from '../lib/prisma.js';

export interface AuthRequest extends Request {
  user?: JwtPayload & { id: string };
}

export async function authenticate(req: AuthRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {
    const payload = verifyAccessToken(header.slice(7));
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || user.isBanned) {
      return res.status(401).json({ error: 'Invalid or banned account' });
    }
    req.user = { ...payload, id: payload.sub };
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function requireAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  if (req.user?.role !== UserRole.ADMIN) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

export function requireSubscription(req: AuthRequest, res: Response, next: NextFunction) {
  prisma.user
    .findUnique({ where: { id: req.user!.id } })
    .then((user: { subscriptionStatus: string; subscriptionEndsAt: Date | null } | null) => {
      if (!user) return res.status(401).json({ error: 'User not found' });
  const active = user.subscriptionStatus === 'BASIC' || user.subscriptionStatus === 'PRO';
      const notExpired = !user.subscriptionEndsAt || user.subscriptionEndsAt > new Date();
      if (!active || !notExpired) {
        return res.status(402).json({ error: 'Active subscription required', code: 'SUBSCRIPTION_REQUIRED' });
      }
      next();
    })
    .catch(() => res.status(500).json({ error: 'Internal server error' }));
}
