import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { Category } from '@prisma/client';

export const projectRouter = Router();

const createProjectSchema = z.object({
  title: z.string().min(1, 'Başlık gerekli'),
  description: z.string().min(1, 'Açıklama gerekli'),
  category: z.nativeEnum(Category),
});

// Get all projects
projectRouter.get('/', async (req, res) => {
  const { category, sortBy } = req.query;
  
  const projects = await prisma.project.findMany({
    where: category ? { category: category as Category } : undefined,
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          avatarURL: true,
        },
      },
      _count: {
        select: {
          applications: true,
          upvotes: true,
        },
      },
      upvotes: {
        select: {
          userId: true,
        },
      },
    },
    orderBy: sortBy === 'popular' 
      ? { upvotes: { _count: 'desc' } }
      : { createdAt: 'desc' },
  });
  
  const formattedProjects = projects.map(project => ({
    id: project.id,
    title: project.title,
    description: project.description,
    category: project.category,
    createdAt: project.createdAt,
    owner: project.owner,
    upvoteCount: project._count.upvotes,
    applicationCount: project._count.applications,
    upvotedByIds: project.upvotes.map(u => u.userId),
  }));
  
  res.json(formattedProjects);
});

// Get single project
projectRouter.get('/:id', async (req, res) => {
  const project = await prisma.project.findUnique({
    where: { id: req.params.id },
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          email: true,
          bio: true,
          avatarURL: true,
          createdAt: true,
        },
      },
      applications: {
        include: {
          applicant: {
            select: {
              id: true,
              name: true,
              avatarURL: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      },
      _count: {
        select: {
          upvotes: true,
        },
      },
      upvotes: {
        select: {
          userId: true,
        },
      },
    },
  });
  
  if (!project) {
    return res.status(404).json({ error: 'Proje bulunamadı' });
  }
  
  res.json({
    id: project.id,
    title: project.title,
    description: project.description,
    category: project.category,
    createdAt: project.createdAt,
    owner: project.owner,
    upvoteCount: project._count.upvotes,
    upvotedByIds: project.upvotes.map(u => u.userId),
    applications: project.applications.map(app => ({
      id: app.id,
      role: app.role,
      message: app.message,
      status: app.status,
      createdAt: app.createdAt,
      applicant: app.applicant,
    })),
  });
});

// Create project
projectRouter.post('/', authenticate, async (req: AuthRequest, res) => {
  try {
    const { title, description, category } = createProjectSchema.parse(req.body);
    
    const project = await prisma.project.create({
      data: {
        title,
        description,
        category,
        ownerId: req.userId!,
      },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            avatarURL: true,
          },
        },
      },
    });
    
    res.status(201).json({
      id: project.id,
      title: project.title,
      description: project.description,
      category: project.category,
      createdAt: project.createdAt,
      owner: project.owner,
      upvoteCount: 0,
      applicationCount: 0,
      upvotedByIds: [],
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Update project
projectRouter.patch('/:id', authenticate, async (req: AuthRequest, res) => {
  const updateSchema = z.object({
    title: z.string().min(1).optional(),
    description: z.string().min(1).optional(),
    category: z.nativeEnum(Category).optional(),
  });
  
  try {
    const project = await prisma.project.findUnique({ where: { id: req.params.id } });
    
    if (!project) {
      return res.status(404).json({ error: 'Proje bulunamadı' });
    }
    
    if (project.ownerId !== req.userId) {
      return res.status(403).json({ error: 'Bu projeyi düzenleme yetkiniz yok' });
    }
    
    const data = updateSchema.parse(req.body);
    
    const updated = await prisma.project.update({
      where: { id: req.params.id },
      data,
    });
    
    res.json(updated);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Delete project
projectRouter.delete('/:id', authenticate, async (req: AuthRequest, res) => {
  const project = await prisma.project.findUnique({ where: { id: req.params.id } });
  
  if (!project) {
    return res.status(404).json({ error: 'Proje bulunamadı' });
  }
  
  if (project.ownerId !== req.userId) {
    return res.status(403).json({ error: 'Bu projeyi silme yetkiniz yok' });
  }
  
  await prisma.project.delete({ where: { id: req.params.id } });
  
  res.status(204).send();
});

// Toggle upvote
projectRouter.post('/:id/upvote', authenticate, async (req: AuthRequest, res) => {
  const projectId = req.params.id;
  const userId = req.userId!;
  
  const existingUpvote = await prisma.upvote.findUnique({
    where: {
      userId_projectId: { userId, projectId },
    },
  });
  
  if (existingUpvote) {
    // Remove upvote
    await prisma.upvote.delete({
      where: { id: existingUpvote.id },
    });
    
    const count = await prisma.upvote.count({ where: { projectId } });
    return res.json({ upvoted: false, upvoteCount: count });
  } else {
    // Add upvote
    await prisma.upvote.create({
      data: { userId, projectId },
    });
    
    const count = await prisma.upvote.count({ where: { projectId } });
    return res.json({ upvoted: true, upvoteCount: count });
  }
});

// Get user's projects
projectRouter.get('/user/:userId', async (req, res) => {
  const projects = await prisma.project.findMany({
    where: { ownerId: req.params.userId },
    include: {
      _count: {
        select: {
          applications: true,
          upvotes: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
  
  res.json(projects.map(p => ({
    ...p,
    upvoteCount: p._count.upvotes,
    applicationCount: p._count.applications,
  })));
});
