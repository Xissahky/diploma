import { Body, Controller, Post, Get, UseGuards, Req, Patch } from '@nestjs/common';
import { AuthService } from './auth.service';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import type { Request } from 'express';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private prisma: PrismaService,
  ) {}

  @Post('register')
  @ApiOperation({ summary: 'Register a new user' })
  async register(@Body() body: RegisterDto) {
    return this.authService.register(body.email, body.password, body.displayName);
  }

  @Post('login')
  @ApiOperation({ summary: 'Log in and receive JWT access token' })
  async login(@Body() body: LoginDto) {
    const user = await this.authService.validateUser(body.email, body.password);
    return this.authService.login(user);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user profile (requires JWT)' })
  async getProfile(@Req() req: Request) {
    const userId = (req.user as any).userId;
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, displayName: true, avatarUrl: true },
    });
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user profile (requires JWT)' })
  async updateProfile(
    @Req() req: Request,
    @Body() body: { name?: string; avatarUrl?: string },
  ) {
    const userId = (req.user as any).userId;
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName: body.name,
        avatarUrl: body.avatarUrl,
      },
      select: { id: true, email: true, displayName: true, avatarUrl: true },
    });
  }
}
