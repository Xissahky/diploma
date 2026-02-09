import { BadRequestException } from '@nestjs/common';
import { UsersService } from './users.service';

jest.mock('bcrypt', () => ({
  hash: jest.fn(),
  compare: jest.fn(),
}));
import * as bcrypt from 'bcrypt';

describe('UsersService', () => {
  let service: UsersService;

  const prismaMock = {
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new UsersService(prismaMock);
  });

  describe('createUser', () => {
    it('should hash password and create user', async () => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('HASHED');
      prismaMock.user.create.mockResolvedValue({
        id: 'u1',
        email: 'a@b.com',
        passwordHash: 'HASHED',
        displayName: 'Alice',
      });

      const res = await service.createUser('a@b.com', 'pass', 'Alice');

      expect(bcrypt.hash).toHaveBeenCalledWith('pass', 10);
      expect(prismaMock.user.create).toHaveBeenCalledWith({
        data: { email: 'a@b.com', passwordHash: 'HASHED', displayName: 'Alice' },
      });
      expect(res.passwordHash).toBe('HASHED');
    });
  });

  describe('findByEmail', () => {
    it('should call prisma.user.findUnique', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'u1' });

      const res = await service.findByEmail('a@b.com');

      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({ where: { email: 'a@b.com' } });
      expect(res).toEqual({ id: 'u1' });
    });
  });

  describe('findById', () => {
    it('should call prisma.user.findUnique', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ id: 'u1' });

      const res = await service.findById('u1');

      expect(prismaMock.user.findUnique).toHaveBeenCalledWith({ where: { id: 'u1' } });
      expect(res).toEqual({ id: 'u1' });
    });
  });

  describe('updateProfile', () => {
    it('should update allowed fields', async () => {
      prismaMock.user.update.mockResolvedValue({
        id: 'u1',
        email: 'a@b.com',
        displayName: 'New',
        avatarUrl: 'x',
        bio: 'bio',
        preferences: { lang: 'pl' },
        role: 'user',
      });

      const dto = {
        displayName: 'New',
        avatarUrl: 'x',
        bio: 'bio',
        preferences: { lang: 'pl' },
      } as any;

      const res = await service.updateProfile('u1', dto);

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: {
          displayName: 'New',
          avatarUrl: 'x',
          bio: 'bio',
          preferences: { lang: 'pl' },
        },
        select: {
          id: true,
          email: true,
          displayName: true,
          avatarUrl: true,
          bio: true,
          preferences: true,
          role: true,
        },
      });

      expect(res.displayName).toBe('New');
      expect(res.role).toBe('user');
    });
  });

  describe('changePassword', () => {
    it('should throw if user not found', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);

      await expect(service.changePassword('u404', 'old', 'new')).rejects.toBeInstanceOf(
        BadRequestException,
      );

      expect(prismaMock.user.update).not.toHaveBeenCalled();
    });

    it('should throw if old password is incorrect', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'u1',
        passwordHash: 'HASHED_OLD',
      });
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(service.changePassword('u1', 'old', 'new')).rejects.toBeInstanceOf(
        BadRequestException,
      );

      expect(bcrypt.compare).toHaveBeenCalledWith('old', 'HASHED_OLD');
      expect(prismaMock.user.update).not.toHaveBeenCalled();
    });

    it('should hash new password and update passwordHash', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'u1',
        passwordHash: 'HASHED_OLD',
      });
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      (bcrypt.hash as jest.Mock).mockResolvedValue('HASHED_NEW');
      prismaMock.user.update.mockResolvedValue({ id: 'u1' });

      const res = await service.changePassword('u1', 'old', 'new');

      expect(bcrypt.compare).toHaveBeenCalledWith('old', 'HASHED_OLD');
      expect(bcrypt.hash).toHaveBeenCalledWith('new', 10);

      expect(prismaMock.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { passwordHash: 'HASHED_NEW' },
      });

      expect(res).toEqual({ success: true });
    });
  });
});
