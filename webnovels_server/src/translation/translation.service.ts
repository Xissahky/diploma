import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TranslateDto, TranslateChapterDto } from './dto/translate.dto';
import { TranslatorAdapter } from './adapters/translator.adapter';
import { LibreTranslateAdapter } from './adapters/libretranslate.adapter';
// import { GoogleTranslateAdapter } from './adapters/google.adapter';
import { DeepLAdapter } from './adapters/deepl.adapter';
import { OpenAIAdapter } from './adapters/openai.adapter';

@Injectable()
export class TranslationService {
  private readonly logger = new Logger(TranslationService.name);
  private adapter: TranslatorAdapter;

  constructor(private prisma: PrismaService) {
    this.adapter = this.makeAdapter();
  }

  private makeAdapter(): TranslatorAdapter {
    const provider = (process.env.TRANSLATOR_PROVIDER || 'libre').toLowerCase();
    switch (provider) {
    //   case 'google':
    //     return new GoogleTranslateAdapter();
      case 'deepl':
        return new DeepLAdapter(
          process.env.DEEPL_API_KEY || '',
          process.env.DEEPL_API_URL || 'https://api-free.deepl.com/v2/translate'
        );
      case 'openai':
        return new OpenAIAdapter(
          process.env.OPENAI_API_KEY || '',
          process.env.OPENAI_MODEL || 'gpt-4o-mini'
        );
      case 'libre':
      default:
        return new LibreTranslateAdapter(
          process.env.LIBRETRANSLATE_URL || 'http://localhost:5000/translate'
        );
    }
  }

  async translateText({ text, targetLang }: TranslateDto): Promise<string> {
    if (!text?.trim()) throw new BadRequestException('Empty text');
    return this.adapter.translateText(text, targetLang);
  }

  async translateChapter({ chapterId, targetLang }: TranslateChapterDto): Promise<string> {
    const cached = await this.prisma.chapterTranslation.findUnique({
      where: { chapterId_targetLang: { chapterId, targetLang } },
    });
    if (cached) return cached.text;

    const chapter = await this.prisma.chapter.findUnique({ where: { id: chapterId } });
    if (!chapter) throw new BadRequestException('Chapter not found');

    const translated = await this.adapter.translateText(chapter.content, targetLang);

    await this.prisma.chapterTranslation.create({
      data: { chapterId, targetLang, text: translated },
    });

    return translated;
  }
}
