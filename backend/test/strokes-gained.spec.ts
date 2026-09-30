import { StrokesGainedClassifier } from '../src/strokes-gained/strokes-gained.classifier';
import { ShotCategory } from '../src/strokes-gained/strokes-gained.types';
import { ClubType } from '../src/golf-bag/entities/golf-bag-club.entity';
import {
  NullStrokesGainedBenchmarkProvider,
  MockStrokesGainedBenchmarkProvider,
} from '../src/strokes-gained/benchmark/strokes-gained-benchmark.provider';
import { StrokesGainedService } from '../src/strokes-gained/strokes-gained.service';
import { ShotStatus } from '../src/shots/entities/shot.entity';

describe('Strokes Gained Framework', () => {
  describe('StrokesGainedClassifier', () => {
    it('classifies tee shot on Par 4 and Par 5 as DRIVING (Off-the-Tee)', () => {
      const catPar4 = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 1,
        clubType: ClubType.DRIVER,
      });
      expect(catPar4).toBe(ShotCategory.DRIVING);

      const catPar5 = StrokesGainedClassifier.classifyShot({
        holePar: 5,
        shotIndexOnHole: 1,
        clubType: ClubType.WOOD_3,
      });
      expect(catPar5).toBe(ShotCategory.DRIVING);
    });

    it('classifies tee shot on Par 3 as APPROACH', () => {
      const catPar3 = StrokesGainedClassifier.classifyShot({
        holePar: 3,
        shotIndexOnHole: 1,
        clubType: ClubType.IRON_7,
      });
      expect(catPar3).toBe(ShotCategory.APPROACH);
    });

    it('classifies shots taken with Putter or on green as PUTTING', () => {
      const catPutter = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 3,
        clubType: ClubType.PUTTER,
      });
      expect(catPutter).toBe(ShotCategory.PUTTING);

      const catOnGreen = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 2,
        isOnGreen: true,
      });
      expect(catOnGreen).toBe(ShotCategory.PUTTING);
    });

    it('classifies shots within 100 yards (91.44m) of green as SHORT_GAME', () => {
      const catShort = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 2,
        startDistanceToGreenMeters: 50.0,
      });
      expect(catShort).toBe(ShotCategory.SHORT_GAME);
    });

    it('classifies shots beyond 100 yards (91.44m) of green as APPROACH', () => {
      const catApproach = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 2,
        startDistanceToGreenMeters: 145.0,
      });
      expect(catApproach).toBe(ShotCategory.APPROACH);
    });

    it('uses club fallback heuristics when distance to green is missing', () => {
      const catWedge = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 2,
        clubType: ClubType.SAND_WEDGE,
      });
      expect(catWedge).toBe(ShotCategory.SHORT_GAME);

      const catIron = StrokesGainedClassifier.classifyShot({
        holePar: 4,
        shotIndexOnHole: 2,
        clubType: ClubType.IRON_6,
      });
      expect(catIron).toBe(ShotCategory.APPROACH);
    });
  });

  describe('Benchmark Providers', () => {
    it('NullStrokesGainedBenchmarkProvider returns UNAVAILABLE without faking numbers', async () => {
      const provider = new NullStrokesGainedBenchmarkProvider();
      const res = await provider.getExpectedStrokes(ShotCategory.DRIVING, 250);
      expect(res.status).toBe('UNAVAILABLE');
      expect(res.expectedStrokes).toBeNull();
      expect(res.reason).toContain('unavailable');
    });

    it('MockStrokesGainedBenchmarkProvider returns expected strokes when available', async () => {
      const mock = new MockStrokesGainedBenchmarkProvider('AVAILABLE');
      const res = await mock.getExpectedStrokes(ShotCategory.PUTTING, 3.0);
      expect(res.status).toBe('AVAILABLE');
      expect(typeof res.expectedStrokes).toBe('number');
      expect(res.expectedStrokes).toBeGreaterThan(0);
    });
  });

  describe('StrokesGainedService', () => {
    let service: StrokesGainedService;
    let mockShotRepo: any;
    let mockRoundRepo: any;
    let mockPlayerRepo: any;
    let mockHoleRepo: any;

    beforeEach(() => {
      mockShotRepo = {
        createQueryBuilder: jest.fn().mockReturnValue({
          leftJoinAndSelect: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          andWhere: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          addOrderBy: jest.fn().mockReturnThis(),
          getMany: jest.fn().mockResolvedValue([
            {
              id: 'shot-1',
              holeId: 'hole-1',
              status: ShotStatus.SAVED,
              distance: 230,
              club: { club_type: ClubType.DRIVER },
              hole: { par: 4 },
              createdAt: new Date('2026-09-01T10:00:00Z'),
            },
            {
              id: 'shot-2',
              holeId: 'hole-1',
              status: ShotStatus.SAVED,
              distance: 140,
              club: { club_type: ClubType.IRON_7 },
              hole: { par: 4 },
              createdAt: new Date('2026-09-01T10:05:00Z'),
            },
            {
              id: 'shot-3',
              holeId: 'hole-1',
              status: ShotStatus.SAVED,
              distance: 4,
              club: { club_type: ClubType.PUTTER },
              hole: { par: 4 },
              createdAt: new Date('2026-09-01T10:10:00Z'),
            },
          ]),
        }),
      };
      mockRoundRepo = {};
      mockPlayerRepo = {};
      mockHoleRepo = {};

      service = new StrokesGainedService(
        mockShotRepo,
        mockRoundRepo,
        mockPlayerRepo,
        mockHoleRepo,
        new NullStrokesGainedBenchmarkProvider(),
      );
    });

    it('returns status UNAVAILABLE and null strokes gained when benchmark table is unavailable (NEVER fake 0.00)', async () => {
      const summary = await service.getStrokesGained('user-uuid');
      expect(summary.status).toBe('UNAVAILABLE');
      expect(summary.totalStrokesGained).toBeNull();
      expect(summary.categories[ShotCategory.DRIVING].strokesGained).toBeNull();
      expect(summary.categories[ShotCategory.DRIVING].shotsCount).toBe(1);
      expect(summary.categories[ShotCategory.APPROACH].shotsCount).toBe(1);
      expect(summary.categories[ShotCategory.PUTTING].shotsCount).toBe(1);
      expect(summary.message).toContain('unavailable');
    });

    it('computes strokes gained when benchmark provider is available', async () => {
      const mockProvider = new MockStrokesGainedBenchmarkProvider('AVAILABLE');
      service.setBenchmarkProvider(mockProvider);

      const summary = await service.getStrokesGained('user-uuid');
      expect(summary.status).toBe('AVAILABLE');
      expect(typeof summary.totalStrokesGained).toBe('number');
      expect(summary.categories[ShotCategory.DRIVING].strokesGained).not.toBeNull();
    });
  });
});
