import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
  Delete,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CommentsService } from './comments.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

@ApiTags('comments')
@Controller('comments')
export class CommentsController {
  constructor(private commentsService: CommentsService) {}

  @Get('novel/:novelId')
  @ApiOperation({ summary: 'Get comments for a novel' })
  getForNovel(@Param('novelId') novelId: string) {
    return this.commentsService.getForNovel(novelId);
  }

  @Get('chapter/:chapterId')
  @ApiOperation({ summary: 'Get comments for a chapter' })
  getForChapter(@Param('chapterId') chapterId: string) {
    return this.commentsService.getForChapter(chapterId);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post()
  @ApiOperation({ summary: 'Create a comment (auth required)' })
  create(
    @Body()
    body: {
      content: string;
      novelId?: string;
      chapterId?: string;
      parentId?: string;
    },
    @CurrentUser() user: any,
  ) {
    return this.commentsService.create({
      authorId: user.userId,
      content: body.content,
      novelId: body.novelId,
      chapterId: body.chapterId,
      parentId: body.parentId,
    });
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Delete(':id')
  @ApiOperation({ summary: 'Delete own comment' })
  delete(@Param('id') id: string, @CurrentUser() user: any) {
    return this.commentsService.delete(id, user.userId);
  }
}
