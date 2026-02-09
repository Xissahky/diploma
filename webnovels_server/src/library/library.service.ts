import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LibraryStatus } from '@prisma/client';
import { AchievementsService } from '../achievements/achievements.service';

@Injectable()
export class LibraryService {
  constructor(
    private prisma: PrismaService,
    private achievements: AchievementsService, 
  ) {}

  list(userId: string, status?: LibraryStatus) {
    return this.prisma.libraryEntry.findMany({
      where: { userId, ...(status ? { status } : {}) },
      include: { novel: { include: { author: true } } },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async upsert(
    userId: string,
    novelId: string,
    data: { status: LibraryStatus; favorite?: boolean; progress?: number },
  ) {
    if (!data.status) throw new BadRequestException('status is required');

    const entry = await this.prisma.libraryEntry.upsert({
      where: { userId_novelId: { userId, novelId } },
      update: {
        status: data.status,
        favorite: data.favorite ?? false,
        progress: data.progress ?? undefined,
      },
      create: {
        userId,
        novelId,
        status: data.status,
        favorite: data.favorite ?? false,
        progress: data.progress ?? 0,
      },
    });

    await this.achievements.checkUserProgress(userId);

    return entry;
  }

  remove(userId: string, novelId: string) {
    return this.prisma.libraryEntry.delete({
      where: { userId_novelId: { userId, novelId } },
    });
  }
}
