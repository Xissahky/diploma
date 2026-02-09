import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RatingsService {
  constructor(private prisma: PrismaService) {}

  async setRating(userId: string, novelId: string, value: number) {
    if (!Number.isInteger(value) || value < 1 || value > 5) {
      throw new BadRequestException('Rating must be an integer 1..5');
    }

    await this.prisma.userRating.upsert({
      where: { userId_novelId: { userId, novelId } },
      update: { value },
      create: { userId, novelId, value },
    });

    const agg = await this.prisma.userRating.aggregate({
      where: { novelId },
      _avg: { value: true },
    });

    const avg = Number(agg._avg.value ?? 0);
    await this.prisma.novel.update({
      where: { id: novelId },
      data: { rating: Math.round(avg * 100) / 100 }, 
    });

    return {
      novelId,
      myRating: value,
      average: Math.round(avg * 100) / 100,
    };
  }

  getMyRating(userId: string, novelId: string) {
    return this.prisma.userRating.findUnique({
      where: { userId_novelId: { userId, novelId } },
      select: { value: true },
    });
  }

  async getAverage(novelId: string) {
    const agg = await this.prisma.userRating.aggregate({
      where: { novelId },
      _avg: { value: true },
    });
    const avg = Number(agg._avg.value ?? 0);
    return { novelId, average: Math.round(avg * 100) / 100 };
  }
}
