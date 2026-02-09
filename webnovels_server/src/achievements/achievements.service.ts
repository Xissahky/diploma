import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class AchievementsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  async getAll() {
    return this.prisma.achievement.findMany({
      orderBy: { points: 'desc' },
    });
  }

  async getUserAchievements(userId: string) {
    return this.prisma.userAchievement.findMany({
      where: { userId },
      include: { achievement: true },
      orderBy: { earnedAt: 'desc' },
    });
  }

  async grant(userId: string, code: string) {
    const achievement = await this.prisma.achievement.findUnique({
      where: { code },
    });
    if (!achievement) return null;

    const already = await this.prisma.userAchievement.findUnique({
      where: {
        userId_achievementId: {
          userId,
          achievementId: achievement.id,
        },
      },
    });

    if (already) return null; 

    const earned = await this.prisma.userAchievement.create({
      data: { userId, achievementId: achievement.id },
      include: { achievement: true },
    });

    await this.notifications.create(userId, NotificationType.ACHIEVEMENT_UNLOCKED, {
      title: achievement.title,
      description: achievement.description,
      points: achievement.points,
    });

    return earned;
  }

  async checkUserProgress(userId: string) {
    const libraryCount = await this.prisma.libraryEntry.count({ where: { userId } });
    const readCount = await this.prisma.libraryEntry.count({
      where: { userId, status: 'COMPLETED' },
    });

    if (libraryCount >= 5) await this.grant(userId, 'ADD_5_NOVELS');
    if (readCount >= 10) await this.grant(userId, 'READ_10_NOVELS');
  }
}
