import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { addCredits, spendCredits, getConfigNumber, InsufficientCreditsError } from '../lib/credits.js';

export const applicationRouter = Router();

const applySchema = z.object({
  projectId: z.string().min(1, 'Proje ID gerekli'),
  role: z.string().min(1, 'Rol gerekli'),
  message: z.string().optional().default(''),
});

const updateStatusSchema = z.object({
  status: z.enum(['ACCEPTED', 'REJECTED']),
});

// Apply to a project
applicationRouter.post('/', authenticate, async (req: AuthRequest, res) => {
  try {
    const { projectId, role, message } = applySchema.parse(req.body);
    
    const project = await prisma.project.findUnique({ where: { id: projectId } });
    if (!project) {
      return res.status(404).json({ error: 'Proje bulunamadı' });
    }
    
    if (project.ownerId === req.userId) {
      return res.status(400).json({ error: 'Kendi projenize başvuramazsınız' });
    }
    
    const existingApplication = await prisma.application.findUnique({
      where: {
        projectId_applicantId: {
          projectId,
          applicantId: req.userId!,
        },
      },
    });
    
    if (existingApplication) {
      return res.status(400).json({ error: 'Bu projeye zaten başvurdunuz' });
    }

    // Başvuru kredi maliyetini düş
    if (project.applicationCost > 0) {
      try {
        await spendCredits(
          req.userId!,
          project.applicationCost,
          'APPLICATION_SPENT',
          `"${project.title}" projesine başvuru`,
          projectId
        );
      } catch (err) {
        if (err instanceof InsufficientCreditsError) {
          return res.status(400).json({ error: err.message });
        }
        throw err;
      }
    }
    
    const application = await prisma.application.create({
      data: {
        projectId,
        applicantId: req.userId!,
        role,
        message,
      },
      include: {
        project: {
          select: {
            id: true,
            title: true,
          },
        },
        applicant: {
          select: {
            id: true,
            name: true,
            avatarURL: true,
          },
        },
      },
    });
    
    res.status(201).json(application);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Get my applications
applicationRouter.get('/my', authenticate, async (req: AuthRequest, res) => {
  const applications = await prisma.application.findMany({
    where: { applicantId: req.userId },
    include: {
      project: {
        select: {
          id: true,
          title: true,
          category: true,
          owner: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
  
  res.json(applications);
});

// Get applications I received (for my projects)
applicationRouter.get('/received', authenticate, async (req: AuthRequest, res) => {
  const applications = await prisma.application.findMany({
    where: {
      project: {
        ownerId: req.userId,
      },
    },
    include: {
      project: {
        select: {
          id: true,
          title: true,
        },
      },
      applicant: {
        select: {
          id: true,
          name: true,
          email: true,
          avatarURL: true,
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
  
  res.json(applications);
});

// Update application status (accept/reject)
applicationRouter.patch('/:id/status', authenticate, async (req: AuthRequest, res) => {
  try {
    const { status } = updateStatusSchema.parse(req.body);
    
    const application = await prisma.application.findUnique({
      where: { id: req.params.id },
      include: {
        project: true,
      },
    });
    
    if (!application) {
      return res.status(404).json({ error: 'Başvuru bulunamadı' });
    }
    
    if (application.project.ownerId !== req.userId) {
      return res.status(403).json({ error: 'Bu başvuruyu değerlendirme yetkiniz yok' });
    }

    if (application.status === status) {
      return res.status(400).json({ error: 'Başvuru zaten bu durumda' });
    }
    
    const updated = await prisma.application.update({
      where: { id: req.params.id },
      data: { status },
      include: {
        applicant: {
          select: {
            id: true,
            name: true,
            avatarURL: true,
          },
        },
      },
    });

    const acceptedBonus = await getConfigNumber('APPLICATION_ACCEPTED_BONUS', 10);

    // Kabul edildiğinde kredi ver
    if (status === 'ACCEPTED') {
      await addCredits(
        application.applicantId,
        acceptedBonus,
        'APPLICATION_ACCEPTED',
        `"${application.project.title}" projesine kabul kredisi`,
        application.id
      );
    }

    // Kabul edildikten sonra reddedildiyse krediyi geri al
    if (status === 'REJECTED' && application.status === 'ACCEPTED') {
      await spendCredits(
        application.applicantId,
        acceptedBonus,
        'APPLICATION_ACCEPTED',
        `"${application.project.title}" kabul kredisi iadesi`,
        application.id
      ).catch(() => {});
    }
    
    res.json(updated);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    throw error;
  }
});

// Delete application (withdraw)
applicationRouter.delete('/:id', authenticate, async (req: AuthRequest, res) => {
  const application = await prisma.application.findUnique({
    where: { id: req.params.id },
  });
  
  if (!application) {
    return res.status(404).json({ error: 'Başvuru bulunamadı' });
  }
  
  if (application.applicantId !== req.userId) {
    return res.status(403).json({ error: 'Bu başvuruyu silme yetkiniz yok' });
  }
  
  await prisma.application.delete({ where: { id: req.params.id } });
  
  res.status(204).send();
});
