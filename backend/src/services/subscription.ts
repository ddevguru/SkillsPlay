import { SubscriptionStatus } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

const FREE_PLAYS = parseInt(process.env.FREE_PLAYS_PER_TOPIC || '10', 10);

export const PLANS = {
  basic_monthly: { name: 'Basic Monthly', tier: SubscriptionStatus.BASIC, amount: 999, interval: 'month' },
  pro_monthly: { name: 'Pro Monthly', tier: SubscriptionStatus.PRO, amount: 1999, interval: 'month' },
  basic_yearly: { name: 'Basic Yearly', tier: SubscriptionStatus.BASIC, amount: 9999, interval: 'year' },
  pro_yearly: { name: 'Pro Yearly', tier: SubscriptionStatus.PRO, amount: 19999, interval: 'year' },
  student_basic: { name: 'Student Basic', tier: SubscriptionStatus.BASIC, amount: 499, interval: 'month', coupon: 'STUDENT50' },
} as const;

export type PlanId = keyof typeof PLANS;

export async function hasActiveSubscription(userId: string): Promise<boolean> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return false;
  const active = user.subscriptionStatus === SubscriptionStatus.BASIC || user.subscriptionStatus === SubscriptionStatus.PRO;
  const notExpired = !user.subscriptionEndsAt || user.subscriptionEndsAt > new Date();
  return active && notExpired;
}

export async function canPlayLesson(userId: string, trackId: string): Promise<{ allowed: boolean; reason?: string; remaining?: number }> {
  if (await hasActiveSubscription(userId)) {
    return { allowed: true };
  }

  const credit = await prisma.freePlayCredit.findUnique({
    where: { userId_trackId: { userId, trackId } },
  });

  const remaining = credit?.remaining ?? FREE_PLAYS;
  if (remaining <= 0) {
    return { allowed: false, reason: 'Free plays exhausted. Subscribe to continue.', remaining: 0 };
  }
  return { allowed: true, remaining };
}

export async function consumeFreePlay(userId: string, trackId: string): Promise<void> {
  if (await hasActiveSubscription(userId)) return;

  await prisma.freePlayCredit.upsert({
    where: { userId_trackId: { userId, trackId } },
    create: { userId, trackId, remaining: FREE_PLAYS - 1 },
    update: { remaining: { decrement: 1 } },
  });
}

export async function initializeFreeCredits(userId: string, trackIds: string[]): Promise<void> {
  for (const trackId of trackIds) {
    await prisma.freePlayCredit.upsert({
      where: { userId_trackId: { userId, trackId } },
      create: { userId, trackId, remaining: FREE_PLAYS },
      update: {},
    });
  }
}

function addInterval(date: Date, interval: string): Date {
  const result = new Date(date);
  if (interval === 'year') result.setFullYear(result.getFullYear() + 1);
  else result.setMonth(result.getMonth() + 1);
  return result;
}

export async function processMockCheckout(userId: string, planId: PlanId, coupon?: string): Promise<{
  paymentId: string;
  checkoutUrl: string;
  status: string;
}> {
  const plan = PLANS[planId];
  if (!plan) throw new Error('Invalid plan');

  let amount: number = plan.amount;
  if (coupon === 'STUDENT50' && 'coupon' in plan) {
    amount = Math.floor(amount * 0.5);
  }

  const payment = await prisma.subscriptionPayment.create({
    data: {
      userId,
      providerId: `mock_${Date.now()}`,
      planId,
      status: 'PENDING',
      amount,
    },
  });

  return {
    paymentId: payment.id,
    checkoutUrl: `/mock-checkout/${payment.id}?plan=${planId}`,
    status: 'pending',
  };
}

export async function completeMockPayment(paymentId: string): Promise<void> {
  const payment = await prisma.subscriptionPayment.findUnique({ where: { id: paymentId } });
  if (!payment || payment.status !== 'PENDING') throw new Error('Invalid payment');

  const plan = PLANS[payment.planId as PlanId];
  if (!plan) throw new Error('Invalid plan on payment');

  const startAt = new Date();
  const endAt = addInterval(startAt, plan.interval);

  await prisma.$transaction([
    prisma.subscriptionPayment.update({
      where: { id: paymentId },
      data: { status: 'ACTIVE', startAt, endAt },
    }),
    prisma.user.update({
      where: { id: payment.userId },
      data: { subscriptionStatus: plan.tier, subscriptionEndsAt: endAt },
    }),
  ]);
}

export async function refundMockPayment(paymentId: string): Promise<void> {
  const payment = await prisma.subscriptionPayment.findUnique({ where: { id: paymentId } });
  if (!payment) throw new Error('Payment not found');

  await prisma.$transaction([
    prisma.subscriptionPayment.update({
      where: { id: paymentId },
      data: { status: 'REFUNDED' },
    }),
    prisma.user.update({
      where: { id: payment.userId },
      data: { subscriptionStatus: SubscriptionStatus.FREE, subscriptionEndsAt: null },
    }),
  ]);
}
