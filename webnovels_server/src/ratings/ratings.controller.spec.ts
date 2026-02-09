import { Test, TestingModule } from '@nestjs/testing';
import { RatingsController } from './ratings.contoller';
import { RatingsService } from './ratings.service';

describe('RatingsController', () => {
  let controller: RatingsController;

  const serviceMock = {
    setRating: jest.fn(),
    getMyRating: jest.fn(),
    getAverage: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [RatingsController],
      providers: [{ provide: RatingsService, useValue: serviceMock }],
    }).compile();

    controller = module.get(RatingsController);
  });

  it('setRating should pass userId, novelId and numeric value', async () => {
    serviceMock.setRating.mockResolvedValue({
      novelId: 'n1',
      myRating: 5,
      average: 4.2,
    });

    const res = await controller.setRating({ userId: 'u1' }, 'n1', { value: 5 });

    expect(serviceMock.setRating).toHaveBeenCalledWith('u1', 'n1', 5);
    expect(res).toEqual({
      novelId: 'n1',
      myRating: 5,
      average: 4.2,
    });
  });

  it('setRating should coerce body.value to Number()', async () => {
    serviceMock.setRating.mockResolvedValue({
      novelId: 'n1',
      myRating: 3,
      average: 3.0,
    });

    const res = await controller.setRating({ userId: 'u1' }, 'n1', { value: '3' as any });

    expect(serviceMock.setRating).toHaveBeenCalledWith('u1', 'n1', 3);
    expect(res.myRating).toBe(3);
  });

  it('getMine should forward userId and novelId from query', async () => {
    serviceMock.getMyRating.mockResolvedValue({ value: 4 });

    const res = await controller.getMine({ userId: 'u1' }, 'n1');

    expect(serviceMock.getMyRating).toHaveBeenCalledWith('u1', 'n1');
    expect(res).toEqual({ value: 4 });
  });

  it('getAverage should forward novelId', async () => {
    serviceMock.getAverage.mockResolvedValue({ novelId: 'n1', average: 4.5 });

    const res = await controller.getAverage('n1');

    expect(serviceMock.getAverage).toHaveBeenCalledWith('n1');
    expect(res).toEqual({ novelId: 'n1', average: 4.5 });
  });
});
