import { LibraryService } from './library.service';
import { BadRequestException } from '@nestjs/common';
import { LibraryStatus } from '@prisma/client';

describe('LibraryService', () => {
  let service: LibraryService;

  const prismaMock = {
    libraryEntry: {
      findMany: jest.fn(),
      upsert: jest.fn(),
      delete: jest.fn(),
    },
  } as any;

  const achievementsMock = {
    checkUserProgress: jest.fn(),
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new LibraryService(prismaMock, achievementsMock);
  });

  describe('list', () => {
    it('should list library entries without status filter', async () => {
      const fake = [{ id: 'e1' }];
      prismaMock.libraryEntry.findMany.mockResolvedValue(fake);

      const result = await service.list('u1');

      expect(prismaMock.libraryEntry.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1' },
        include: { novel: { include: { author: true } } },
        orderBy: { updatedAt: 'desc' },
      });
      expect(result).toEqual(fake);
    });

    it('should list library entries with status filter', async () => {
      const fake = [{ id: 'e2' }];
      prismaMock.libraryEntry.findMany.mockResolvedValue(fake);

      const result = await service.list('u1', LibraryStatus.COMPLETED);

      expect(prismaMock.libraryEntry.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1', status: LibraryStatus.COMPLETED },
        include: { novel: { include: { author: true } } },
        orderBy: { updatedAt: 'desc' },
      });
      expect(result).toEqual(fake);
    });
  });

  

  describe('remove', () => {
    it('should delete entry by composite key', async () => {
      prismaMock.libraryEntry.delete.mockResolvedValue({ id: 'e1' });

      const result = await service.remove('u1', 'n1');

      expect(prismaMock.libraryEntry.delete).toHaveBeenCalledWith({
        where: { userId_novelId: { userId: 'u1', novelId: 'n1' } },
      });
      expect(result).toEqual({ id: 'e1' });
    });
  });
});
