import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

describe('UsersController', () => {
  let controller: UsersController;

  const usersServiceMock = {
    findById: jest.fn(),
    updateProfile: jest.fn(),
    changePassword: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [{ provide: UsersService, useValue: usersServiceMock }],
    }).compile();

    controller = module.get(UsersController);
  });

  describe('getMe', () => {
    it('should return sanitized user object', async () => {
      usersServiceMock.findById.mockResolvedValue({
        id: 'u1',
        email: 'a@b.com',
        displayName: 'Alice',
        avatarUrl: '/uploads/a.png',
        bio: 'Hello',
        role: 'user',
        preferences: { lang: 'en' },
        passwordHash: 'SHOULD_NOT_LEAK',
      });

      const res = await controller.getMe({ userId: 'u1' } as any);

      expect(usersServiceMock.findById).toHaveBeenCalledWith('u1');
      expect(res).toEqual({
        id: 'u1',
        email: 'a@b.com',
        displayName: 'Alice',
        avatarUrl: '/uploads/a.png',
        bio: 'Hello',
        role: 'user',
        preferences: { lang: 'en' },
      });
      // убеждаемся, что пароль не “протек”
      expect((res as any).passwordHash).toBeUndefined();
    });

    it('should throw NotFoundException when user not found', async () => {
      usersServiceMock.findById.mockResolvedValue(null);

      await expect(controller.getMe({ userId: 'u404' } as any)).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(usersServiceMock.findById).toHaveBeenCalledWith('u404');
    });
  });

  describe('updateMe', () => {
    it('should call usersService.updateProfile', async () => {
      usersServiceMock.updateProfile.mockResolvedValue({
        id: 'u1',
        email: 'a@b.com',
        displayName: 'New',
        avatarUrl: null,
        bio: null,
        preferences: null,
        role: 'user',
      });

      const dto = { displayName: 'New' } as any;
      const res = await controller.updateMe({ userId: 'u1' } as any, dto);

      expect(usersServiceMock.updateProfile).toHaveBeenCalledWith('u1', dto);
      expect(res.displayName).toBe('New');
    });
  });

  describe('changePassword', () => {
    it('should call usersService.changePassword', async () => {
      usersServiceMock.changePassword.mockResolvedValue({ success: true });

      const dto = { oldPassword: 'old', newPassword: 'new' } as any;
      const res = await controller.changePassword({ userId: 'u1' } as any, dto);

      expect(usersServiceMock.changePassword).toHaveBeenCalledWith('u1', 'old', 'new');
      expect(res).toEqual({ success: true });
    });
  });
});
