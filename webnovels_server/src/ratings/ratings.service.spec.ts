import { BadRequestException } from '@nestjs/common';
import { RatingsService } from './ratings.service';

describe('RatingsService', () => {
  let service: RatingsService;

  const prismaMock = {
    userRating: {
      upsert: jest.fn(),
      aggregate: jest.fn(),
      findUnique: jest.fn(),
    },
    novel: {
      update: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new RatingsService(prismaMock);
  });

  describe('setRating', () => {
    it('should throw BadRequestException for value < 1', async () => {
      await expect(service.setRating('u1', 'n1', 0)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('should throw BadRequestException for value > 5', async () => {
      await expect(service.setRating('u1', 'n1', 6)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('should throw BadRequestException for non-integer value', async () => {
      await expect(service.setRating('u1', 'n1', 4.2)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('should upsert rating, recompute avg and update novel.rating (rounded to 2 decimals)', async () => {
      prismaMock.userRating.upsert.mockResolvedValue({}); // результат не используется
      prismaMock.userRating.aggregate.mockResolvedValue({
        _avg: { value: 4.3333333 },
      });
      prismaMock.novel.update.mockResolvedValue({});

      const res = await service.setRating('u1', 'n1', 5);

      expect(prismaMock.userRating.upsert).toHaveBeenCalledWith({
        where: { userId_novelId: { userId: 'u1', novelId: 'n1' } },
        update: { value: 5 },
        create: { userId: 'u1', novelId: 'n1', value: 5 },
      });

      expect(prismaMock.userRating.aggregate).toHaveBeenCalledWith({
        where: { novelId: 'n1' },
        _avg: { value: true },
      });

      // 4.3333333 -> 4.33
      expect(prismaMock.novel.update).toHaveBeenCalledWith({
        where: { id: 'n1' },
        data: { rating: 4.33 },
      });

      expect(res).toEqual({
        novelId: 'n1',
        myRating: 5,
        average: 4.33,
      });
    });

    it('should treat null avg as 0 and update novel.rating=0', async () => {
      prismaMock.userRating.upsert.mockResolvedValue({});
      prismaMock.userRating.aggregate.mockResolvedValue({
        _avg: { value: null },
      });
      prismaMock.novel.update.mockResolvedValue({});

      const res = await service.setRating('u1', 'n1', 1);

      expect(prismaMock.novel.update).toHaveBeenCalledWith({
        where: { id: 'n1' },
        data: { rating: 0 },
      });
      expect(res).toEqual({
        novelId: 'n1',
        myRating: 1,
        average: 0,
      });
    });

    it('should convert body.value to number in controller layer; service expects number already (sanity)', async () => {
      prismaMock.userRating.upsert.mockResolvedValue({});
      prismaMock.userRating.aggregate.mockResolvedValue({ _avg: { value: 2 } });
      prismaMock.novel.update.mockResolvedValue({});

      const res = await service.setRating('u1', 'n1', Number('3'));

      expect(res.myRating).toBe(3);
      expect(res.average).toBe(2);
    });
  });

  describe('getMyRating', () => {
    it('should return my rating value', async () => {
      prismaMock.userRating.findUnique.mockResolvedValue({ value: 4 });

      const res = await service.getMyRating('u1', 'n1');

      expect(prismaMock.userRating.findUnique).toHaveBeenCalledWith({
        where: { userId_novelId: { userId: 'u1', novelId: 'n1' } },
        select: { value: true },
      });
      expect(res).toEqual({ value: 4 });
    });
  });

  describe('getAverage', () => {
    it('should return average rounded to 2 decimals', async () => {
      prismaMock.userRating.aggregate.mockResolvedValue({ _avg: { value: 4.6666 } });

      const res = await service.getAverage('n1');

      expect(prismaMock.userRating.aggregate).toHaveBeenCalledWith({
        where: { novelId: 'n1' },
        _avg: { value: true },
      });
      expect(res).toEqual({ novelId: 'n1', average: 4.67 });
    });

    it('should return 0 when avg is null', async () => {
      prismaMock.userRating.aggregate.mockResolvedValue({ _avg: { value: null } });

      const res = await service.getAverage('n1');

      expect(res).toEqual({ novelId: 'n1', average: 0 });
    });
  });
});
