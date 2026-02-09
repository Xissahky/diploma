import { Module } from '@nestjs/common';
import { RatingsService } from './ratings.service';
import { RatingsController } from './ratings.contoller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  providers: [RatingsService, PrismaService],
  controllers: [RatingsController],
  exports: [RatingsService],
})
export class RatingsModule {}
