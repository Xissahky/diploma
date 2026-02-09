import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RatingsService } from './ratings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

@ApiTags('ratings')
@Controller()
export class RatingsController {
  constructor(private ratings: RatingsService) {}

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Patch('novels/:id/rate')
  @ApiOperation({ summary: 'Set my rating for a novel (1..5)' })
  setRating(
    @CurrentUser() user: any,
    @Param('id') novelId: string,
    @Body() body: { value: number },
  ) {
    return this.ratings.setRating(user.userId, novelId, Number(body.value));
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Get('ratings/me')
  @ApiOperation({ summary: 'Get my rating for a novel' })
  getMine(@CurrentUser() user: any, @Query('novelId') novelId: string) {
    return this.ratings.getMyRating(user.userId, novelId);
  }

  @Get('novels/:id/rating')
  @ApiOperation({ summary: 'Get novel average rating' })
  getAverage(@Param('id') novelId: string) {
    return this.ratings.getAverage(novelId);
  }
}
