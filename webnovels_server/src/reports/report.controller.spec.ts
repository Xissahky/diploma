import { Test, TestingModule } from '@nestjs/testing';
import { ReportsController } from './report.controller';
import { ReportsService } from './report.service';

describe('ReportsController', () => {
  let controller: ReportsController;

  const serviceMock = {
    createReport: jest.fn(),
    listReports: jest.fn(),
    getReportWithTarget: jest.fn(),
    processReport: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ReportsController],
      providers: [{ provide: ReportsService, useValue: serviceMock }],
    }).compile();

    controller = module.get(ReportsController);
  });

  it('createReport should pass reporterId from req.user + body payload', async () => {
    serviceMock.createReport.mockResolvedValue({ id: 'r1' });

    const req: any = { user: { userId: 'u1' } };
    const body: any = {
      targetType: 'COMMENT',
      targetId: 'c1',
      reason: 'SPAM',
      description: 'spam',
    };

    const res = await controller.createReport(req, body);

    expect(serviceMock.createReport).toHaveBeenCalledWith({
      targetType: 'COMMENT',
      targetId: 'c1',
      reason: 'SPAM',
      description: 'spam',
      reporterId: 'u1',
    });
    expect(res).toEqual({ id: 'r1' });
  });

  it('listReports should forward status query to service', async () => {
    serviceMock.listReports.mockResolvedValue([{ id: 'r1' }]);

    const res = await controller.listReports('OPEN' as any);

    expect(serviceMock.listReports).toHaveBeenCalledWith('OPEN');
    expect(res).toEqual([{ id: 'r1' }]);
  });

  it('getReport should forward id to service', async () => {
    serviceMock.getReportWithTarget.mockResolvedValue({ report: { id: 'r1' }, target: null });

    const res = await controller.getReport('r1');

    expect(serviceMock.getReportWithTarget).toHaveBeenCalledWith('r1');
    expect(res).toEqual({ report: { id: 'r1' }, target: null });
  });

  it('processReport should pass adminId from req.user and body fields', async () => {
    serviceMock.processReport.mockResolvedValue({ id: 'r1', status: 'RESOLVED' });

    const req: any = { user: { userId: 'admin1' } };
    const body: any = { status: 'RESOLVED', action: 'delete_content', adminNote: 'ok' };

    const res = await controller.processReport('r1', req, body);

    expect(serviceMock.processReport).toHaveBeenCalledWith('r1', 'admin1', {
      status: 'RESOLVED',
      action: 'delete_content',
      adminNote: 'ok',
    });
    expect(res).toEqual({ id: 'r1', status: 'RESOLVED' });
  });
});
