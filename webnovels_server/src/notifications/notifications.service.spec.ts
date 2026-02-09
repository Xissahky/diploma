import { NotificationsService } from './notifications.service';
import { NotificationType } from '@prisma/client';

describe('NotificationsService', () => {
  let service: NotificationsService;

  const prismaMock = {
    notification: {
      create: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NotificationsService(prismaMock);
  });

  it('create should call prisma.notification.create', async () => {
    prismaMock.notification.create.mockResolvedValue({ id: 'n1' });

    const result = await service.create('u1', NotificationType.ACHIEVEMENT_UNLOCKED, {
      title: 'Test',
    });

    expect(prismaMock.notification.create).toHaveBeenCalledWith({
      data: {
        userId: 'u1',
        type: NotificationType.ACHIEVEMENT_UNLOCKED,
        payload: { title: 'Test' },
      },
    });
    expect(result).toEqual({ id: 'n1' });
  });

  describe('list', () => {
    it('should list all notifications when unreadOnly is false/undefined', async () => {
      prismaMock.notification.findMany.mockResolvedValue([{ id: 'n1' }]);

      const result = await service.list('u1');

      expect(prismaMock.notification.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1' },
        orderBy: { createdAt: 'desc' },
      });
      expect(result).toEqual([{ id: 'n1' }]);
    });

    it('should list only unread notifications when unreadOnly=true', async () => {
      prismaMock.notification.findMany.mockResolvedValue([{ id: 'n2' }]);

      const result = await service.list('u1', true);

      expect(prismaMock.notification.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1', isRead: false },
        orderBy: { createdAt: 'desc' },
      });
      expect(result).toEqual([{ id: 'n2' }]);
    });
  });

  it('markRead should update notification as read', async () => {
    prismaMock.notification.update.mockResolvedValue({ id: 'n1', isRead: true });

    const result = await service.markRead('u1', 'n1');

    expect(prismaMock.notification.update).toHaveBeenCalledWith({
      where: { id: 'n1' },
      data: { isRead: true },
    });
    expect(result).toEqual({ id: 'n1', isRead: true });
  });

  it('markAllRead should updateMany only unread notifications for user', async () => {
    prismaMock.notification.updateMany.mockResolvedValue({ count: 3 });

    const result = await service.markAllRead('u1');

    expect(prismaMock.notification.updateMany).toHaveBeenCalledWith({
      where: { userId: 'u1', isRead: false },
      data: { isRead: true },
    });
    expect(result).toEqual({ count: 3 });
  });
});
