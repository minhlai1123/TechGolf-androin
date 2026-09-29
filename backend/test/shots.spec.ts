import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { ShotsService } from '../src/shots/shots.service';
import { ShotsController } from '../src/shots/shots.controller';
import { ClubDistanceController } from '../src/shots/club-distance.controller';
import { Shot, ShotStatus, DistanceUnit } from '../src/shots/entities/shot.entity';
import { Round, GameMode, RoundStatus } from '../src/rounds/entities/round.entity';
import { RoundPlayer } from '../src/rounds/entities/round-player.entity';
import { Hole } from '../src/courses/entities/hole.entity';
import { GolfBagClub, ClubType } from '../src/golf-bag/entities/golf-bag-club.entity';
import { StartShotDto } from '../src/shots/dto/start-shot.dto';
import { SaveShotDto } from '../src/shots/dto/save-shot.dto';

describe('ShotsModule Integration Tests', () => {
  let shotsService: ShotsService;
  let shotsController: ShotsController;
  let clubDistanceController: ClubDistanceController;

  const userId = 'user-uuid-1111';
  const otherUserId = 'user-uuid-9999';
  const roundId = 'round-uuid-2222';
  const courseId = 'course-uuid-3333';
  const playerId1 = 'player-uuid-4441';
  const holeId1 = 'hole-uuid-5551';
  const clubId1 = 'club-uuid-6661';
  const shotId1 = 'shot-uuid-7771';

  let mockRound: Partial<Round>;
  let mockPlayer: Partial<RoundPlayer>;
  let mockHole: Partial<Hole>;
  let mockClub: Partial<GolfBagClub>;
  let mockShot: Partial<Shot>;

  const mockShotRepo = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockRoundRepo = {
    findOne: jest.fn(),
  };

  const mockPlayerRepo = {
    findOne: jest.fn(),
  };

  const mockHoleRepo = {
    findOne: jest.fn(),
  };

  const mockClubRepo = {
    findOne: jest.fn(),
    find: jest.fn(),
    update: jest.fn(),
  };

  beforeEach(async () => {
    mockPlayer = {
      id: playerId1,
      roundId,
      userId,
      playerName: 'Golfer 1',
      playerOrder: 1,
    };

    mockRound = {
      id: roundId,
      courseId,
      createdBy: userId,
      gameMode: GameMode.STROKE_PLAY,
      status: RoundStatus.IN_PROGRESS,
      players: [mockPlayer as RoundPlayer],
    };

    mockHole = {
      id: holeId1,
      course_id: courseId,
      hole_number: 1,
      par: 4,
    };

    mockClub = {
      id: clubId1,
      user_id: userId,
      club_type: ClubType.IRON_7,
      custom_name: '7 Iron',
      average_distance_meters: 140.0,
      total_shots_recorded: 1,
      is_active: true,
    };

    mockShot = {
      id: shotId1,
      roundId,
      playerId: playerId1,
      userId,
      holeId: holeId1,
      clubId: clubId1,
      status: ShotStatus.STARTED,
      startLatitude: 21.028511,
      startLongitude: 105.854444,
      startElevation: 10.0,
      distanceUnit: DistanceUnit.YARDS,
      round: mockRound as Round,
      player: mockPlayer as RoundPlayer,
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ShotsController, ClubDistanceController],
      providers: [
        ShotsService,
        { provide: getRepositoryToken(Shot), useValue: mockShotRepo },
        { provide: getRepositoryToken(Round), useValue: mockRoundRepo },
        { provide: getRepositoryToken(RoundPlayer), useValue: mockPlayerRepo },
        { provide: getRepositoryToken(Hole), useValue: mockHoleRepo },
        { provide: getRepositoryToken(GolfBagClub), useValue: mockClubRepo },
      ],
    }).compile();

    shotsService = module.get<ShotsService>(ShotsService);
    shotsController = module.get<ShotsController>(ShotsController);
    clubDistanceController = module.get<ClubDistanceController>(ClubDistanceController);

    jest.clearAllMocks();
  });

  describe('startShot', () => {
    it('successfully initiates a shot in STARTED state', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);
      mockHoleRepo.findOne.mockResolvedValue(mockHole);
      mockClubRepo.findOne.mockResolvedValue(mockClub);

      const createdShot = {
        ...mockShot,
        id: shotId1,
        status: ShotStatus.STARTED,
      };
      mockShotRepo.create.mockReturnValue(createdShot);
      mockShotRepo.save.mockResolvedValue(createdShot);

      const dto: StartShotDto = {
        playerId: playerId1,
        holeId: holeId1,
        clubId: clubId1,
        latitude: 21.028511,
        longitude: 105.854444,
        elevation: 10.0,
        unit: DistanceUnit.YARDS,
      };

      const result = await shotsController.startShot({ userId } as any, roundId, dto);

      expect(mockRoundRepo.findOne).toHaveBeenCalledWith({
        where: { id: roundId },
        relations: ['players'],
      });
      expect(mockHoleRepo.findOne).toHaveBeenCalledWith({
        where: { id: holeId1, course_id: courseId },
      });
      expect(result.status).toBe(ShotStatus.STARTED);
      expect(result.startLatitude).toBe(21.028511);
    });

    it('rejects start shot if player does not belong to round', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);

      const dto: StartShotDto = {
        playerId: 'unknown-player-id',
        holeId: holeId1,
        latitude: 21.028511,
        longitude: 105.854444,
      };

      await expect(
        shotsController.startShot({ userId } as any, roundId, dto),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects start shot if user is not authorized for round or player', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);

      const dto: StartShotDto = {
        playerId: playerId1,
        holeId: holeId1,
        latitude: 21.028511,
        longitude: 105.854444,
      };

      await expect(
        shotsController.startShot({ userId: otherUserId } as any, roundId, dto),
      ).rejects.toThrow(ForbiddenException);
    });

    it('rejects start shot if hole does not belong to course', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);
      mockHoleRepo.findOne.mockResolvedValue(null); // Hole not found on course

      const dto: StartShotDto = {
        playerId: playerId1,
        holeId: holeId1,
        latitude: 21.028511,
        longitude: 105.854444,
      };

      await expect(
        shotsController.startShot({ userId } as any, roundId, dto),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('saveShot', () => {
    it('calculates geodesic distance and saves shot in SAVED state', async () => {
      mockShotRepo.findOne.mockResolvedValue({
        ...mockShot,
        status: ShotStatus.STARTED,
      });
      mockClubRepo.findOne.mockResolvedValue(mockClub);

      const savedResult = {
        ...mockShot,
        endLatitude: 21.029800,
        endLongitude: 105.855200,
        endElevation: 18.0,
        elevationDelta: 8.0,
        distance: 165.2,
        status: ShotStatus.SAVED,
      };
      mockShotRepo.save.mockResolvedValue(savedResult);
      mockShotRepo.find.mockResolvedValue([savedResult]); // For recalculate average
      mockClubRepo.update.mockResolvedValue({});

      const dto: SaveShotDto = {
        clubId: clubId1,
        latitude: 21.029800,
        longitude: 105.855200,
        elevation: 18.0,
        unit: DistanceUnit.YARDS,
      };

      const result = await shotsController.saveShot(
        { userId } as any,
        roundId,
        shotId1,
        dto,
      );

      expect(result.status).toBe(ShotStatus.SAVED);
      expect(result.distance).toBeGreaterThan(0);
      expect(mockClubRepo.update).toHaveBeenCalled();
    });

    it('rejects saving a shot that is already SAVED', async () => {
      mockShotRepo.findOne.mockResolvedValue({
        ...mockShot,
        status: ShotStatus.SAVED,
      });

      const dto: SaveShotDto = {
        clubId: clubId1,
        latitude: 21.029800,
        longitude: 105.855200,
      };

      await expect(
        shotsController.saveShot({ userId } as any, roundId, shotId1, dto),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects saving a shot if club not found in user bag', async () => {
      mockShotRepo.findOne.mockResolvedValue({
        ...mockShot,
        status: ShotStatus.STARTED,
      });
      mockClubRepo.findOne.mockResolvedValue(null);

      const dto: SaveShotDto = {
        clubId: 'unknown-club-id',
        latitude: 21.029800,
        longitude: 105.855200,
      };

      await expect(
        shotsController.saveShot({ userId } as any, roundId, shotId1, dto),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('recalculateClubAverage', () => {
    it('computes arithmetic average of recorded saved shots for club', async () => {
      // 2 shots: 150m and 170m -> average 160m
      const shots: Partial<Shot>[] = [
        { distance: 150, distanceUnit: DistanceUnit.METERS, status: ShotStatus.SAVED },
        { distance: 170, distanceUnit: DistanceUnit.METERS, status: ShotStatus.SAVED },
      ];
      mockShotRepo.find.mockResolvedValue(shots);
      mockClubRepo.update.mockResolvedValue({});

      await shotsService.recalculateClubAverage(clubId1);

      expect(mockClubRepo.update).toHaveBeenCalledWith(clubId1, {
        average_distance_meters: 160.0,
        total_shots_recorded: 2,
      });
    });
  });

  describe('getShotsByRound and getShotsByHole', () => {
    it('returns all shots for a round when user is member', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);
      mockShotRepo.find.mockResolvedValue([mockShot]);

      const result = await shotsController.getShotsByRound(
        { userId } as any,
        roundId,
      );

      expect(result).toHaveLength(1);
      expect(mockShotRepo.find).toHaveBeenCalledWith({
        where: { roundId },
        relations: ['player', 'club', 'hole'],
        order: { createdAt: 'ASC' },
      });
    });

    it('rejects viewing shots for non-members', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);

      await expect(
        shotsController.getShotsByRound({ userId: otherUserId } as any, roundId),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('Club Distances & Recommendations', () => {
    it('returns club distances with yards and meters conversions', async () => {
      mockClubRepo.find.mockResolvedValue([mockClub]);

      const result = await clubDistanceController.getClubDistances({ userId } as any);

      expect(result).toHaveLength(1);
      expect(result[0].clubType).toBe(ClubType.IRON_7);
      expect(result[0].averageDistanceMeters).toBe(140.0);
      expect(result[0].averageDistanceYards).toBeCloseTo(153.1, 1);
    });

    it('computes plays-like distance and recommends club', async () => {
      mockClubRepo.find.mockResolvedValue([mockClub]); // 140m avg (~153.1 yards)

      const result = await clubDistanceController.recommendClub(
        { userId } as any,
        {
          remainingDistance: 150,
          unit: DistanceUnit.YARDS,
          startElevation: 10,
          targetElevation: 13, // +3m -> +3.3y adjustment
        },
      );

      expect(result.playsLike).toBeDefined();
      expect(result.playsLike.hasElevation).toBe(true);
      expect(result.playsLike.playsLikeDistance).toBeGreaterThan(150);
      expect(result.recommendation.hasRecommendation).toBe(true);
      expect(result.recommendation.recommendedClub.clubType).toBe(ClubType.IRON_7);
    });
  });
});
