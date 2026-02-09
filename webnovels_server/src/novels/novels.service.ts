import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type MatchMode = 'any' | 'all';

@Injectable()
export class NovelsService {
  constructor(private prisma: PrismaService) {}

  async getAll() {
    const novels = await this.prisma.novel.findMany({
      include: {
        author: true,
        tags: { include: { tag: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return novels.map(this.flattenNovel);
  }

  async getOne(id: string, userId?: string) {
    const novel = await this.prisma.novel.findUnique({
      where: { id },
      include: {
        author: true,
        chapters: true,
        tags: { include: { tag: true } },
      },
    });

    if (!novel) throw new NotFoundException('Novel not found');

    if (userId) {
      const mine = await this.prisma.userRating.findUnique({
        where: { userId_novelId: { userId, novelId: id } },
        select: { value: true },
      });
      return { ...this.flattenNovel(novel), myRating: mine?.value ?? null };
    }

    return this.flattenNovel(novel);
  }

  async searchNovels(query: string, opts?: { tags?: string[]; mode?: MatchMode }) {
    const tags = (opts?.tags ?? [])
      .map((t) => t.toLowerCase().trim())
      .filter(Boolean);
    const mode: MatchMode = opts?.mode ?? 'any';

    const titleCond = query
      ? { title: { contains: query, mode: 'insensitive' as const } }
      : {};

    const tagsCond =
      tags.length === 0
        ? {}
        : mode === 'all'
        ? { AND: tags.map((tag) => ({ tags: { some: { tag: { name: tag } } } })) }
        : { tags: { some: { tag: { name: { in: tags } } } } };

    const novels = await this.prisma.novel.findMany({
      where: { ...titleCond, ...tagsCond },
      include: { author: true, tags: { include: { tag: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return novels.map(this.flattenNovel);
  }

  async create(data: { title: string; description: string; coverUrl?: string; authorId: string; tags?: string[] }) {
    const tags = (data.tags ?? [])
      .map((t) => t.toLowerCase().trim())
      .filter(Boolean);

    const novel = await this.prisma.novel.create({
      data: {
        title: data.title,
        description: data.description,
        coverUrl: data.coverUrl,
        authorId: data.authorId,
        tags: {
          create: tags.map((name) => ({
            tag: {
              connectOrCreate: {
                where: { name },
                create: { name },
              },
            },
          })),
        },
      },
      include: { author: true, tags: { include: { tag: true } } },
    });

    return this.flattenNovel(novel);
  }

  async update(
    id: string,
    userId: string,
    dto: { title?: string; description?: string; coverUrl?: string; tags?: string[] },
  ) {
    const novel = await this.prisma.novel.findUnique({ where: { id }, select: { authorId: true } });
    if (!novel) throw new NotFoundException('Novel not found');

    const me = await this.prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
    const isOwner = novel.authorId === userId;
    const isAdmin = me?.role === 'admin';
    if (!isOwner && !isAdmin) throw new ForbiddenException('Only author or admin can edit novel');

    let tagsUpdate: any = undefined;
    if (dto.tags) {
      const tags = dto.tags.map((t) => t.toLowerCase().trim()).filter(Boolean);
      tagsUpdate = {
        deleteMany: {},
        create: tags.map((name) => ({
          tag: { connectOrCreate: { where: { name }, create: { name } } },
        })),
      };
    }

    const updated = await this.prisma.novel.update({
      where: { id },
      data: {
        title: dto.title,
        description: dto.description,
        coverUrl: dto.coverUrl,
        ...(tagsUpdate ? { tags: tagsUpdate } : {}),
      },
      include: { author: true, tags: { include: { tag: true } } },
    });

    return this.flattenNovel(updated);
  }

  async delete(id: string, userId?: string) {
    if (userId) {
      const novel = await this.prisma.novel.findUnique({ where: { id }, select: { authorId: true } });
      if (!novel) throw new NotFoundException('Novel not found');

      const me = await this.prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
      const isOwner = novel.authorId === userId;
      const isAdmin = me?.role === 'admin';
      if (!isOwner && !isAdmin) throw new ForbiddenException('Only author or admin can delete novel');
    }
    return this.prisma.novel.delete({ where: { id } });
  }

  async getAllTags() {
    const tags = await this.prisma.tag.findMany({
      orderBy: { name: 'asc' },
    });
    return tags.map((t) => t.name);
  }

  async recordView(novelId: string, userId?: string) {
    await this.prisma.novelView.create({
      data: { novelId, userId: userId ?? null },
    });
    return { ok: true };
  }

  async getPopular(days = 14, limit = 20) {
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const grouped = await this.prisma.novelView.groupBy({
      by: ['novelId'],
      where: { createdAt: { gte: since } },
      _count: { novelId: true },
      orderBy: { _count: { novelId: 'desc' } },
      take: limit,
    });

    if (grouped.length === 0) return [];

    const ids = grouped.map((g) => g.novelId);
    const novels = await this.prisma.novel.findMany({
      where: { id: { in: ids } },
      include: { author: true, tags: { include: { tag: true } } },
    });

    const viewsMap = new Map(grouped.map((g) => [g.novelId, g._count.novelId]));
    const byId = new Map(novels.map((n) => [n.id, this.flattenNovel(n)]));

    return ids
      .map((id) => {
        const n = byId.get(id);
        if (!n) return null;
        return { ...n, recentViews: viewsMap.get(id) ?? 0 };
      })
      .filter(Boolean) as any[];
  }

  async getTopRated(limit = 20) {
    const novels = await this.prisma.novel.findMany({
      orderBy: [{ rating: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: { author: true, tags: { include: { tag: true } } },
    });
    return novels.map(this.flattenNovel);
  }

  async getHomeSections(userId?: string) {
    const [popular, topRated] = await Promise.all([
      this.getPopular(14, 20),
      this.getTopRated(20),
    ]);
    const recommended = topRated.slice(0, 12);
    return { popular, topRated, recommended };
  }

  async addChapter(novelId: string, userId: string, dto: { title: string; content: string }) {
    const novel = await this.prisma.novel.findUnique({ where: { id: novelId }, select: { authorId: true } });
    if (!novel) throw new NotFoundException('Novel not found');

    const me = await this.prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
    const isOwner = novel.authorId === userId;
    const isAdmin = me?.role === 'admin';
    if (!isOwner && !isAdmin) throw new ForbiddenException('Only author or admin can add chapters');

    const chapter = await this.prisma.chapter.create({
      data: { title: dto.title, content: dto.content, novelId },
    });


    return chapter;
  }

  async updateChapter(novelId: string, chapterId: string, userId: string, dto: { title?: string; content?: string }) {
    const chapter = await this.prisma.chapter.findUnique({
      where: { id: chapterId },
      include: { novel: { select: { authorId: true } } },
    });
    if (!chapter || chapter.novelId !== novelId) throw new NotFoundException('Chapter not found');

    const me = await this.prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
    const isOwner = chapter.novel.authorId === userId;
    const isAdmin = me?.role === 'admin';
    if (!isOwner && !isAdmin) throw new ForbiddenException('Only author or admin can edit chapters');

    return this.prisma.chapter.update({
      where: { id: chapterId },
      data: { title: dto.title, content: dto.content },
    });
  }

  async deleteChapter(novelId: string, chapterId: string, userId: string) {
    const chapter = await this.prisma.chapter.findUnique({
      where: { id: chapterId },
      include: { novel: { select: { authorId: true } } },
    });
    if (!chapter || chapter.novelId !== novelId) throw new NotFoundException('Chapter not found');

    const me = await this.prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
    const isOwner = chapter.novel.authorId === userId;
    const isAdmin = me?.role === 'admin';
    if (!isOwner && !isAdmin) throw new ForbiddenException('Only author or admin can delete chapters');

    return this.prisma.chapter.delete({ where: { id: chapterId } });
  }

  private flattenNovel = (n: any) => {
    const tagNames = n.tags?.map((nt: any) => nt.tag?.name).filter(Boolean) ?? [];
    const { tags, ...rest } = n;
    return { ...rest, tags: tagNames };
  };
}
