import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ReportsService } from './report.service';
import { CreateReportDto } from './dto/create-report.dto';
import { UpdateReportAdminDto } from './dto/update-report-admin.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { ReportStatus } from '@prisma/client';

@ApiTags('reports')
@Controller('reports')
export class ReportsController {
  constructor(private reportsService: ReportsService) {}

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post()
  @ApiOperation({ summary: 'Create a report for chapter or comment' })
  async createReport(@Req() req: Request, @Body() body: CreateReportDto) {
    const userId = (req.user as any).userId as string;

    return this.reportsService.createReport({
      targetType: body.targetType,
      targetId: body.targetId,
      reason: body.reason,
      description: body.description,
      reporterId: userId,
    });
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @Get('admin')
  @ApiOperation({ summary: 'List reports (admin)' })
  async listReports(@Query('status') status?: ReportStatus) {
    return this.reportsService.listReports(status);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @Get('admin/:id')
  @ApiOperation({ summary: 'Get report details with target (admin)' })
  async getReport(@Param('id') id: string) {
    return this.reportsService.getReportWithTarget(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @Patch('admin/:id')
  @ApiOperation({ summary: 'Process report (admin)' })
  async processReport(
    @Param('id') id: string,
    @Req() req: Request,
    @Body() body: UpdateReportAdminDto,
  ) {
    const adminId = (req.user as any).userId as string;

    return this.reportsService.processReport(id, adminId, {
      status: body.status,
      action: body.action,
      adminNote: body.adminNote,
    });
  }
}
