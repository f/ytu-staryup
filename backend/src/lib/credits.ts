import { CreditTransactionType } from '@prisma/client';
import { prisma } from './prisma.js';

export async function addCredits(
  userId: string,
  amount: number,
  type: CreditTransactionType,
  description = '',
  referenceId?: string
) {
  return prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { credits: { increment: amount } },
    }),
    prisma.creditTransaction.create({
      data: { userId, amount, type, description, referenceId },
    }),
  ]);
}

export async function spendCredits(
  userId: string,
  amount: number,
  type: CreditTransactionType,
  description = '',
  referenceId?: string
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { credits: true },
  });

  if (!user || user.credits < amount) {
    const current = user?.credits ?? 0;
    throw new InsufficientCreditsError(amount, current);
  }

  return prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { credits: { decrement: amount } },
    }),
    prisma.creditTransaction.create({
      data: { userId, amount: -amount, type, description, referenceId },
    }),
  ]);
}

export async function getConfig(key: string): Promise<string | null> {
  const config = await prisma.systemConfig.findUnique({ where: { key } });
  return config?.value ?? null;
}

export async function getConfigNumber(key: string, fallback: number): Promise<number> {
  const value = await getConfig(key);
  if (value === null) return fallback;
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? fallback : parsed;
}

export class InsufficientCreditsError extends Error {
  public required: number;
  public current: number;

  constructor(required: number, current: number) {
    super(`Yetersiz kredi. Gereken: ${required}, Mevcut: ${current}`);
    this.name = 'InsufficientCreditsError';
    this.required = required;
    this.current = current;
  }
}
