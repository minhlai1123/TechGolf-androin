import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { UsersService } from '../src/users/users.service';
import { UsersController } from '../src/users/users.controller';
import { User } from '../src/users/entities/user.entity';

describe('UsersModule Tests', () => {
  let usersService: UsersService;
  let usersController: UsersController;

  const mockUser: Partial<User> = {
    id: 'user-uuid-1234',
    email: 'player@techgolf.com',
    full_name: 'Original Name',
    avatar_url: 'https://example.com/original.jpg',
    handicap_index: 20.0,
    created_at: new Date(),
    updated_at: new Date(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
      ],
    }).compile();

    usersService = module.get<UsersService>(UsersService);
    usersController = module.get<UsersController>(UsersController);
  });

  describe('UsersService.findById', () => {
    it('should return user profile if found', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);

      const result = await usersService.findById('user-uuid-1234');
      expect(result).toEqual(mockUser);
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'user-uuid-1234' },
      });
    });

    it('should throw NotFoundException if user does not exist', async () => {
      mockUserRepository.findOne.mockResolvedValue(null);

      await expect(usersService.findById('unknown-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('UsersService.update', () => {
    it('should successfully update user profile fields', async () => {
      const existing = { ...mockUser };
      mockUserRepository.findOne.mockResolvedValue(existing);
      mockUserRepository.save.mockImplementation(async (u) => u);

      const updated = await usersService.update('user-uuid-1234', {
        full_name: 'Updated Name',
        handicap_index: 15.2,
      });

      expect(updated.full_name).toBe('Updated Name');
      expect(updated.handicap_index).toBe(15.2);
      expect(mockUserRepository.save).toHaveBeenCalled();
    });
  });

  describe('UsersController', () => {
    it('should get profile through controller for authenticated user', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);

      const result = await usersController.getProfile({
        userId: 'user-uuid-1234',
        email: 'player@techgolf.com',
      });

      expect(result).toEqual(mockUser);
    });

    it('should update profile through controller', async () => {
      const existing = { ...mockUser };
      mockUserRepository.findOne.mockResolvedValue(existing);
      mockUserRepository.save.mockImplementation(async (u) => u);

      const result = await usersController.updateProfile(
        { userId: 'user-uuid-1234', email: 'player@techgolf.com' },
        { full_name: 'Controller Updated' },
      );

      expect(result.full_name).toBe('Controller Updated');
    });
  });
});
