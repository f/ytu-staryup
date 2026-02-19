import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  // Varsayılan admin hesabı oluştur
  const adminEmail = 'admin@ytu.edu.tr';
  const existingAdmin = await prisma.admin.findUnique({ where: { email: adminEmail } });

  if (!existingAdmin) {
    const hashedPassword = await bcrypt.hash('admin123', 10);
    await prisma.admin.create({
      data: {
        email: adminEmail,
        password: hashedPassword,
        name: 'Admin',
      },
    });
    console.log('✅ Varsayılan admin oluşturuldu: admin@ytu.edu.tr / admin123');
  } else {
    console.log('ℹ️  Admin zaten mevcut');
  }

  // Varsayılan sistem ayarları
  const defaults = [
    { key: 'REGISTRATION_BONUS_AMOUNT', value: '50' },
    { key: 'UPVOTE_CREDIT_AMOUNT', value: '2' },
    { key: 'APPLICATION_ACCEPTED_BONUS', value: '10' },
    { key: 'DEFAULT_APPLICATION_COST', value: '5' },
  ];

  for (const config of defaults) {
    await prisma.systemConfig.upsert({
      where: { key: config.key },
      update: {},
      create: config,
    });
  }
  console.log('✅ Sistem ayarları oluşturuldu');
}

main()
  .catch((e) => {
    console.error('❌ Seed hatası:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
