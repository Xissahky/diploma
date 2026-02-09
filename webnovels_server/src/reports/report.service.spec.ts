import { NotFoundException } from '@nestjs/common';
import { ReportsService } from './report.service';

describe('ReportsService', () => {
  let service: ReportsService;

  const prismaMock = {
    report: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    comment: {
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
    chapter: {
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new ReportsService(prismaMock);
  });

  describe('createReport', () => {
    it('should create report with proper payload', async () => {
      prismaMock.report.create.mockResolvedValue({ id: 'r1' });

      const res = await service.createReport({
        targetType: 'COMMENT',
        targetId: 'c1',
        reason: 'SPAM',
        description: 'spam links',
        reporterId: 'u1',
      } as any);

      expect(prismaMock.report.create).toHaveBeenCalledWith({
        data: {
          targetType: 'COMMENT',
          targetId: 'c1',
          reason: 'SPAM',
          description: 'spam links',
          reporterId: 'u1',
        },
      });
      expect(res).toEqual({ id: 'r1' });
    });
  });

  describe('listReports', () => {
    it('should list reports without status filter when status is undefined', async () => {
      prismaMock.report.findMany.mockResolvedValue([{ id: 'r1' }]);

      const res = await service.listReports(undefined);

      expect(prismaMock.report.findMany).toHaveBeenCalledWith({
        where: {},
        orderBy: { createdAt: 'desc' },
        include: {
          reporter: { select: { id: true, email: true, displayName: true } },
          admin: { select: { id: true, email: true, displayName: true } },
        },
      });
      expect(res).toEqual([{ id: 'r1' }]);
    });

    it('should list reports with status filter when provided', async () => {
      prismaMock.report.findMany.mockResolvedValue([{ id: 'r2' }]);

      const res = await service.listReports('OPEN' as any);

      expect(prismaMock.report.findMany).toHaveBeenCalledWith({
        where: { status: 'OPEN' },
        orderBy: { createdAt: 'desc' },
        include: {
          reporter: { select: { id: true, email: true, displayName: true } },
          admin: { select: { id: true, email: true, displayName: true } },
        },
      });
      expect(res).toEqual([{ id: 'r2' }]);
    });
  });

  describe('getReportWithTarget', () => {
    it('should throw NotFoundException when report not found', async () => {
      prismaMock.report.findUnique.mockResolvedValue(null);

      await expect(service.getReportWithTarget('r404')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('should return report + COMMENT target', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r1',
        targetType: 'COMMENT',
        targetId: 'c1',
      });
      prismaMock.comment.findUnique.mockResolvedValue({ id: 'c1', content: '...' });

      const res = await service.getReportWithTarget('r1');

      expect(prismaMock.comment.findUnique).toHaveBeenCalledWith({ where: { id: 'c1' } });
      expect(res).toEqual({
        report: { id: 'r1', targetType: 'COMMENT', targetId: 'c1' },
        target: { id: 'c1', content: '...' },
      });
    });

    it('should return report + CHAPTER target (with novel included)', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r2',
        targetType: 'CHAPTER',
        targetId: 'ch1',
      });
      prismaMock.chapter.findUnique.mockResolvedValue({
        id: 'ch1',
        title: 'Chapter 1',
        novel: { id: 'n1', authorId: 'u2' },
      });

      const res = await service.getReportWithTarget('r2');

      expect(prismaMock.chapter.findUnique).toHaveBeenCalledWith({
        where: { id: 'ch1' },
        include: { novel: true },
      });

      expect(res).toEqual({
        report: { id: 'r2', targetType: 'CHAPTER', targetId: 'ch1' },
        target: { id: 'ch1', title: 'Chapter 1', novel: { id: 'n1', authorId: 'u2' } },
      });
    });

    it('should return report + null target for unknown targetType', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r3',
        targetType: 'SOMETHING_ELSE',
        targetId: 'x',
      });

      const res = await service.getReportWithTarget('r3');

      expect(prismaMock.comment.findUnique).not.toHaveBeenCalled();
      expect(prismaMock.chapter.findUnique).not.toHaveBeenCalled();
      expect(res).toEqual({
        report: { id: 'r3', targetType: 'SOMETHING_ELSE', targetId: 'x' },
        target: null,
      });
    });
  });

  describe('processReport', () => {
    it('should throw NotFoundException when report not found', async () => {
      prismaMock.report.findUnique.mockResolvedValue(null);

      await expect(
        service.processReport('r404', 'admin1', { status: 'RESOLVED' as any }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('should delete COMMENT when action=delete_content and then update report', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r1',
        targetType: 'COMMENT',
        targetId: 'c1',
      });

      prismaMock.comment.delete.mockResolvedValue({});
      prismaMock.report.update.mockResolvedValue({ id: 'r1', status: 'RESOLVED' });

      const res = await service.processReport('r1', 'admin1', {
        action: 'delete_content',
        status: 'RESOLVED' as any,
        adminNote: 'deleted',
      });

      expect(prismaMock.comment.delete).toHaveBeenCalledWith({ where: { id: 'c1' } });

      expect(prismaMock.report.update).toHaveBeenCalledWith({
        where: { id: 'r1' },
        data: {
          status: 'RESOLVED',
          adminId: 'admin1',
          adminNote: 'deleted',
        },
        include: {
          reporter: { select: { id: true, email: true, displayName: true } },
          admin: { select: { id: true, email: true, displayName: true } },
        },
      });

      expect(res).toEqual({ id: 'r1', status: 'RESOLVED' });
    });

    it('should delete CHAPTER when action=delete_content and then update report', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r2',
        targetType: 'CHAPTER',
        targetId: 'ch1',
      });

      prismaMock.chapter.delete.mockResolvedValue({});
      prismaMock.report.update.mockResolvedValue({ id: 'r2', status: 'RESOLVED' });

      await service.processReport('r2', 'admin1', { action: 'delete_content' });

      expect(prismaMock.chapter.delete).toHaveBeenCalledWith({ where: { id: 'ch1' } });

      // если status не передан -> по коду ставится RESOLVED
      expect(prismaMock.report.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'r2' },
          data: expect.objectContaining({
            status: 'RESOLVED',
            adminId: 'admin1',
          }),
        }),
      );
    });

    it('should not delete anything when action=none and still update report', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r3',
        targetType: 'COMMENT',
        targetId: 'c9',
      });
      prismaMock.report.update.mockResolvedValue({ id: 'r3', status: 'RESOLVED' });

      await service.processReport('r3', 'admin1', { action: 'none' });

      expect(prismaMock.comment.delete).not.toHaveBeenCalled();
      expect(prismaMock.chapter.delete).not.toHaveBeenCalled();
      expect(prismaMock.report.update).toHaveBeenCalled();
    });

    it('action=ban_user should look up author for COMMENT (but not ban in current implementation)', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r4',
        targetType: 'COMMENT',
        targetId: 'c1',
      });
      prismaMock.comment.findUnique.mockResolvedValue({
        id: 'c1',
        authorId: 'u2',
      });
      prismaMock.report.update.mockResolvedValue({ id: 'r4', status: 'RESOLVED' });

      await service.processReport('r4', 'admin1', { action: 'ban_user' });

      expect(prismaMock.comment.findUnique).toHaveBeenCalledWith({ where: { id: 'c1' } });
      expect(prismaMock.report.update).toHaveBeenCalled();
    });

    it('action=ban_user should look up author for CHAPTER via novel.authorId', async () => {
      prismaMock.report.findUnique.mockResolvedValue({
        id: 'r5',
        targetType: 'CHAPTER',
        targetId: 'ch1',
      });
      prismaMock.chapter.findUnique.mockResolvedValue({
        id: 'ch1',
        novel: { authorId: 'u9' },
      });
      prismaMock.report.update.mockResolvedValue({ id: 'r5', status: 'RESOLVED' });

      await service.processReport('r5', 'admin1', { action: 'ban_user' });

      expect(prismaMock.chapter.findUnique).toHaveBeenCalledWith({
        where: { id: 'ch1' },
        include: { novel: true },
      });
      expect(prismaMock.report.update).toHaveBeenCalled();
    });
  });
});
