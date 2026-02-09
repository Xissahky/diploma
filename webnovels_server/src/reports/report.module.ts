import { Module } from '@nestjs/common';
import { ReportsController } from './report.controller';
import { ReportsService } from './report.service';
import { PrismaService } from '../prisma/prisma.service';
import { RolesGuard } from '../auth/roles.guard';
import { Reflector } from '@nestjs/core';

@Module({
  controllers: [ReportsController],
  providers: [ReportsService, PrismaService, RolesGuard, Reflector],
})
export class ReportsModule {}
