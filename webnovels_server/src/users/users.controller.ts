import { Body, Controller, Get, Patch, UseGuards, NotFoundException } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { ChangePasswordDto } from '../dto/change-password.dto';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user' })
  async getMe(@CurrentUser() user: any) {
    const fullUser = await this.usersService.findById(user.userId);
    if (!fullUser) throw new NotFoundException('User not found');

    return {
      id: fullUser.id,
      email: fullUser.email,
      displayName: fullUser.displayName,
      avatarUrl: fullUser.avatarUrl,
      bio: fullUser.bio,
      role: fullUser.role,
      preferences: fullUser.preferences,
    };
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update profile' })
  updateMe(@CurrentUser() u: any, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(u.userId, dto);
  }

  @Patch('me/password')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change password' })
  changePassword(@CurrentUser() u: any, @Body() dto: ChangePasswordDto) {
    return this.usersService.changePassword(u.userId, dto.oldPassword, dto.newPassword);
  }
}
