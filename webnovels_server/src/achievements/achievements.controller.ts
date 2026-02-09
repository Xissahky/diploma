import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AchievementsService } from './achievements.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

@ApiTags('achievements')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('achievements')
export class AchievementsController {
  constructor(private achievements: AchievementsService) {}

  @Get('all')
  @ApiOperation({ summary: 'List all available achievements' })
  getAll() {
    return this.achievements.getAll();
  }

  @Get('me')
  @ApiOperation({ summary: 'My unlocked achievements' })
  getMine(@CurrentUser() user: any) {
    return this.achievements.getUserAchievements(user.userId);
  }
}
