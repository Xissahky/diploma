import { Test, TestingModule } from '@nestjs/testing';
import { LibraryController } from './library.controller';
import { LibraryService } from './library.service';
import { LibraryStatus } from '@prisma/client';

describe('LibraryController', () => {
  let controller: LibraryController;

  const libraryServiceMock = {
    list: jest.fn(),
    upsert: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [LibraryController],
      providers: [{ provide: LibraryService, useValue: libraryServiceMock }],
    }).compile();

    controller = module.get(LibraryController);
  });

  it('list should call library.list with optional status', async () => {
    libraryServiceMock.list.mockResolvedValue([{ id: 'e1' }]);

    const result = await controller.list({ userId: 'u1' } as any, LibraryStatus.READING);

    expect(libraryServiceMock.list).toHaveBeenCalledWith('u1', LibraryStatus.READING);
    expect(result).toEqual([{ id: 'e1' }]);
  });

  it('upsert should call library.upsert with userId, novelId and body', async () => {
    const body = { status: LibraryStatus.COMPLETED, favorite: true, progress: 100 };
    libraryServiceMock.upsert.mockResolvedValue({ id: 'e1' });

    const result = await controller.upsert({ userId: 'u1' } as any, 'n1', body as any);

    expect(libraryServiceMock.upsert).toHaveBeenCalledWith('u1', 'n1', body);
    expect(result).toEqual({ id: 'e1' });
  });

  it('remove should call library.remove with userId and novelId', async () => {
    libraryServiceMock.remove.mockResolvedValue({ id: 'e1' });

    const result = await controller.remove({ userId: 'u1' } as any, 'n1');

    expect(libraryServiceMock.remove).toHaveBeenCalledWith('u1', 'n1');
    expect(result).toEqual({ id: 'e1' });
  });
});
