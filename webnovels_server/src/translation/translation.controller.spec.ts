import { Test, TestingModule } from '@nestjs/testing';
import { TranslationController } from './translation.controller';
import { TranslationService } from './translation.service';

describe('TranslationController', () => {
  let controller: TranslationController;

  const serviceMock = {
    translateText: jest.fn(),
    translateChapter: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [TranslationController],
      providers: [{ provide: TranslationService, useValue: serviceMock }],
    }).compile();

    controller = module.get(TranslationController);
  });

  it('translateText should return { text }', async () => {
    serviceMock.translateText.mockResolvedValue('Hello');

    const res = await controller.translateText({ text: 'Cześć', targetLang: 'en' } as any);

    expect(serviceMock.translateText).toHaveBeenCalledWith({ text: 'Cześć', targetLang: 'en' });
    expect(res).toEqual({ text: 'Hello' });
  });

  it('translateChapter should return { text }', async () => {
    serviceMock.translateChapter.mockResolvedValue('Translated chapter');

    const res = await controller.translateChapter({ chapterId: 'ch1', targetLang: 'en' } as any);

    expect(serviceMock.translateChapter).toHaveBeenCalledWith({ chapterId: 'ch1', targetLang: 'en' });
    expect(res).toEqual({ text: 'Translated chapter' });
  });
});
