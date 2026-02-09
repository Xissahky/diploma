import { IsString, IsOptional } from 'class-validator';

export class TranslateDto {
  @IsString()
  text!: string;

  @IsOptional()
  @IsString()
  targetLang: string = 'en';
}

export class TranslateChapterDto {
  @IsString()
  chapterId!: string;

  @IsString()
  targetLang: string = 'en';
}
