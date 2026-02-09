import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength } from 'class-validator';

export class CreateChapterDto {
  @ApiProperty() @IsString() @MaxLength(200)
  title!: string;

  @ApiProperty() @IsString()
  content!: string;
}
