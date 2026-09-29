import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { GolfBagService } from '../src/golf-bag/golf-bag.service';
import { GolfBagController } from '../src/golf-bag/golf-bag.controller';
import { GolfBagClub, ClubType } from '../src/golf-bag/entities/golf-bag-club.entity';

describe('GolfBagModule Tests', () => {
  let golfBagService: GolfBagService;
  let golfBagController: GolfBagController;

  const userAId = 'user-a-1111';
  const userBId = 'user-b-2222';
  const clubId = 'club-uuid-9999';

  const mockClub: Partial<GolfBagClub> = {
    id: clubId,
    user_id: userAId,
    club_type: ClubType.DRIVER,
    custom_name: 'Driver 10.5 deg',
    average_distance_meters: 220.0,
    total_shots_recorded: 15,
    created_at: new Date(),
    updated_at: new Date(),
  };

  const mockClubRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [GolfBagController],
      providers: [
        GolfBagService,
        {
          provide: getRepositoryToken(GolfBagClub),
          useValue: mockClubRepository,
        },
      ],
    }).compile();

    golfBagService = module.get<GolfBagService>(GolfBagService);
    golfBagController = module.get<GolfBagController>(GolfBagController);
  });

  describe('Create club', () => {
    it('should create and return a new club for user', async () => {
      mockClubRepository.create.mockReturnValue({ ...mockClub });
      mockClubRepository.save.mockResolvedValue({ ...mockClub });

      const result = await golfBagService.createClub(userAId, {
        club_type: ClubType.DRIVER,
        custom_name: 'Driver 10.5 deg',
        average_distance_meters: 220.0,
      });

      expect(result.club_type).toBe(ClubType.DRIVER);
      expect(result.user_id).toBe(userAId);
      expect(mockClubRepository.save).toHaveBeenCalled();
    });
  });

  describe('Get clubs', () => {
    it('should return list of clubs for the requesting user', async () => {
      mockClubRepository.find.mockResolvedValue([mockClub]);

      const clubs = await golfBagService.getClubsByUser(userAId);
      expect(clubs.length).toBe(1);
      expect(clubs[0].id).toBe(clubId);
      expect(mockClubRepository.find).toHaveBeenCalledWith({
        where: { user_id: userAId },
        order: { created_at: 'ASC' },
      });
    });
  });

  describe('Update club & Access Control', () => {
    it('should allow user to update their own club', async () => {
      mockClubRepository.findOne.mockResolvedValue({ ...mockClub });
      mockClubRepository.save.mockImplementation(async (c) => c);

      const updated = await golfBagService.updateClub(userAId, clubId, {
        custom_name: 'Updated Driver Name',
        average_distance_meters: 235.0,
      });

      expect(updated.custom_name).toBe('Updated Driver Name');
      expect(updated.average_distance_meters).toBe(235.0);
    });

    it('should REJECT update and throw ForbiddenException if user attempts to edit another users club', async () => {
      // Club belongs to userAId, but userBId is trying to update it
      mockClubRepository.findOne.mockResolvedValue({ ...mockClub });

      await expect(
        golfBagService.updateClub(userBId, clubId, {
          custom_name: 'Malicious Update',
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if club does not exist', async () => {
      mockClubRepository.findOne.mockResolvedValue(null);

      await expect(
        golfBagService.updateClub(userAId, 'non-existent-club', {
          custom_name: 'New Name',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('Delete club & Access Control', () => {
    it('should allow user to delete their own club', async () => {
      mockClubRepository.findOne.mockResolvedValue({ ...mockClub });
      mockClubRepository.remove.mockResolvedValue({ ...mockClub });

      const result = await golfBagService.deleteClub(userAId, clubId);
      expect(result.success).toBe(true);
      expect(mockClubRepository.remove).toHaveBeenCalled();
    });

    it('should REJECT deletion and throw ForbiddenException if user attempts to delete another users club', async () => {
      // Club belongs to userAId, but userBId is trying to delete it
      mockClubRepository.findOne.mockResolvedValue({ ...mockClub });

      await expect(
        golfBagService.deleteClub(userBId, clubId),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('Controller integration', () => {
    it('should route getClubs properly', async () => {
      mockClubRepository.find.mockResolvedValue([mockClub]);

      const result = await golfBagController.getClubs({
        userId: userAId,
        email: 'a@techgolf.com',
      });
      expect(result).toEqual([mockClub]);
    });
  });
});
