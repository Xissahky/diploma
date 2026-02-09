import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  ReportReason,
  ReportStatus,
  ReportTargetType,
} from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  createReport(params: {
    targetType: ReportTargetType;
    targetId: string;
    reason: ReportReason;
    description?: string;
    reporterId: string;
  }) {
    return this.prisma.report.create({
      data: {
        targetType: params.targetType,
        targetId: params.targetId,
        reason: params.reason,
        description: params.description,
        reporterId: params.reporterId,
      },
    });
  }

  listReports(status?: ReportStatus) {
    return this.prisma.report.findMany({
      where: status ? { status } : {},
      orderBy: { createdAt: 'desc' },
      include: {
        reporter: {
          select: { id: true, email: true, displayName: true },
        },
        admin: {
          select: { id: true, email: true, displayName: true },
        },
      },
    });
  }

  async getReportWithTarget(id: string) {
    const report = await this.prisma.report.findUnique({
      where: { id },
      include: {
        reporter: {
          select: { id: true, email: true, displayName: true },
        },
        admin: {
          select: { id: true, email: true, displayName: true },
        },
      },
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    let target: any = null;

    if (report.targetType === ReportTargetType.COMMENT) {
      target = await this.prisma.comment.findUnique({
        where: { id: report.targetId },
      });
    } else if (report.targetType === ReportTargetType.CHAPTER) {
      target = await this.prisma.chapter.findUnique({
        where: { id: report.targetId },
        include: { novel: true },
      });
    }

    return { report, target };
  }

  async processReport(
    id: string,
    adminId: string,
    params: {
      status?: ReportStatus;
      action?: 'none' | 'delete_content' | 'ban_user';
      adminNote?: string;
    },
  ) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) throw new NotFoundException('Report not found');

    if (params.action === 'delete_content') {
      if (report.targetType === ReportTargetType.COMMENT) {
        await this.prisma.comment.delete({ where: { id: report.targetId } });
      } else if (report.targetType === ReportTargetType.CHAPTER) {
        await this.prisma.chapter.delete({ where: { id: report.targetId } });
      }
    } else if (params.action === 'ban_user') {

      let authorId: string | null = null;

      if (report.targetType === ReportTargetType.COMMENT) {
        const comment = await this.prisma.comment.findUnique({
          where: { id: report.targetId },
        });
        authorId = comment?.authorId ?? null;
      } else if (report.targetType === ReportTargetType.CHAPTER) {
        const chapter = await this.prisma.chapter.findUnique({
          where: { id: report.targetId },
          include: { novel: true },
        });
        authorId = chapter?.novel.authorId ?? null;
      }

      if (authorId) {

      }
    }

    const updated = await this.prisma.report.update({
      where: { id },
      data: {
        status: params.status ?? ReportStatus.RESOLVED,
        adminId,
        adminNote: params.adminNote,
      },
      include: {
        reporter: {
          select: { id: true, email: true, displayName: true },
        },
        admin: {
          select: { id: true, email: true, displayName: true },
        },
      },
    });

    return updated;
  }
}
