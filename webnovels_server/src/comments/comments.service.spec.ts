import { CommentsService } from './comments.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('CommentsService', () => {
  let service: CommentsService;

  const prismaMock = {
    comment: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      delete: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new CommentsService(prismaMock);
  });

  describe('getForNovel', () => {
    it('should throw when novelId is empty', async () => {
      await expect(service.getForNovel('' as any)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prismaMock.comment.findMany).not.toHaveBeenCalled();
    });

    it('should query top-level comments for novel with replies', async () => {
      const fake = [{ id: 'c1' }];
      prismaMock.comment.findMany.mockResolvedValue(fake);

      const result = await service.getForNovel('n1');

      expect(prismaMock.comment.findMany).toHaveBeenCalledWith({
        where: { novelId: 'n1', parentId: null },
        include: {
          author: true,
          replies: {
            include: { author: true },
            orderBy: { createdAt: 'asc' },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      expect(result).toEqual(fake);
    });
  });

  describe('getForChapter', () => {
    it('should throw when chapterId is empty', async () => {
      await expect(service.getForChapter('' as any)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prismaMock.comment.findMany).not.toHaveBeenCalled();
    });

    it('should query top-level comments for chapter with replies', async () => {
      const fake = [{ id: 'c1' }];
      prismaMock.comment.findMany.mockResolvedValue(fake);

      const result = await service.getForChapter('ch1');

      expect(prismaMock.comment.findMany).toHaveBeenCalledWith({
        where: { chapterId: 'ch1', parentId: null },
        include: {
          author: true,
          replies: {
            include: { author: true },
            orderBy: { createdAt: 'asc' },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      expect(result).toEqual(fake);
    });
  });

  describe('create', () => {
    it('should throw when content is empty/blank', async () => {
      await expect(
        service.create({ authorId: 'u1', content: '   ', novelId: 'n1' }),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prismaMock.comment.create).not.toHaveBeenCalled();
    });

    it('should throw when neither novelId nor chapterId is provided', async () => {
      await expect(
        service.create({ authorId: 'u1', content: 'Hello' }),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prismaMock.comment.create).not.toHaveBeenCalled();
    });

    it('should throw when parentId does not exist', async () => {
      prismaMock.comment.findUnique.mockResolvedValue(null);

      await expect(
        service.create({
          authorId: 'u1',
          content: 'Reply',
          novelId: 'n1',
          parentId: 'p1',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);

      expect(prismaMock.comment.findUnique).toHaveBeenCalledWith({
        where: { id: 'p1' },
      });
      expect(prismaMock.comment.create).not.toHaveBeenCalled();
    });

    it('should create comment for novel', async () => {
      prismaMock.comment.create.mockResolvedValue({
        id: 'c1',
        content: 'Hello',
        novelId: 'n1',
        author: { id: 'u1' },
      });

      const result = await service.create({
        authorId: 'u1',
        content: 'Hello',
        novelId: 'n1',
      });

      expect(prismaMock.comment.create).toHaveBeenCalledWith({
        data: {
          content: 'Hello',
          authorId: 'u1',
          novelId: 'n1',
          chapterId: null,
          parentId: null,
        },
        include: { author: true },
      });

      expect(result.id).toBe('c1');
    });

    it('should create comment for chapter', async () => {
      prismaMock.comment.create.mockResolvedValue({ id: 'c2' });

      await service.create({
        authorId: 'u1',
        content: 'Nice chapter',
        chapterId: 'ch1',
      });

      expect(prismaMock.comment.create).toHaveBeenCalledWith({
        data: {
          content: 'Nice chapter',
          authorId: 'u1',
          novelId: null,
          chapterId: 'ch1',
          parentId: null,
        },
        include: { author: true },
      });
    });

    it('should create reply (parent exists)', async () => {
      prismaMock.comment.findUnique.mockResolvedValue({ id: 'p1' });
      prismaMock.comment.create.mockResolvedValue({ id: 'c3' });

      await service.create({
        authorId: 'u1',
        content: 'Reply',
        novelId: 'n1',
        parentId: 'p1',
      });

      expect(prismaMock.comment.findUnique).toHaveBeenCalledWith({
        where: { id: 'p1' },
      });

      expect(prismaMock.comment.create).toHaveBeenCalledWith({
        data: {
          content: 'Reply',
          authorId: 'u1',
          novelId: 'n1',
          chapterId: null,
          parentId: 'p1',
        },
        include: { author: true },
      });
    });
  });

  describe('delete', () => {
    it('should throw when comment not found', async () => {
      prismaMock.comment.findUnique.mockResolvedValue(null);

      await expect(service.delete('c1', 'u1')).rejects.toBeInstanceOf(
        NotFoundException,
      );

      expect(prismaMock.comment.delete).not.toHaveBeenCalled();
    });

    it('should throw when user is not author', async () => {
      prismaMock.comment.findUnique.mockResolvedValue({
        id: 'c1',
        authorId: 'u2',
      });

      await expect(service.delete('c1', 'u1')).rejects.toBeInstanceOf(
        BadRequestException,
      );

      expect(prismaMock.comment.delete).not.toHaveBeenCalled();
    });

    it('should delete comment when user is author', async () => {
      prismaMock.comment.findUnique.mockResolvedValue({
        id: 'c1',
        authorId: 'u1',
      });
      prismaMock.comment.delete.mockResolvedValue({ id: 'c1' });

      const result = await service.delete('c1', 'u1');

      expect(prismaMock.comment.delete).toHaveBeenCalledWith({
        where: { id: 'c1' },
      });
      expect(result).toEqual({ success: true });
    });
  });
});
