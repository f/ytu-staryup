import { Router } from 'express';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { addCredits, getConfigNumber } from '../lib/credits.js';

export const authRouter = Router();

const registerSchema = z.object({
  email: z.string().email('Geçerli bir e-posta girin'),
  password: z.string().min(6, 'Şifre en az 6 karakter olmalı'),
  name: z.string().min(1, 'İsim gerekli'),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

// Register
authRouter.post('/register', async (req, res) => {
  try {
    const { email, password, name } = registerSchema.parse(req.body);
    
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'Bu e-posta zaten kayıtlı' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const bonusAmount = await getConfigNumber('REGISTRATION_BONUS_AMOUNT', 50);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        credits: bonusAmount,
      },
      select: {
        id: true,
        email: true,
        name: true,
        bio: true,
        avatarURL: true,
        credits: true,
        createdAt: true,
      },
    });

    await addCredits(user.id, bonusAmount, 'REGISTRATION_BONUS', 'Hoşgeldin kredisi');
    
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET!, {
      expiresIn: '30d',
    });
    
    res.status(201).json({ user, token });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Login
authRouter.post('/login', async (req, res) => {
  try {
    const { email, password } = loginSchema.parse(req.body);
    
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return res.status(401).json({ error: 'Kullanıcı bulunamadı' });
    }
    
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Geçersiz şifre' });
    }

    if (user.banned) {
      return res.status(403).json({ error: 'Hesabınız askıya alınmıştır' });
    }
    
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET!, {
      expiresIn: '30d',
    });
    
    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        bio: user.bio,
        avatarURL: user.avatarURL,
        credits: user.credits,
        createdAt: user.createdAt,
      },
      token,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Get current user
authRouter.get('/me', authenticate, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: {
      id: true,
      email: true,
      name: true,
      bio: true,
      avatarURL: true,
      credits: true,
      createdAt: true,
    },
  });
  
  if (!user) {
    return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
  }
  
  res.json(user);
});

// Update profile
authRouter.patch('/me', authenticate, async (req: AuthRequest, res) => {
  const updateSchema = z.object({
    name: z.string().min(1).optional(),
    bio: z.string().optional(),
    avatarURL: z.string().url().optional().nullable(),
  });
  
  try {
    const data = updateSchema.parse(req.body);
    
    const user = await prisma.user.update({
      where: { id: req.userId },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        bio: true,
        avatarURL: true,
        credits: true,
        createdAt: true,
      },
    });
    
    res.json(user);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});
