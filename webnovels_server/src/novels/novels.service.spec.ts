import { NovelsService } from './novels.service';
import { ForbiddenException, NotFoundException } from '@nestjs/common';

describe('NovelsService', () => {
  let service: NovelsService;

  const prismaMock = {
    novel: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    tag: {
      findMany: jest.fn(),
    },
    novelView: {
      create: jest.fn(),
      groupBy: jest.fn(),
    },
    userRating: {
      findUnique: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
    },
    chapter: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NovelsService(prismaMock);
  });

  // ---------- getAll ----------
  it('getAll should return flattened tags', async () => {
    prismaMock.novel.findMany.mockResolvedValue([
      {
        id: 'n1',
        title: 'A',
        tags: [{ tag: { name: 'isekai' } }, { tag: { name: 'action' } }],
      },
    ]);

    const result = await service.getAll();

    expect(prismaMock.novel.findMany).toHaveBeenCalled();
    expect(result[0].tags).toEqual(['isekai', 'action']);
  });

  // ---------- getOne ----------
  it('getOne should throw NotFound when novel does not exist', async () => {
    prismaMock.novel.findUnique.mockResolvedValue(null);

    await expect(service.getOne('missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('getOne should include myRating when userId provided', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({
      id: 'n1',
      title: 'A',
      tags: [{ tag: { name: 'tag1' } }],
      chapters: [],
      author: { id: 'u1' },
    });
    prismaMock.userRating.findUnique.mockResolvedValue({ value: 4 });

    const result = await service.getOne('n1', 'uX');

    expect(prismaMock.userRating.findUnique).toHaveBeenCalledWith({
      where: { userId_novelId: { userId: 'uX', novelId: 'n1' } },
      select: { value: true },
    });
    expect(result.myRating).toBe(4);
    expect(result.tags).toEqual(['tag1']);
  });

  it('getOne should not query rating when userId not provided', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({
      id: 'n1',
      tags: [{ tag: { name: 'tag1' } }],
      chapters: [],
      author: { id: 'u1' },
    });

    const result = await service.getOne('n1');

    expect(prismaMock.userRating.findUnique).not.toHaveBeenCalled();
    expect(result.tags).toEqual(['tag1']);
  });

  // ---------- searchNovels ----------
  it('searchNovels should build query with title filter and tags mode=any', async () => {
    prismaMock.novel.findMany.mockResolvedValue([
      { id: 'n1', tags: [{ tag: { name: 'magic' } }] },
    ]);

    await service.searchNovels('abc', { tags: ['Magic', '  Action  '], mode: 'any' });

    expect(prismaMock.novel.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          title: { contains: 'abc', mode: 'insensitive' },
          tags: { some: { tag: { name: { in: ['magic', 'action'] } } } },
        }),
      }),
    );
  });

  it('searchNovels should build tags condition with mode=all (AND)', async () => {
    prismaMock.novel.findMany.mockResolvedValue([]);

    await service.searchNovels('', { tags: ['x', 'y'], mode: 'all' });

    expect(prismaMock.novel.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          AND: [
            { tags: { some: { tag: { name: 'x' } } } },
            { tags: { some: { tag: { name: 'y' } } } },
          ],
        }),
      }),
    );
  });

  // ---------- create ----------
  it('create should connectOrCreate tags and return flattened tags', async () => {
    prismaMock.novel.create.mockResolvedValue({
      id: 'n1',
      title: 'A',
      tags: [{ tag: { name: 'isekai' } }, { tag: { name: 'action' } }],
    });

    const result = await service.create({
      title: 'A',
      description: 'D',
      authorId: 'u1',
      tags: ['Isekai', ' Action '],
    });

    expect(prismaMock.novel.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          tags: {
            create: [
              {
                tag: {
                  connectOrCreate: {
                    where: { name: 'isekai' },
                    create: { name: 'isekai' },
                  },
                },
              },
              {
                tag: {
                  connectOrCreate: {
                    where: { name: 'action' },
                    create: { name: 'action' },
                  },
                },
              },
            ],
          },
        }),
      }),
    );
    expect(result.tags).toEqual(['isekai', 'action']);
  });

  // ---------- update permissions ----------
  it('update should throw NotFound when novel missing', async () => {
    prismaMock.novel.findUnique.mockResolvedValue(null);

    await expect(service.update('n1', 'u1', { title: 'x' })).rejects.toBeInstanceOf(NotFoundException);
  });

  it('update should throw Forbidden when not owner and not admin', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({ authorId: 'owner' });
    prismaMock.user.findUnique.mockResolvedValue({ role: 'user' });

    await expect(service.update('n1', 'u2', { title: 'x' })).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('update should allow owner and update tags when provided', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({ authorId: 'u1' });
    prismaMock.user.findUnique.mockResolvedValue({ role: 'user' });
    prismaMock.novel.update.mockResolvedValue({
      id: 'n1',
      tags: [{ tag: { name: 't1' } }, { tag: { name: 't2' } }],
    });

    const result = await service.update('n1', 'u1', { tags: ['T1', 't2'] });

    expect(prismaMock.novel.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'n1' },
        data: expect.objectContaining({
          tags: expect.objectContaining({
            deleteMany: {},
            create: [
              { tag: { connectOrCreate: { where: { name: 't1' }, create: { name: 't1' } } } },
              { tag: { connectOrCreate: { where: { name: 't2' }, create: { name: 't2' } } } },
            ],
          }),
        }),
      }),
    );

    expect(result.tags).toEqual(['t1', 't2']);
  });

  // ---------- delete permissions ----------
  it('delete should throw Forbidden when user provided but not owner/admin', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({ authorId: 'owner' });
    prismaMock.user.findUnique.mockResolvedValue({ role: 'user' });

    await expect(service.delete('n1', 'u2')).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('delete should call prisma.novel.delete when allowed', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({ authorId: 'u1' });
    prismaMock.user.findUnique.mockResolvedValue({ role: 'user' });
    prismaMock.novel.delete.mockResolvedValue({ id: 'n1' });

    const result = await service.delete('n1', 'u1');

    expect(prismaMock.novel.delete).toHaveBeenCalledWith({ where: { id: 'n1' } });
    expect(result).toEqual({ id: 'n1' });
  });

  // ---------- tags ----------
  it('getAllTags should return list of tag names', async () => {
    prismaMock.tag.findMany.mockResolvedValue([{ name: 'a' }, { name: 'b' }]);

    const result = await service.getAllTags();

    expect(prismaMock.tag.findMany).toHaveBeenCalledWith({ orderBy: { name: 'asc' } });
    expect(result).toEqual(['a', 'b']);
  });

  // ---------- recordView ----------
  it('recordView should create novelView with nullable userId', async () => {
    prismaMock.novelView.create.mockResolvedValue({ id: 'v1' });

    const result = await service.recordView('n1');

    expect(prismaMock.novelView.create).toHaveBeenCalledWith({
      data: { novelId: 'n1', userId: null },
    });
    expect(result).toEqual({ ok: true });
  });

  // ---------- getPopular ----------
  it('getPopular should return empty array when no grouped views', async () => {
    prismaMock.novelView.groupBy.mockResolvedValue([]);

    const result = await service.getPopular(14, 20);

    expect(result).toEqual([]);
    expect(prismaMock.novel.findMany).not.toHaveBeenCalled();
  });

  it('getPopular should map ids preserving group order and attach recentViews', async () => {
    prismaMock.novelView.groupBy.mockResolvedValue([
      { novelId: 'n2', _count: { novelId: 10 } },
      { novelId: 'n1', _count: { novelId: 5 } },
    ]);

    prismaMock.novel.findMany.mockResolvedValue([
      { id: 'n1', tags: [{ tag: { name: 't1' } }] },
      { id: 'n2', tags: [{ tag: { name: 't2' } }] },
    ]);

    const result = await service.getPopular(14, 20);

    expect(result.map((x) => x.id)).toEqual(['n2', 'n1']);
    expect(result[0].recentViews).toBe(10);
    expect(result[1].recentViews).toBe(5);
  });

  // ---------- chapters permissions ----------
  it('addChapter should throw Forbidden when not owner/admin', async () => {
    prismaMock.novel.findUnique.mockResolvedValue({ authorId: 'owner' });
    prismaMock.user.findUnique.mockResolvedValue({ role: 'user' });

    await expect(
      service.addChapter('n1', 'u2', { title: 't', content: 'c' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('updateChapter should throw NotFound when chapter missing or novelId mismatch', async () => {
    prismaMock.chapter.findUnique.mockResolvedValue(null);

    await expect(
      service.updateChapter('n1', 'ch1', 'u1', { title: 'x' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('deleteChapter should allow admin', async () => {
    prismaMock.chapter.findUnique.mockResolvedValue({
      id: 'ch1',
      novelId: 'n1',
      novel: { authorId: 'owner' },
    });
    prismaMock.user.findUnique.mockResolvedValue({ role: 'admin' });
    prismaMock.chapter.delete.mockResolvedValue({ id: 'ch1' });

    const result = await service.deleteChapter('n1', 'ch1', 'adminUser');

    expect(prismaMock.chapter.delete).toHaveBeenCalledWith({ where: { id: 'ch1' } });
    expect(result).toEqual({ id: 'ch1' });
  });
});
