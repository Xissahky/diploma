import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsOptional, IsString, MaxLength, ArrayMaxSize } from 'class-validator';

export class CreateNovelDto {
  @ApiProperty() @IsString() @MaxLength(200)
  title!: string;

  @ApiProperty() @IsString()
  description!: string;

  @ApiProperty({ required: false }) @IsOptional() @IsString()
  coverUrl?: string;

  @ApiProperty({ type: [String], required: false, description: 'lowercase tags' })
  @IsOptional() @IsArray() @ArrayMaxSize(20)
  tags?: string[];
}
