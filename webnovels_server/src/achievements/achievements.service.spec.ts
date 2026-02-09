import { AchievementsService } from './achievements.service';
import { NotificationType } from '@prisma/client';

describe('AchievementsService', () => {
  let service: AchievementsService;

  const prismaMock = {
    achievement: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    userAchievement: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    libraryEntry: {
      count: jest.fn(),
    },
  } as any;

  const notificationsMock = {
    create: jest.fn(),
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AchievementsService(prismaMock, notificationsMock);
  });

  describe('getAll', () => {
    it('should return all achievements ordered by points desc', async () => {
      const fake = [{ code: 'A', points: 10 }, { code: 'B', points: 5 }];
      prismaMock.achievement.findMany.mockResolvedValue(fake);

      const result = await service.getAll();

      expect(prismaMock.achievement.findMany).toHaveBeenCalledWith({
        orderBy: { points: 'desc' },
      });
      expect(result).toEqual(fake);
    });
  });

  describe('getUserAchievements', () => {
    it('should return user achievements with included achievement details', async () => {
      const fake = [
        { earnedAt: new Date(), achievement: { code: 'X' } },
      ];
      prismaMock.userAchievement.findMany.mockResolvedValue(fake);

      const result = await service.getUserAchievements('user1');

      expect(prismaMock.userAchievement.findMany).toHaveBeenCalledWith({
        where: { userId: 'user1' },
        include: { achievement: true },
        orderBy: { earnedAt: 'desc' },
      });
      expect(result).toEqual(fake);
    });
  });

  describe('grant', () => {
    it('should return null when achievement code not found', async () => {
      prismaMock.achievement.findUnique.mockResolvedValue(null);

      const result = await service.grant('user1', 'UNKNOWN_CODE');

      expect(prismaMock.achievement.findUnique).toHaveBeenCalledWith({
        where: { code: 'UNKNOWN_CODE' },
      });
      expect(result).toBeNull();
      expect(prismaMock.userAchievement.findUnique).not.toHaveBeenCalled();
      expect(prismaMock.userAchievement.create).not.toHaveBeenCalled();
      expect(notificationsMock.create).not.toHaveBeenCalled();
    });

    it('should return null when achievement already granted', async () => {
      prismaMock.achievement.findUnique.mockResolvedValue({
        id: 'ach1',
        code: 'ADD_5_NOVELS',
      });
      prismaMock.userAchievement.findUnique.mockResolvedValue({
        userId: 'user1',
        achievementId: 'ach1',
      });

      const result = await service.grant('user1', 'ADD_5_NOVELS');

      expect(prismaMock.userAchievement.findUnique).toHaveBeenCalledWith({
        where: {
          userId_achievementId: { userId: 'user1', achievementId: 'ach1' },
        },
      });
      expect(result).toBeNull();
      expect(prismaMock.userAchievement.create).not.toHaveBeenCalled();
      expect(notificationsMock.create).not.toHaveBeenCalled();
    });

    it('should create userAchievement and send notification when not already granted', async () => {
      const achievement = {
        id: 'ach1',
        code: 'ADD_5_NOVELS',
        title: 'Add 5 novels',
        description: 'Added 5 novels to library',
        points: 50,
      };

      const earned = {
        userId: 'user1',
        achievementId: 'ach1',
        achievement,
      };

      prismaMock.achievement.findUnique.mockResolvedValue(achievement);
      prismaMock.userAchievement.findUnique.mockResolvedValue(null);
      prismaMock.userAchievement.create.mockResolvedValue(earned);

      const result = await service.grant('user1', 'ADD_5_NOVELS');

      expect(prismaMock.userAchievement.create).toHaveBeenCalledWith({
        data: { userId: 'user1', achievementId: 'ach1' },
        include: { achievement: true },
      });

      expect(notificationsMock.create).toHaveBeenCalledWith(
        'user1',
        NotificationType.ACHIEVEMENT_UNLOCKED,
        {
          title: achievement.title,
          description: achievement.description,
          points: achievement.points,
        },
      );

      expect(result).toEqual(earned);
    });
  });

  describe('checkUserProgress', () => {
    it('should grant achievements based on library and completed counts', async () => {
      prismaMock.libraryEntry.count
        .mockResolvedValueOnce(6)  
        .mockResolvedValueOnce(12);

      const grantSpy = jest
        .spyOn(service, 'grant')
        .mockResolvedValue({} as any);

      await service.checkUserProgress('user1');

      expect(prismaMock.libraryEntry.count).toHaveBeenNthCalledWith(1, {
        where: { userId: 'user1' },
      });
      expect(prismaMock.libraryEntry.count).toHaveBeenNthCalledWith(2, {
        where: { userId: 'user1', status: 'COMPLETED' },
      });

      expect(grantSpy).toHaveBeenCalledWith('user1', 'ADD_5_NOVELS');
      expect(grantSpy).toHaveBeenCalledWith('user1', 'READ_10_NOVELS');
    });

    it('should not grant when thresholds are not met', async () => {
      prismaMock.libraryEntry.count
        .mockResolvedValueOnce(2)
        .mockResolvedValueOnce(3);

      const grantSpy = jest.spyOn(service, 'grant').mockResolvedValue({} as any);

      await service.checkUserProgress('user1');

      expect(grantSpy).not.toHaveBeenCalled();
    });
  });
});
