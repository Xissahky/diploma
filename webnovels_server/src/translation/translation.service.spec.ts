import { BadRequestException } from '@nestjs/common';
import { TranslationService } from './translation.service';

const translateTextMock = jest.fn();

jest.mock('./adapters/libretranslate.adapter', () => {
  return {
    LibreTranslateAdapter: jest.fn().mockImplementation(() => ({
      translateText: translateTextMock,
    })),
  };
});

describe('TranslationService', () => {
  let service: TranslationService;

  const prismaMock = {
    chapterTranslation: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    chapter: {
      findUnique: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    translateTextMock.mockReset();

    process.env.TRANSLATOR_PROVIDER = 'libre';
    process.env.LIBRETRANSLATE_URL = 'http://localhost:5000/translate';

    service = new TranslationService(prismaMock);
  });

  describe('translateText', () => {
    it('should throw BadRequestException on empty text', async () => {
      await expect(
        service.translateText({ text: '   ', targetLang: 'en' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(translateTextMock).not.toHaveBeenCalled();
    });

    it('should call adapter.translateText and return translated text', async () => {
      translateTextMock.mockResolvedValue('Hello!');

      const res = await service.translateText({ text: 'Cześć', targetLang: 'en' } as any);

      expect(translateTextMock).toHaveBeenCalledWith('Cześć', 'en');
      expect(res).toBe('Hello!');
    });
  });

  describe('translateChapter', () => {
    it('should return cached translation if exists', async () => {
      prismaMock.chapterTranslation.findUnique.mockResolvedValue({
        chapterId: 'ch1',
        targetLang: 'en',
        text: 'Cached text',
      });

      const res = await service.translateChapter({ chapterId: 'ch1', targetLang: 'en' } as any);

      expect(prismaMock.chapterTranslation.findUnique).toHaveBeenCalledWith({
        where: { chapterId_targetLang: { chapterId: 'ch1', targetLang: 'en' } },
      });

      expect(prismaMock.chapter.findUnique).not.toHaveBeenCalled();
      expect(translateTextMock).not.toHaveBeenCalled();
      expect(prismaMock.chapterTranslation.create).not.toHaveBeenCalled();

      expect(res).toBe('Cached text');
    });

    it('should throw BadRequestException if chapter not found', async () => {
      prismaMock.chapterTranslation.findUnique.mockResolvedValue(null);
      prismaMock.chapter.findUnique.mockResolvedValue(null);

      await expect(
        service.translateChapter({ chapterId: 'ch404', targetLang: 'en' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(translateTextMock).not.toHaveBeenCalled();
      expect(prismaMock.chapterTranslation.create).not.toHaveBeenCalled();
    });

    it('should translate chapter, save to cache and return translated text', async () => {
      prismaMock.chapterTranslation.findUnique.mockResolvedValue(null);
      prismaMock.chapter.findUnique.mockResolvedValue({
        id: 'ch1',
        content: 'Original chapter content',
      });
      translateTextMock.mockResolvedValue('Translated chapter content');
      prismaMock.chapterTranslation.create.mockResolvedValue({ id: 't1' });

      const res = await service.translateChapter({ chapterId: 'ch1', targetLang: 'en' } as any);

      expect(prismaMock.chapter.findUnique).toHaveBeenCalledWith({ where: { id: 'ch1' } });
      expect(translateTextMock).toHaveBeenCalledWith('Original chapter content', 'en');

      expect(prismaMock.chapterTranslation.create).toHaveBeenCalledWith({
        data: { chapterId: 'ch1', targetLang: 'en', text: 'Translated chapter content' },
      });

      expect(res).toBe('Translated chapter content');
    });
  });
});
