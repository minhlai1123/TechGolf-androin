import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { RoundsService } from '../src/rounds/rounds.service';
import { RoundsController } from '../src/rounds/rounds.controller';
import { Round, GameMode, RoundStatus } from '../src/rounds/entities/round.entity';
import { RoundPlayer } from '../src/rounds/entities/round-player.entity';
import { RoundScore } from '../src/rounds/entities/round-score.entity';
import { Course } from '../src/courses/entities/course.entity';
import { Hole } from '../src/courses/entities/hole.entity';
import { CreateRoundDto } from '../src/rounds/dto/create-round.dto';
import { SaveScoreDto } from '../src/rounds/dto/save-score.dto';

describe('RoundsModule Tests', () => {
  let controller: RoundsController;

  const userId = 'user-uuid-1111';
  const otherUserId = 'user-uuid-9999';
  const courseId = 'course-uuid-2222';
  const roundId = 'round-uuid-3333';
  const playerId1 = 'player-uuid-4441';
  const playerId2 = 'player-uuid-4442';
  const holeId1 = 'hole-uuid-5551';
  const holeId2 = 'hole-uuid-5552';

  const mockCourse: Partial<Course> = {
    id: courseId,
    name: 'Pine Valley Golf Club',
  };

  const mockHoles: Partial<Hole>[] = [
    { id: holeId1, course_id: courseId, hole_number: 1, par: 4, handicap_index: 5 },
    { id: holeId2, course_id: courseId, hole_number: 2, par: 3, handicap_index: 7 },
  ];

  let mockRound: Partial<Round>;
  let mockPlayers: Partial<RoundPlayer>[];
  let mockScores: Partial<RoundScore>[];

  const mockRoundRepo = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
  };

  const mockPlayerRepo = {
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
  };

  const mockScoreRepo = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockCourseRepo = {
    findOne: jest.fn(),
  };

  const mockHoleRepo = {
    findOne: jest.fn(),
    find: jest.fn(),
  };

  beforeEach(async () => {
    mockPlayers = [
      { id: playerId1, roundId, userId, playerName: 'Minh', playerOrder: 1 },
      { id: playerId2, roundId, userId: null, playerName: 'Guest', playerOrder: 2 },
    ];

    mockScores = [];

    mockRound = {
      id: roundId,
      courseId,
      gameMode: GameMode.STROKE_PLAY,
      status: RoundStatus.NOT_STARTED,
      currentHole: 1,
      createdBy: userId,
      players: mockPlayers as RoundPlayer[],
      scores: mockScores as RoundScore[],
      course: mockCourse as Course,
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [RoundsController],
      providers: [
        RoundsService,
        { provide: getRepositoryToken(Round), useValue: mockRoundRepo },
        { provide: getRepositoryToken(RoundPlayer), useValue: mockPlayerRepo },
        { provide: getRepositoryToken(RoundScore), useValue: mockScoreRepo },
        { provide: getRepositoryToken(Course), useValue: mockCourseRepo },
        { provide: getRepositoryToken(Hole), useValue: mockHoleRepo },
      ],
    }).compile();

    controller = module.get<RoundsController>(RoundsController);

    jest.clearAllMocks();
  });

  describe('Round Creation & Flight Validation', () => {
    test('creates round with 1 player successfully', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);
      mockRoundRepo.create.mockReturnValue(mockRound);
      mockRoundRepo.save.mockResolvedValue(mockRound);
      mockPlayerRepo.create.mockImplementation((dto) => dto);
      mockPlayerRepo.save.mockResolvedValue([mockPlayers[0]]);
      mockRoundRepo.findOne.mockResolvedValue(mockRound);

      const dto: CreateRoundDto = {
        courseId,
        gameMode: GameMode.STROKE_PLAY,
        players: [
          { playerName: 'Solo Player', playerOrder: 1, userId },
        ],
      };

      const result = await controller.createRound({ userId, role: 'USER' } as any, dto);
      expect(result).toBeDefined();
      expect(result.id).toBe(roundId);
    });

    test('creates round with 4 players successfully', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);
      mockRoundRepo.create.mockReturnValue(mockRound);
      mockRoundRepo.save.mockResolvedValue(mockRound);
      mockPlayerRepo.create.mockImplementation((dto) => dto);
      mockPlayerRepo.save.mockResolvedValue(mockPlayers);
      mockRoundRepo.findOne.mockResolvedValue(mockRound);

      const dto: CreateRoundDto = {
        courseId,
        gameMode: GameMode.STROKE_PLAY,
        players: [
          { playerName: 'P1', playerOrder: 1, userId },
          { playerName: 'P2', playerOrder: 2 },
          { playerName: 'P3', playerOrder: 3 },
          { playerName: 'P4', playerOrder: 4 },
        ],
      };

      const result = await controller.createRound({ userId, role: 'USER' } as any, dto);
      expect(result).toBeDefined();
    });

    test('rejects round creation when course not found', async () => {
      mockCourseRepo.findOne.mockResolvedValue(null);

      const dto: CreateRoundDto = {
        courseId: 'non-existent',
        gameMode: GameMode.STROKE_PLAY,
        players: [{ playerName: 'P1', playerOrder: 1 }],
      };

      await expect(
        controller.createRound({ userId, role: 'USER' } as any, dto),
      ).rejects.toThrow(NotFoundException);
    });

    test('rejects round creation with duplicate player order', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);

      const dto: CreateRoundDto = {
        courseId,
        gameMode: GameMode.STROKE_PLAY,
        players: [
          { playerName: 'P1', playerOrder: 1 },
          { playerName: 'P2', playerOrder: 1 }, // Duplicate order 1
        ],
      };

      await expect(
        controller.createRound({ userId, role: 'USER' } as any, dto),
      ).rejects.toThrow(BadRequestException);
    });

    test('rejects round creation with duplicate registered users', async () => {
      mockCourseRepo.findOne.mockResolvedValue(mockCourse);

      const dto: CreateRoundDto = {
        courseId,
        gameMode: GameMode.STROKE_PLAY,
        players: [
          { playerName: 'P1', playerOrder: 1, userId },
          { playerName: 'P2', playerOrder: 2, userId }, // Duplicate userId
        ],
      };

      await expect(
        controller.createRound({ userId, role: 'USER' } as any, dto),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('Round Lifecycle: Start, Current Hole, Finish', () => {
    test('starts a NOT_STARTED round', async () => {
      mockRoundRepo.findOne.mockResolvedValue({
        ...mockRound,
        status: RoundStatus.NOT_STARTED,
      });
      mockRoundRepo.save.mockImplementation((r) => Promise.resolve(r));

      const result = await controller.startRound({ userId } as any, roundId);
      expect(result.status).toBe(RoundStatus.IN_PROGRESS);
      expect(result.startedAt).toBeDefined();
    });

    test('rejects starting already started round', async () => {
      mockRoundRepo.findOne.mockResolvedValue({
        ...mockRound,
        status: RoundStatus.IN_PROGRESS,
      });

      await expect(
        controller.startRound({ userId } as any, roundId),
      ).rejects.toThrow(BadRequestException);
    });

    test('updates current hole when IN_PROGRESS', async () => {
      mockRoundRepo.findOne.mockResolvedValue({
        ...mockRound,
        status: RoundStatus.IN_PROGRESS,
      });
      mockRoundRepo.save.mockImplementation((r) => Promise.resolve(r));

      const result = await controller.updateCurrentHole({ userId } as any, roundId, { currentHole: 3 });
      expect(result.currentHole).toBe(3);
    });

    test('finishes an IN_PROGRESS round', async () => {
      mockRoundRepo.findOne.mockResolvedValue({
        ...mockRound,
        status: RoundStatus.IN_PROGRESS,
      });
      mockRoundRepo.save.mockImplementation((r) => Promise.resolve(r));

      const result = await controller.finishRound({ userId } as any, roundId);
      expect(result.status).toBe(RoundStatus.COMPLETED);
      expect(result.finishedAt).toBeDefined();
    });
  });

  describe('Score Entry & Validation', () => {
    beforeEach(() => {
      mockRoundRepo.findOne.mockResolvedValue({
        ...mockRound,
        status: RoundStatus.IN_PROGRESS,
      });
    });

    test('saves valid score for player on hole', async () => {
      mockHoleRepo.findOne.mockResolvedValue(mockHoles[0]);
      mockScoreRepo.findOne.mockResolvedValue(null);
      mockScoreRepo.create.mockImplementation((dto) => dto);
      mockScoreRepo.save.mockImplementation((dto) => Promise.resolve({ id: 'score-1', ...dto }));

      const dto: SaveScoreDto = {
        playerId: playerId1,
        holeId: holeId1,
        grossScore: 4,
        putts: 2,
        penalties: 0,
        fairwayHit: 'STRAIGHT' as any,
        gir: true,
      };

      const result = await controller.saveScore({ userId } as any, roundId, dto);
      expect(result).toBeDefined();
      expect(result.grossScore).toBe(4);
      expect(result.putts).toBe(2);
    });

    test('rejects score entry when putts > grossScore', async () => {
      mockHoleRepo.findOne.mockResolvedValue(mockHoles[0]);

      const dto: SaveScoreDto = {
        playerId: playerId1,
        holeId: holeId1,
        grossScore: 3,
        putts: 4, // 4 putts > 3 gross -> Invalid!
      };

      await expect(
        controller.saveScore({ userId } as any, roundId, dto),
      ).rejects.toThrow(BadRequestException);
    });

    test('rejects score for player not in round', async () => {
      const dto: SaveScoreDto = {
        playerId: 'foreign-player-id',
        holeId: holeId1,
        grossScore: 4,
      };

      await expect(
        controller.saveScore({ userId } as any, roundId, dto),
      ).rejects.toThrow(BadRequestException);
    });

    test('rejects score for hole not belonging to course', async () => {
      mockHoleRepo.findOne.mockResolvedValue(null);

      const dto: SaveScoreDto = {
        playerId: playerId1,
        holeId: 'foreign-hole-id',
        grossScore: 4,
      };

      await expect(
        controller.saveScore({ userId } as any, roundId, dto),
      ).rejects.toThrow(BadRequestException);
    });

    test('upserts score when score already exists for hole', async () => {
      const existingScore: Partial<RoundScore> = {
        id: 'score-existing',
        roundId,
        playerId: playerId1,
        holeId: holeId1,
        grossScore: 5,
        putts: 3,
      };
      mockHoleRepo.findOne.mockResolvedValue(mockHoles[0]);
      mockScoreRepo.findOne.mockResolvedValue(existingScore);
      mockScoreRepo.save.mockImplementation((s) => Promise.resolve(s));

      const dto: SaveScoreDto = {
        playerId: playerId1,
        holeId: holeId1,
        grossScore: 4,
        putts: 2,
      };

      const result = await controller.saveScore({ userId } as any, roundId, dto);
      expect(result.id).toBe('score-existing');
      expect(result.grossScore).toBe(4);
      expect(result.putts).toBe(2);
    });
  });

  describe('Authorization & Scorecard Retrieval', () => {
    test('rejects access to round from non-participant user', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);

      await expect(
        controller.getRound({ userId: otherUserId } as any, roundId),
      ).rejects.toThrow(ForbiddenException);
    });

    test('retrieves full scorecard matrix', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);
      mockHoleRepo.find.mockResolvedValue(mockHoles);
      mockScoreRepo.find.mockResolvedValue([
        {
          id: 's1',
          roundId,
          playerId: playerId1,
          holeId: holeId1,
          grossScore: 4,
          putts: 2,
          penalties: 0,
          fairwayHit: 'STRAIGHT',
          gir: true,
        },
      ]);

      const scorecard = await controller.getScorecard({ userId } as any, roundId);
      expect(scorecard).toBeDefined();
      expect(scorecard.holes.length).toBe(2);
      expect(scorecard.players.length).toBe(2);
      expect(scorecard.totals.length).toBe(2);
      expect(scorecard.totals[0].grossScore).toBe(4);
    });

    test('retrieves game mode result summary', async () => {
      mockRoundRepo.findOne.mockResolvedValue(mockRound);
      mockHoleRepo.find.mockResolvedValue(mockHoles);
      mockScoreRepo.find.mockResolvedValue([]);

      const result = await controller.getRoundResult({ userId } as any, roundId);
      expect(result).toBeDefined();
      expect(result.gameMode).toBe(GameMode.STROKE_PLAY);
      expect(result.strokePlay).toBeDefined();
    });
  });
});
