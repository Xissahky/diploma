import { AuthService } from './auth.service';
import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

jest.mock('bcrypt');

describe('AuthService', () => {
  let service: AuthService;

  const usersServiceMock = {
    findByEmail: jest.fn(),
    createUser: jest.fn(),
  };

  const jwtServiceMock = {
    sign: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AuthService(usersServiceMock as any, jwtServiceMock as any);
  });

  describe('validateUser', () => {
    it('should throw UnauthorizedException when user not found', async () => {
      usersServiceMock.findByEmail.mockResolvedValue(null);

      await expect(service.validateUser('a@b.com', 'pass'))
        .rejects
        .toBeInstanceOf(UnauthorizedException);

      expect(usersServiceMock.findByEmail).toHaveBeenCalledWith('a@b.com');
      expect(bcrypt.compare).not.toHaveBeenCalled();
    });

    it('should throw UnauthorizedException when password is invalid', async () => {
      usersServiceMock.findByEmail.mockResolvedValue({
        id: 'u1',
        email: 'a@b.com',
        passwordHash: 'hash',
      });

      (bcrypt.compare as any).mockResolvedValue(false);

      await expect(service.validateUser('a@b.com', 'wrong'))
        .rejects
        .toBeInstanceOf(UnauthorizedException);

      expect(usersServiceMock.findByEmail).toHaveBeenCalledWith('a@b.com');
      expect(bcrypt.compare).toHaveBeenCalledWith('wrong', 'hash');
    });

    it('should return user when password is valid', async () => {
      const user = {
        id: 'u1',
        email: 'a@b.com',
        passwordHash: 'hash',
        role: 'user',
        displayName: 'Tester',
      };
      usersServiceMock.findByEmail.mockResolvedValue(user);
      (bcrypt.compare as any).mockResolvedValue(true);

      const result = await service.validateUser('a@b.com', 'ok');

      expect(result).toEqual(user);
      expect(bcrypt.compare).toHaveBeenCalledWith('ok', 'hash');
    });
  });

  describe('login', () => {
    it('should return access_token and user payload', async () => {
      const user = {
        id: 'u1',
        email: 'a@b.com',
        displayName: 'Tester',
        role: 'user',
      };

      jwtServiceMock.sign.mockReturnValue('jwt.token');

      const result = await service.login(user);

      expect(jwtServiceMock.sign).toHaveBeenCalledWith({ sub: 'u1', role: 'user' });
      expect(result).toEqual({
        access_token: 'jwt.token',
        user: {
          id: 'u1',
          email: 'a@b.com',
          displayName: 'Tester',
          role: 'user',
        },
      });
    });
  });

  describe('register', () => {
    it('should throw UnauthorizedException when email already used', async () => {
      usersServiceMock.findByEmail.mockResolvedValue({
        id: 'u-existing',
        email: 'a@b.com',
      });

      await expect(service.register('a@b.com', 'pass', 'Name'))
        .rejects
        .toBeInstanceOf(UnauthorizedException);

      expect(usersServiceMock.findByEmail).toHaveBeenCalledWith('a@b.com');
      expect(usersServiceMock.createUser).not.toHaveBeenCalled();
      expect(jwtServiceMock.sign).not.toHaveBeenCalled();
    });

    it('should create user and return login response when email is free', async () => {
      usersServiceMock.findByEmail.mockResolvedValue(null);

      const createdUser = {
        id: 'u1',
        email: 'a@b.com',
        displayName: 'Name',
        role: 'user',
      };

      usersServiceMock.createUser.mockResolvedValue(createdUser);
      jwtServiceMock.sign.mockReturnValue('jwt.token');

      const result = await service.register('a@b.com', 'pass', 'Name');

      expect(usersServiceMock.findByEmail).toHaveBeenCalledWith('a@b.com');
      expect(usersServiceMock.createUser).toHaveBeenCalledWith('a@b.com', 'pass', 'Name');
      expect(jwtServiceMock.sign).toHaveBeenCalledWith({ sub: 'u1', role: 'user' });

      expect(result).toEqual({
        access_token: 'jwt.token',
        user: {
          id: 'u1',
          email: 'a@b.com',
          displayName: 'Name',
          role: 'user',
        },
      });
    });
  });
});
