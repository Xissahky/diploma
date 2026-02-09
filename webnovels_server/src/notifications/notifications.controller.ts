import { Controller, Get, Patch, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private n: NotificationsService) {}

  @Get('me')
  @ApiOperation({ summary: 'List my notifications' })
  list(@CurrentUser() u: any, @Query('unread') unread?: string) {
    const unreadOnly = unread === '1' || unread === 'true';
    return this.n.list(u.userId, unreadOnly);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark notification as read' })
  read(@CurrentUser() u: any, @Param('id') id: string) {
    return this.n.markRead(u.userId, id);
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all as read' })
  readAll(@CurrentUser() u: any) {
    return this.n.markAllRead(u.userId);
  }
}
