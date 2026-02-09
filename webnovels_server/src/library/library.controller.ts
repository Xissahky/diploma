import { Controller, Get, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { LibraryService } from './library.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { LibraryStatus } from '@prisma/client';
import { IsBoolean, IsEnum, IsInt, IsOptional, Min } from 'class-validator';

class UpsertLibraryDto {
  @IsEnum(LibraryStatus)
  status!: LibraryStatus;

  @IsOptional() @IsBoolean()
  favorite?: boolean;

  @IsOptional() @IsInt() @Min(0)
  progress?: number;
}

@ApiTags('library')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('library')
export class LibraryController {
  constructor(private library: LibraryService) {}

  @Get('me')
  @ApiOperation({ summary: 'My library (optional status filter)' })
  list(@CurrentUser() u: any, @Query('status') status?: LibraryStatus) {
    return this.library.list(u.userId, status);
  }

  @Patch(':novelId')
  @ApiOperation({ summary: 'Add/update novel in my library' })
  upsert(@CurrentUser() u: any, @Param('novelId') novelId: string, @Body() body: UpsertLibraryDto) {
    return this.library.upsert(u.userId, novelId, body);
  }

  @Delete(':novelId')
  @ApiOperation({ summary: 'Remove novel from my library' })
  remove(@CurrentUser() u: any, @Param('novelId') novelId: string) {
    return this.library.remove(u.userId, novelId);
  }
}
