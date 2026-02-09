import { Test, TestingModule } from '@nestjs/testing';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

describe('NotificationsController', () => {
  let controller: NotificationsController;

  const serviceMock = {
    list: jest.fn(),
    markRead: jest.fn(),
    markAllRead: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [{ provide: NotificationsService, useValue: serviceMock }],
    }).compile();

    controller = module.get(NotificationsController);
  });

  describe('list', () => {
    it('should call list with unreadOnly=true when unread=1', async () => {
      serviceMock.list.mockResolvedValue([{ id: 'n1' }]);

      const result = await controller.list({ userId: 'u1' } as any, '1');

      expect(serviceMock.list).toHaveBeenCalledWith('u1', true);
      expect(result).toEqual([{ id: 'n1' }]);
    });

    it('should call list with unreadOnly=true when unread=true', async () => {
      serviceMock.list.mockResolvedValue([{ id: 'n2' }]);

      const result = await controller.list({ userId: 'u1' } as any, 'true');

      expect(serviceMock.list).toHaveBeenCalledWith('u1', true);
      expect(result).toEqual([{ id: 'n2' }]);
    });

    it('should call list with unreadOnly=false otherwise', async () => {
      serviceMock.list.mockResolvedValue([{ id: 'n3' }]);

      const result = await controller.list({ userId: 'u1' } as any, '0');

      expect(serviceMock.list).toHaveBeenCalledWith('u1', false);
      expect(result).toEqual([{ id: 'n3' }]);
    });
  });

  it('read should call markRead', async () => {
    serviceMock.markRead.mockResolvedValue({ id: 'n1', isRead: true });

    const result = await controller.read({ userId: 'u1' } as any, 'n1');

    expect(serviceMock.markRead).toHaveBeenCalledWith('u1', 'n1');
    expect(result).toEqual({ id: 'n1', isRead: true });
  });

  it('readAll should call markAllRead', async () => {
    serviceMock.markAllRead.mockResolvedValue({ count: 5 });

    const result = await controller.readAll({ userId: 'u1' } as any);

    expect(serviceMock.markAllRead).toHaveBeenCalledWith('u1');
    expect(result).toEqual({ count: 5 });
  });
});
