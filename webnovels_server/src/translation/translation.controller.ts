import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TranslationService } from './translation.service';
import { TranslateDto, TranslateChapterDto } from './dto/translate.dto';

@ApiTags('translation')
@Controller('translate')
export class TranslationController {
  constructor(private translationService: TranslationService) {}

  @Post('text')
  @ApiOperation({ summary: 'Translate arbitrary text' })
  async translateText(@Body() dto: TranslateDto) {
    const text = await this.translationService.translateText(dto);
    return { text };
  }

  @Post('chapter')
  @ApiOperation({ summary: 'Translate specific chapter' })
  async translateChapter(@Body() dto: TranslateChapterDto) {
    const text = await this.translationService.translateChapter(dto);
    return { text };
  }
}
