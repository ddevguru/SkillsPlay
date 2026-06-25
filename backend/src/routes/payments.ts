import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { validateBody } from '../middleware/validate.js';
import {
  PLANS,
  PlanId,
  processMockCheckout,
  completeMockPayment,
  refundMockPayment,
  hasActiveSubscription,
} from '../services/subscription.js';

const router = Router();

const checkoutSchema = z.object({
  planId: z.enum(['basic_monthly', 'pro_monthly', 'basic_yearly', 'pro_yearly', 'student_basic']),
  coupon: z.string().optional(),
});

router.get('/plans', (_req, res) => {
  res.json(
    Object.entries(PLANS).map(([id, plan]) => ({
      id,
      ...plan,
      priceDisplay: `$${(plan.amount / 100).toFixed(2)}`,
    }))
  );
});

router.post('/checkout', authenticate, validateBody(checkoutSchema), async (req: AuthRequest, res) => {
  const { planId, coupon } = req.body;
  const result = await processMockCheckout(req.user!.id, planId as PlanId, coupon);
  res.json({
    ...result,
    mock: true,
    message: 'Mock payment gateway — call POST /payments/mock/complete to simulate success',
  });
});

router.post('/mock/complete', authenticate, async (req: AuthRequest, res) => {
  const { paymentId } = req.body;
  if (!paymentId) return res.status(400).json({ error: 'paymentId required' });

  const payment = await prisma.subscriptionPayment.findFirst({
    where: { id: paymentId, userId: req.user!.id },
  });
  if (!payment) return res.status(404).json({ error: 'Payment not found' });

  await completeMockPayment(paymentId);
  const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
  res.json({
    message: 'Subscription activated (mock)',
    subscriptionStatus: user?.subscriptionStatus,
    subscriptionEndsAt: user?.subscriptionEndsAt,
  });
});

router.post('/mock/refund', authenticate, async (req: AuthRequest, res) => {
  const { paymentId } = req.body;
  if (!paymentId) return res.status(400).json({ error: 'paymentId required' });
  await refundMockPayment(paymentId);
  res.json({ message: 'Refund processed (mock)' });
});

router.get('/subscriptions/status', authenticate, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: {
      subscriptionStatus: true,
      subscriptionEndsAt: true,
      subscriptionPayments: { orderBy: { createdAt: 'desc' }, take: 5 },
    },
  });
  const active = await hasActiveSubscription(req.user!.id);
  res.json({ ...user, isActive: active, mockPayments: process.env.MOCK_PAYMENTS === 'true' });
});

// Stripe webhook placeholder — forwards to mock handler in dev
router.post('/webhooks/stripe', async (req, res) => {
  if (process.env.MOCK_PAYMENTS === 'true') {
    const { paymentId } = req.body;
    if (paymentId) await completeMockPayment(paymentId);
    return res.json({ received: true, mock: true });
  }
  res.status(501).json({ error: 'Stripe integration not configured — use mock payments' });
});

export default router;
