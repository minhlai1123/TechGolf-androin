import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ConflictException, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { validate } from 'class-validator';
import * as bcrypt from 'bcrypt';
import { AuthService } from '../src/auth/auth.service';
import { AuthController } from '../src/auth/auth.controller';
import { User } from '../src/users/entities/user.entity';
import { RegisterDto } from '../src/auth/dto/register.dto';
import { JwtAuthGuard } from '../src/auth/guards/jwt-auth.guard';

describe('AuthModule Tests', () => {
  let authService: AuthService;
  let authController: AuthController;

  const mockUser: Partial<User> = {
    id: '11111111-1111-1111-1111-111111111111',
    email: 'golfer@techgolf.com',
    password_hash: '$2b$10$hashedpasswordstringsample12345',
    full_name: 'Tiger Golfer',
    handicap_index: 10.5,
    created_at: new Date(),
    updated_at: new Date(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    createQueryBuilder: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn().mockReturnValue('mocked.jwt.token'),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'bcrypt.saltRounds') return 10;
      if (key === 'jwt.secret') return 'test_jwt_secret';
      return null;
    }),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        AuthService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    authController = module.get<AuthController>(AuthController);
  });

  describe('DTO Validation Tests', () => {
    it('should validate valid RegisterDto', async () => {
      const dto = new RegisterDto();
      dto.email = 'valid@example.com';
      dto.password = 'StrongPass123!';
      dto.full_name = 'Valid Golfer';

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should fail on invalid email format', async () => {
      const dto = new RegisterDto();
      dto.email = 'not-an-email';
      dto.password = 'Password123';
      dto.full_name = 'Golfer';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].property).toBe('email');
    });

    it('should fail on weak/short password (<6 characters)', async () => {
      const dto = new RegisterDto();
      dto.email = 'golfer@example.com';
      dto.password = '123';
      dto.full_name = 'Golfer';

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.some((e) => e.property === 'password')).toBe(true);
    });
  });

  describe('AuthService.register', () => {
    it('should register successfully and return user with access token', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);
      mockUserRepository.create.mockReturnValue({
        ...mockUser,
        email: 'new@techgolf.com',
      });
      mockUserRepository.save.mockResolvedValue({
        ...mockUser,
        email: 'new@techgolf.com',
      });

      const result = await authService.register({
        email: 'new@techgolf.com',
        password: 'Password123!',
        full_name: 'New Golfer',
      });

      expect(result).toHaveProperty('accessToken', 'mocked.jwt.token');
      expect(result.user.email).toBe('new@techgolf.com');
      expect(mockUserRepository.save).toHaveBeenCalled();
    });

    it('should throw ConflictException on duplicate email', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);

      await expect(
        authService.register({
          email: 'golfer@techgolf.com',
          password: 'Password123!',
          full_name: 'Duplicate Golfer',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('AuthService.login', () => {
    it('should login successfully with correct credentials', async () => {
      const plainPassword = 'CorrectPassword123!';
      const hash = await bcrypt.hash(plainPassword, 10);

      const queryBuilder = {
        addSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue({
          ...mockUser,
          password_hash: hash,
        }),
      };
      mockUserRepository.createQueryBuilder.mockReturnValue(queryBuilder);

      const result = await authService.login({
        email: 'golfer@techgolf.com',
        password: plainPassword,
      });

      expect(result).toHaveProperty('accessToken', 'mocked.jwt.token');
      expect(result.user.email).toBe(mockUser.email);
    });

    it('should throw UnauthorizedException on wrong password', async () => {
      const hash = await bcrypt.hash('CorrectPassword123!', 10);

      const queryBuilder = {
        addSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue({
          ...mockUser,
          password_hash: hash,
        }),
      };
      mockUserRepository.createQueryBuilder.mockReturnValue(queryBuilder);

      await expect(
        authService.login({
          email: 'golfer@techgolf.com',
          password: 'WrongPassword999!',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException when user not found', async () => {
      const queryBuilder = {
        addSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(null),
      };
      mockUserRepository.createQueryBuilder.mockReturnValue(queryBuilder);

      await expect(
        authService.login({
          email: 'notfound@techgolf.com',
          password: 'SomePassword!',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('AuthService.getMe & Controller /auth/me', () => {
    it('should return current user when valid userId is provided', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);

      const result = await authController.getMe({
        userId: mockUser.id!,
        email: mockUser.email!,
      });

      expect(result).toEqual(mockUser);
    });

    it('should throw NotFoundException if user id does not exist', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      await expect(authService.getMe('non-existent-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('JwtAuthGuard', () => {
    let guard: JwtAuthGuard;

    beforeEach(() => {
      guard = new JwtAuthGuard();
    });

    it('should throw UnauthorizedException when user is not present (no token / invalid token)', () => {
      expect(() => guard.handleRequest(null, null, null)).toThrow(
        UnauthorizedException,
      );
    });

    it('should return user object when authenticated', () => {
      const payload = { userId: '123', email: 'test@techgolf.com' };
      const user = guard.handleRequest(null, payload, null);
      expect(user).toEqual(payload);
    });
  });
});
