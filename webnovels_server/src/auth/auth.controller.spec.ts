import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import type { Request } from 'express';

describe('AuthController', () => {
  let controller: AuthController;

  const authServiceMock = {
    register: jest.fn(),
    validateUser: jest.fn(),
    login: jest.fn(),
  };

  const prismaMock = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        { provide: AuthService, useValue: authServiceMock },
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    controller = module.get(AuthController);
  });

  describe('register', () => {
    it('should call authService.register with dto fields', async () => {
      const dto = {
        email: 'test@example.com',
        password: 'secret123',
        displayName: 'Tester',
      };

      const fakeResult = { id: 'u1', email: dto.email, displayName: dto.displayName };
      authServiceMock.register.mockResolvedValue(fakeResult);

      const result = await controller.register(dto as any);

      expect(authServiceMock.register).toHaveBeenCalledWith(
        dto.email,
        dto.password,
        dto.displayName,
      );
      expect(result).toEqual(fakeResult);
    });
  });

  describe('login', () => {
    it('should validate user and return authService.login result', async () => {
      const dto = { email: 'test@example.com', password: 'secret123' };

      const user = { id: 'u1', email: dto.email, displayName: 'Tester' };
      const tokenResponse = { access_token: 'jwt.token.here' };

      authServiceMock.validateUser.mockResolvedValue(user);
      authServiceMock.login.mockResolvedValue(tokenResponse);

      const result = await controller.login(dto as any);

      expect(authServiceMock.validateUser).toHaveBeenCalledWith(dto.email, dto.password);
      expect(authServiceMock.login).toHaveBeenCalledWith(user);
      expect(result).toEqual(tokenResponse);
    });
  });

  describe('getProfile', () => {
    it('should query prisma.user.findUnique using req.user.userId and return selected fields', async () => {
      const req = { user: { userId: 'u1' } } as unknown as Request;

      const dbUser = {
        id: 'u1',
        email: 'test@example.com',
        displayName: 'Tester',
        avatarUrl: '/uploads/a.png',
      };

      prismaMock.user.findUnique.mockResolvedValue(dbUser);

      const result = await controller.getProfile(req);

      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'u1' },
        select: { id: true, email: true, displayName: true, avatarUrl: true },
      });
      expect(result).toEqual(dbUser);
    });
  });

  describe('updateProfile', () => {
    it('should update displayName and avatarUrl for current user', async () => {
      const req = { user: { userId: 'u1' } } as unknown as Request;
      const body = { name: 'New Name', avatarUrl: '/uploads/new.png' };

      const updated = {
        id: 'u1',
        email: 'test@example.com',
        displayName: 'New Name',
        avatarUrl: '/uploads/new.png',
      };

      prismaMock.user.update.mockResolvedValue(updated);

      const result = await controller.updateProfile(req, body);

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: {
          displayName: body.name,
          avatarUrl: body.avatarUrl,
        },
        select: { id: true, email: true, displayName: true, avatarUrl: true },
      });

      expect(result).toEqual(updated);
    });

    it('should allow partial update (only name)', async () => {
      const req = { user: { userId: 'u1' } } as unknown as Request;
      const body = { name: 'Only Name' };

      prismaMock.user.update.mockResolvedValue({
        id: 'u1',
        email: 'test@example.com',
        displayName: 'Only Name',
        avatarUrl: '/uploads/a.png',
      });

      await controller.updateProfile(req, body as any);

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: {
          displayName: body.name,
          avatarUrl: undefined,
        },
        select: { id: true, email: true, displayName: true, avatarUrl: true },
      });
    });
  });
});
