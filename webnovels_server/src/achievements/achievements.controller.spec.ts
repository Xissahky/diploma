import { Test, TestingModule } from '@nestjs/testing';
import { AchievementsController } from './achievements.controller';
import { AchievementsService } from './achievements.service';

describe('AchievementsController', () => {
  let controller: AchievementsController;

  const achievementsServiceMock = {
    getAll: jest.fn(),
    getUserAchievements: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AchievementsController],
      providers: [
        {
          provide: AchievementsService,
          useValue: achievementsServiceMock,
        },
      ],
    }).compile();

    controller = module.get(AchievementsController);
  });

  it('should return all achievements', async () => {
    const fake = [{ code: 'A' }, { code: 'B' }];
    achievementsServiceMock.getAll.mockResolvedValue(fake);

    const result = await controller.getAll();

    expect(achievementsServiceMock.getAll).toHaveBeenCalledTimes(1);
    expect(result).toEqual(fake);
  });

  it('should return achievements for current user', async () => {
    const fake = [{ achievement: { code: 'X' } }];
    achievementsServiceMock.getUserAchievements.mockResolvedValue(fake);

    const result = await controller.getMine({ userId: 'user1' });

    expect(achievementsServiceMock.getUserAchievements).toHaveBeenCalledWith('user1');
    expect(result).toEqual(fake);
  });
});
