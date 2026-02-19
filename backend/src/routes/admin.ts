import { Router } from 'express';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma.js';
import { authenticateAdmin, AdminRequest } from '../middleware/adminAuth.js';
import { addCredits, spendCredits, InsufficientCreditsError } from '../lib/credits.js';

export const adminRouter = Router();

// Admin Login
adminRouter.post('/login', async (req, res) => {
  const loginSchema = z.object({
    email: z.string().email(),
    password: z.string(),
  });

  try {
    const { email, password } = loginSchema.parse(req.body);

    const admin = await prisma.admin.findUnique({ where: { email } });
    if (!admin) {
      return res.status(401).json({ error: 'Admin bulunamadı' });
    }

    const valid = await bcrypt.compare(password, admin.password);
    if (!valid) {
      return res.status(401).json({ error: 'Geçersiz şifre' });
    }

    const token = jwt.sign(
      { adminId: admin.id, role: 'admin' },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    res.json({
      admin: { id: admin.id, email: admin.email, name: admin.name },
      token,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Dashboard stats
adminRouter.get('/dashboard', authenticateAdmin, async (req: AdminRequest, res) => {
  const [userCount, projectCount, applicationCount, creditStats, recentTransactions] =
    await Promise.all([
      prisma.user.count(),
      prisma.project.count(),
      prisma.application.count(),
      prisma.user.aggregate({
        _sum: { credits: true },
        _avg: { credits: true },
      }),
      prisma.creditTransaction.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, email: true } },
        },
      }),
    ]);

  res.json({
    userCount,
    projectCount,
    applicationCount,
    totalCredits: creditStats._sum.credits ?? 0,
    averageCredits: Math.round(creditStats._avg.credits ?? 0),
    recentTransactions,
  });
});

// List users
adminRouter.get('/users', authenticateAdmin, async (req: AdminRequest, res) => {
  const { search, page = '1', limit = '20' } = req.query;
  const skip = (parseInt(page as string, 10) - 1) * parseInt(limit as string, 10);
  const take = parseInt(limit as string, 10);

  const where = search
    ? {
        OR: [
          { name: { contains: search as string, mode: 'insensitive' as const } },
          { email: { contains: search as string, mode: 'insensitive' as const } },
        ],
      }
    : undefined;

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        name: true,
        bio: true,
        avatarURL: true,
        credits: true,
        createdAt: true,
        _count: { select: { projects: true, applications: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    }),
    prisma.user.count({ where }),
  ]);

  res.json({
    users: users.map(u => ({
      ...u,
      projectCount: u._count.projects,
      applicationCount: u._count.applications,
    })),
    total,
    page: parseInt(page as string, 10),
    totalPages: Math.ceil(total / take),
  });
});

// Get user detail with credit history
adminRouter.get('/users/:id', authenticateAdmin, async (req: AdminRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.params.id },
    select: {
      id: true,
      email: true,
      name: true,
      bio: true,
      avatarURL: true,
      credits: true,
      createdAt: true,
      _count: { select: { projects: true, applications: true } },
    },
  });

  if (!user) {
    return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
  }

  const transactions = await prisma.creditTransaction.findMany({
    where: { userId: req.params.id },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });

  res.json({ ...user, transactions });
});

// Add/remove credits for a user
adminRouter.post('/users/:id/credits', authenticateAdmin, async (req: AdminRequest, res) => {
  const schema = z.object({
    amount: z.number().int().min(1, 'Miktar en az 1 olmalı'),
    operation: z.enum(['add', 'remove']),
    description: z.string().min(1, 'Açıklama gerekli'),
  });

  try {
    const { amount, operation, description } = schema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { id: req.params.id } });
    if (!user) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    if (operation === 'add') {
      await addCredits(user.id, amount, 'ADMIN_ADJUSTMENT', description);
    } else {
      try {
        await spendCredits(user.id, amount, 'ADMIN_ADJUSTMENT', description);
      } catch (err) {
        if (err instanceof InsufficientCreditsError) {
          return res.status(400).json({ error: err.message });
        }
        throw err;
      }
    }

    const updated = await prisma.user.findUnique({
      where: { id: req.params.id },
      select: { id: true, credits: true },
    });

    res.json(updated);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// List projects
adminRouter.get('/projects', authenticateAdmin, async (req: AdminRequest, res) => {
  const { search, page = '1', limit = '20' } = req.query;
  const skip = (parseInt(page as string, 10) - 1) * parseInt(limit as string, 10);
  const take = parseInt(limit as string, 10);

  const where = search
    ? {
        OR: [
          { title: { contains: search as string, mode: 'insensitive' as const } },
          { description: { contains: search as string, mode: 'insensitive' as const } },
        ],
      }
    : undefined;

  const [projects, total] = await Promise.all([
    prisma.project.findMany({
      where,
      include: {
        owner: { select: { id: true, name: true, email: true } },
        _count: { select: { applications: true, upvotes: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    }),
    prisma.project.count({ where }),
  ]);

  res.json({
    projects: projects.map(p => ({
      id: p.id,
      title: p.title,
      description: p.description,
      category: p.category,
      applicationCost: p.applicationCost,
      createdAt: p.createdAt,
      owner: p.owner,
      upvoteCount: p._count.upvotes,
      applicationCount: p._count.applications,
    })),
    total,
    page: parseInt(page as string, 10),
    totalPages: Math.ceil(total / take),
  });
});

// Delete project (admin)
adminRouter.delete('/projects/:id', authenticateAdmin, async (req: AdminRequest, res) => {
  const project = await prisma.project.findUnique({ where: { id: req.params.id } });
  if (!project) {
    return res.status(404).json({ error: 'Proje bulunamadı' });
  }

  await prisma.project.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

// List credit transactions
adminRouter.get('/transactions', authenticateAdmin, async (req: AdminRequest, res) => {
  const { userId, type, page = '1', limit = '20' } = req.query;
  const skip = (parseInt(page as string, 10) - 1) * parseInt(limit as string, 10);
  const take = parseInt(limit as string, 10);

  const where: Record<string, unknown> = {};
  if (userId) where.userId = userId as string;
  if (type) where.type = type as string;

  const [transactions, total] = await Promise.all([
    prisma.creditTransaction.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    }),
    prisma.creditTransaction.count({ where }),
  ]);

  res.json({
    transactions,
    total,
    page: parseInt(page as string, 10),
    totalPages: Math.ceil(total / take),
  });
});

// Get system config
adminRouter.get('/config', authenticateAdmin, async (req: AdminRequest, res) => {
  const configs = await prisma.systemConfig.findMany({
    orderBy: { key: 'asc' },
  });
  res.json(configs);
});

// Update system config
adminRouter.put('/config/:key', authenticateAdmin, async (req: AdminRequest, res) => {
  const schema = z.object({
    value: z.string().min(1, 'Değer gerekli'),
  });

  try {
    const { value } = schema.parse(req.body);

    const config = await prisma.systemConfig.upsert({
      where: { key: req.params.key },
      update: { value },
      create: { key: req.params.key, value },
    });

    res.json(config);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});
