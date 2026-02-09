import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CommentsService {
  constructor(private prisma: PrismaService) {}

  async getForNovel(novelId: string) {
    if (!novelId) throw new BadRequestException('novelId is required');

    const comments = await this.prisma.comment.findMany({
      where: {
        novelId,
        parentId: null, 
      },
      include: {
        author: true,
        replies: {
          include: {
            author: true,
          },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return comments;
  }

  async getForChapter(chapterId: string) {
    if (!chapterId) throw new BadRequestException('chapterId is required');

    const comments = await this.prisma.comment.findMany({
      where: {
        chapterId,
        parentId: null,
      },
      include: {
        author: true,
        replies: {
          include: {
            author: true,
          },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return comments;
  }

  async create(params: {
    authorId: string;
    content: string;
    novelId?: string;
    chapterId?: string;
    parentId?: string;
  }) {
    const { authorId, content, novelId, chapterId, parentId } = params;

    if (!content?.trim()) {
      throw new BadRequestException('content is required');
    }

    if (!novelId && !chapterId) {
      throw new BadRequestException('Either novelId or chapterId is required');
    }

    if (parentId) {
      const parent = await this.prisma.comment.findUnique({ where: { id: parentId } });
      if (!parent) throw new NotFoundException('Parent comment not found');
    }

    return this.prisma.comment.create({
      data: {
        content,
        authorId,
        novelId: novelId ?? null,
        chapterId: chapterId ?? null,
        parentId: parentId ?? null,
      },
      include: {
        author: true,
      },
    });
  }

  async delete(id: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.authorId !== userId) {
      throw new BadRequestException('You cannot delete this comment');
    }
    await this.prisma.comment.delete({ where: { id } });
    return { success: true };
  }
}
