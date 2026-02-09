import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Delete,
  Patch,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { NovelsService } from './novels.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

// DTO (создай файлы, если ещё не созданы)
import { CreateNovelDto } from '../dto/create-novel.dto';
import { UpdateNovelDto } from '../dto/update-novel.dto';
import { CreateChapterDto } from '../dto/create-chapter.dto';
import { UpdateChapterDto } from '../dto/update-chapter.dto';

@ApiTags('novels')
@Controller('novels')
export class NovelsController {
  constructor(private novelsService: NovelsService) {}

  // -------- SEARCH & TAGS --------
  @Get('search')
  @ApiOperation({ summary: 'Search novels by title and tags' })
  async search(
    @Query('query') query = '',
    @Query('tags') tagsRaw = '',
    @Query('mode') mode: 'any' | 'all' = 'any',
  ) {
    const tags = tagsRaw.split(',').map((t) => t.trim()).filter(Boolean);
    return this.novelsService.searchNovels(query, { tags, mode });
  }

  @Get('tags')
  @ApiOperation({ summary: 'Get all available tags' })
  async getAllTags() {
    return this.novelsService.getAllTags();
  }

  // -------- POPULARITY / SECTIONS --------
  @Post(':id/view')
  @ApiOperation({ summary: 'Record a novel view (authenticated)' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  recordViewAuthed(@Param('id') id: string, @CurrentUser() u: any) {
    return this.novelsService.recordView(id, u.userId);
  }

  @Post(':id/view_public')
  @ApiOperation({ summary: 'Record a novel view (unauthenticated)' })
  recordViewPublic(@Param('id') id: string) {
    return this.novelsService.recordView(id, undefined);
  }

  @Get('popular')
  @ApiOperation({ summary: 'Popular novels by recent views' })
  getPopular(@Query('days') days?: string, @Query('limit') limit?: string) {
    return this.novelsService.getPopular(Number(days) || 14, Number(limit) || 20);
  }

  @Get('top-rated')
  @ApiOperation({ summary: 'Top rated novels' })
  getTopRated(@Query('limit') limit?: string) {
    return this.novelsService.getTopRated(Number(limit) || 20);
  }

  @Get('sections')
  @ApiOperation({ summary: 'Home sections: popular, topRated, recommended' })
  @UseGuards(JwtAuthGuard) // убери guard, если хочешь публично
  @ApiBearerAuth()
  getSections(@CurrentUser() u: any) {
    return this.novelsService.getHomeSections(u?.userId);
  }

  // -------- BASIC LIST/DETAIL --------
  @Get()
  @ApiOperation({ summary: 'Get all novels' })
  getAll() {
    return this.novelsService.getAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one novel by ID' })
  getOne(@Param('id') id: string, @CurrentUser() user?: any) {
    // user?.userId будет только если у тебя стоит глобальный guard/интерсептор,
    // иначе можно оставить просто this.novelsService.getOne(id)
    return this.novelsService.getOne(id, user?.userId);
  }

  // -------- CREATE / UPDATE / DELETE NOVEL --------
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post()
  @ApiOperation({ summary: 'Create a novel (auth required)' })
  create(@Body() dto: CreateNovelDto, @CurrentUser() user: any) {
    return this.novelsService.create({
      title: dto.title,
      description: dto.description,
      coverUrl: dto.coverUrl,
      authorId: user.userId,
      tags: dto.tags,
    });
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Patch(':id')
  @ApiOperation({ summary: 'Update a novel (author or admin)' })
  update(@Param('id') id: string, @Body() dto: UpdateNovelDto, @CurrentUser() user: any) {
    return this.novelsService.update(id, user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Delete(':id')
  @ApiOperation({ summary: 'Delete a novel (author or admin)' })
  delete(@Param('id') id: string, @CurrentUser() user: any) {
    return this.novelsService.delete(id, user.userId);
  }

  // -------- CHAPTERS --------
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post(':id/chapters')
  @ApiOperation({ summary: 'Add chapter to a novel (author or admin)' })
  addChapter(
    @Param('id') novelId: string,
    @Body() dto: CreateChapterDto,
    @CurrentUser() user: any,
  ) {
    return this.novelsService.addChapter(novelId, user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Patch(':id/chapters/:chapterId')
  @ApiOperation({ summary: 'Update chapter (author or admin)' })
  updateChapter(
    @Param('id') novelId: string,
    @Param('chapterId') chapterId: string,
    @Body() dto: UpdateChapterDto,
    @CurrentUser() user: any,
  ) {
    return this.novelsService.updateChapter(novelId, chapterId, user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Delete(':id/chapters/:chapterId')
  @ApiOperation({ summary: 'Delete chapter (author or admin)' })
  deleteChapter(
    @Param('id') novelId: string,
    @Param('chapterId') chapterId: string,
    @CurrentUser() user: any,
  ) {
    return this.novelsService.deleteChapter(novelId, chapterId, user.userId);
  }
}
