import { Module } from '@nestjs/common';
import { LibraryController } from './library.controller';
import { LibraryService } from './library.service';
import { PrismaService } from '../prisma/prisma.service';
import { AchievementsModule } from '../achievements/achievements.module'; // 👈

@Module({
  imports: [AchievementsModule],
  controllers: [LibraryController],
  providers: [LibraryService, PrismaService],
  exports: [LibraryService],
})
export class LibraryModule {}
