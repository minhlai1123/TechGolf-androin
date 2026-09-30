import { Injectable, Optional } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Shot, ShotStatus } from '../shots/entities/shot.entity';
import { Round } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { Hole } from '../courses/entities/hole.entity';
import {
  ShotCategory,
  StrokesGainedCategorySummary,
  StrokesGainedRoundSummary,
  BenchmarkStatus,
} from './strokes-gained.types';
import {
  IStrokesGainedBenchmarkProvider,
  NullStrokesGainedBenchmarkProvider,
} from './benchmark/strokes-gained-benchmark.provider';
import { StrokesGainedClassifier } from './strokes-gained.classifier';

@Injectable()
export class StrokesGainedService {
  private benchmarkProvider: IStrokesGainedBenchmarkProvider;

  constructor(
    @InjectRepository(Shot)
    private readonly shotRepo: Repository<Shot>,
    @InjectRepository(Round)
    private readonly roundRepo: Repository<Round>,
    @InjectRepository(RoundPlayer)
    private readonly playerRepo: Repository<RoundPlayer>,
    @InjectRepository(Hole)
    private readonly holeRepo: Repository<Hole>,
    @Optional()
    benchmarkProvider?: IStrokesGainedBenchmarkProvider,
  ) {
    this.benchmarkProvider = benchmarkProvider || new NullStrokesGainedBenchmarkProvider();
  }

  setBenchmarkProvider(provider: IStrokesGainedBenchmarkProvider): void {
    this.benchmarkProvider = provider;
  }

  /**
   * Evaluates tracked shots and calculates Strokes Gained per category.
   * If benchmark reference dataset is unavailable, explicitly reports UNAVAILABLE
   * without fabricating fake numbers.
   */
  async getStrokesGained(
    userId: string,
    roundId?: string,
  ): Promise<StrokesGainedRoundSummary> {
    const queryBuilder = this.shotRepo
      .createQueryBuilder('shot')
      .leftJoinAndSelect('shot.hole', 'hole')
      .leftJoinAndSelect('shot.club', 'club')
      .where('shot.user_id = :userId', { userId })
      .andWhere('shot.status = :status', { status: ShotStatus.SAVED })
      .orderBy('shot.holeId', 'ASC')
      .addOrderBy('shot.createdAt', 'ASC');

    if (roundId) {
      queryBuilder.andWhere('shot.roundId = :roundId', { roundId });
    }

    const shots = await queryBuilder.getMany();

    // Group shots by hole
    const holeShotsMap = new Map<string, Shot[]>();
    for (const shot of shots) {
      const list = holeShotsMap.get(shot.holeId) || [];
      list.push(shot);
      holeShotsMap.set(shot.holeId, list);
    }

    // Initialize category counters
    const categoryCounts: Record<ShotCategory, number> = {
      [ShotCategory.DRIVING]: 0,
      [ShotCategory.APPROACH]: 0,
      [ShotCategory.SHORT_GAME]: 0,
      [ShotCategory.PUTTING]: 0,
      [ShotCategory.UNKNOWN]: 0,
    };

    const categoryGained: Record<ShotCategory, number> = {
      [ShotCategory.DRIVING]: 0,
      [ShotCategory.APPROACH]: 0,
      [ShotCategory.SHORT_GAME]: 0,
      [ShotCategory.PUTTING]: 0,
      [ShotCategory.UNKNOWN]: 0,
    };

    let totalGained = 0;
    let anyAvailable = false;

    // Check if the benchmark provider is available
    const probe = await this.benchmarkProvider.getExpectedStrokes(ShotCategory.DRIVING, 250);
    const isBenchmarkAvailable = probe.status === 'AVAILABLE';

    for (const [, holeShots] of holeShotsMap.entries()) {
      const hole = holeShots[0]?.hole;
      const holePar = hole ? hole.par : 4;

      for (let i = 0; i < holeShots.length; i++) {
        const shot = holeShots[i];
        const shotIndex = i + 1; // 1-based index on hole

        const category = StrokesGainedClassifier.classifyShot({
          holePar,
          shotIndexOnHole: shotIndex,
          clubType: shot.club ? shot.club.club_type : null,
          startDistanceToGreenMeters: shot.distance || null,
        });

        categoryCounts[category]++;

        if (isBenchmarkAvailable) {
          const startDist = shot.distance || 150;
          const endDist = Math.max(0, startDist - (shot.distance || 0));

          const startExpected = await this.benchmarkProvider.getExpectedStrokes(category, startDist);
          const endExpected =
            i === holeShots.length - 1
              ? { status: 'AVAILABLE', expectedStrokes: 0 }
              : await this.benchmarkProvider.getExpectedStrokes(category, endDist);

          if (
            startExpected.status === 'AVAILABLE' &&
            startExpected.expectedStrokes !== null &&
            endExpected.status === 'AVAILABLE' &&
            endExpected.expectedStrokes !== null
          ) {
            const sg = startExpected.expectedStrokes - endExpected.expectedStrokes - 1;
            categoryGained[category] += sg;
            totalGained += sg;
            anyAvailable = true;
          }
        }
      }
    }

    const benchmarkStatus: BenchmarkStatus = isBenchmarkAvailable && anyAvailable ? 'AVAILABLE' : 'UNAVAILABLE';

    const buildCategorySummary = (cat: ShotCategory): StrokesGainedCategorySummary => ({
      category: cat,
      shotsCount: categoryCounts[cat],
      strokesGained: benchmarkStatus === 'AVAILABLE' ? Number(categoryGained[cat].toFixed(2)) : null,
      status: benchmarkStatus,
    });

    return {
      status: benchmarkStatus,
      totalStrokesGained: benchmarkStatus === 'AVAILABLE' ? Number(totalGained.toFixed(2)) : null,
      categories: {
        [ShotCategory.DRIVING]: buildCategorySummary(ShotCategory.DRIVING),
        [ShotCategory.APPROACH]: buildCategorySummary(ShotCategory.APPROACH),
        [ShotCategory.SHORT_GAME]: buildCategorySummary(ShotCategory.SHORT_GAME),
        [ShotCategory.PUTTING]: buildCategorySummary(ShotCategory.PUTTING),
        [ShotCategory.UNKNOWN]: buildCategorySummary(ShotCategory.UNKNOWN),
      },
      message:
        benchmarkStatus === 'AVAILABLE'
          ? 'Strokes Gained calculated successfully.'
          : 'Strokes Gained data unavailable: benchmark tables (Mark Broadie / PGA Tour) are not supplied in specification.',
    };
  }
}
