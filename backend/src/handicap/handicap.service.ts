import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HandicapHistory } from './entities/handicap-history.entity';
import { ScoreDifferential } from './entities/score-differential.entity';
import { User } from '../users/entities/user.entity';
import { Round, RoundStatus } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { RoundScore } from '../rounds/entities/round-score.entity';
import { CourseTee } from '../courses/entities/course-tee.entity';
import { WhsEngine, HoleScoreInput, HandicapCalculationResult } from './whs/whs.engine';
import { PccProvider, NullPccProvider } from './pcc/pcc.provider';

@Injectable()
export class HandicapService {
  private readonly pccProvider: PccProvider;

  constructor(
    @InjectRepository(HandicapHistory)
    private readonly historyRepo: Repository<HandicapHistory>,
    @InjectRepository(ScoreDifferential)
    private readonly diffRepo: Repository<ScoreDifferential>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Round)
    private readonly roundRepo: Repository<Round>,
    @InjectRepository(RoundPlayer)
    private readonly playerRepo: Repository<RoundPlayer>,
    @InjectRepository(RoundScore)
    private readonly scoreRepo: Repository<RoundScore>,
    @InjectRepository(CourseTee)
    private readonly teeRepo: Repository<CourseTee>,
  ) {
    this.pccProvider = new NullPccProvider();
  }

  /**
   * Retrieves the current WHS Handicap Index for user
   */
  async getCurrentHandicap(userId: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User not found: ${userId}`);
    }

    const latestHistory = await this.historyRepo.findOne({
      where: { user_id: userId },
      order: { calculated_at: 'DESC' },
    });

    const diffCount = await this.diffRepo.count({
      where: { user_id: userId },
    });

    const isEstablished = diffCount >= 3;

    return {
      userId,
      handicapIndex: isEstablished && latestHistory ? Number(latestHistory.resulting_handicap_index) : (user.handicap_index ? Number(user.handicap_index) : 54.0),
      isEstablished,
      roundsCount: diffCount,
      lastCalculatedAt: latestHistory ? latestHistory.calculated_at : null,
      status: latestHistory ? latestHistory.status : (isEstablished ? 'VALID' : 'INSUFFICIENT_ROUNDS'),
      message: isEstablished
        ? `Official WHS Handicap Index based on ${diffCount} eligible rounds.`
        : `Needs at least 3 completed 18-hole rounds to establish an official WHS Handicap Index (currently ${diffCount}/3 rounds).`,
    };
  }

  /**
   * Retrieves full chronological history of handicap recalculations
   */
  async getHandicapHistory(userId: string): Promise<HandicapHistory[]> {
    return this.historyRepo.find({
      where: { user_id: userId },
      order: { calculated_at: 'DESC' },
    });
  }

  /**
   * Retrieves recorded score differentials for user
   */
  async getScoreDifferentials(userId: string): Promise<ScoreDifferential[]> {
    return this.diffRepo.find({
      where: { user_id: userId },
      relations: ['course', 'courseTee'],
      order: { played_at: 'DESC' },
    });
  }

  /**
   * Evaluates all completed rounds for the user, computes missing score differentials,
   * recalculates the WHS Handicap Index, and logs a history record.
   */
  async recalculateHandicap(userId: string): Promise<{
    handicapResult: HandicapCalculationResult;
    pccStatus: string;
    newDifferentialsCount: number;
  }> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User not found: ${userId}`);
    }

    // 1. Find all completed rounds where user participated
    const playerEntries = await this.playerRepo.find({
      where: { userId },
      relations: ['round', 'round.course', 'tee'],
    });

    let newDiffsCount = 0;

    for (const player of playerEntries) {
      const round = player.round;
      if (!round || round.status !== RoundStatus.COMPLETED) {
        continue;
      }

      // Check if differential already exists for this round and user
      const existingDiff = await this.diffRepo.findOne({
        where: { round_id: round.id, user_id: userId },
      });

      if (!existingDiff) {
        // Fetch all 18 hole scores for this player
        const scores = await this.scoreRepo.find({
          where: { roundId: round.id, playerId: player.id },
          relations: ['hole'],
        });

        // WHS requires complete round of 18 holes
        if (scores.length >= 18) {
          // Identify course tee for rating and slope
          let tee = player.tee;
          if (!tee && player.teeId) {
            tee = await this.teeRepo.findOne({ where: { id: player.teeId } });
          }
          if (!tee) {
            // Fall back to first tee of the course
            tee = await this.teeRepo.findOne({
              where: { course_id: round.courseId },
              order: { created_at: 'ASC' },
            });
          }

          if (tee && Number(tee.slope_rating) > 0 && Number(tee.rating) > 0) {
            const holeInputs: HoleScoreInput[] = scores.map((s) => ({
              holeNumber: s.hole.hole_number,
              par: s.hole.par,
              handicapIndex: s.hole.handicap_index,
              grossScore: s.grossScore,
            }));

            const ags = WhsEngine.calculateAdjustedGrossScore(
              holeInputs,
              Number(user.handicap_index) || 0,
            );

            const roundDate = round.finishedAt || round.startedAt || new Date();
            const pccResult = await this.pccProvider.getPcc(roundDate, round.courseId);

            const scoreDiff = WhsEngine.calculateScoreDifferential(
              ags,
              Number(tee.rating),
              Number(tee.slope_rating),
              pccResult.value,
            );

            const totalGross = scores.reduce((sum, s) => sum + s.grossScore, 0);

            const diffRecord = this.diffRepo.create({
              user_id: userId,
              round_id: round.id,
              course_id: round.courseId,
              course_tee_id: tee.id,
              gross_score: totalGross,
              adjusted_gross_score: ags,
              course_rating: Number(tee.rating),
              slope_rating: Number(tee.slope_rating),
              pcc: pccResult.value,
              pcc_status: pccResult.status,
              score_differential: scoreDiff,
              played_at: roundDate,
            });

            await this.diffRepo.save(diffRecord);
            newDiffsCount++;
          }
        }
      }
    }

    // 2. Load all available score differentials ordered by played_at DESC
    const allDiffs = await this.diffRepo.find({
      where: { user_id: userId },
      order: { played_at: 'DESC' },
    });

    const diffValues = allDiffs.map((d) => Number(d.score_differential));

    // 3. Compute WHS Handicap Index
    const result = WhsEngine.calculateHandicapIndex(diffValues);

    // Update is_used_in_handicap flags on recent differentials
    const recent20 = allDiffs.slice(0, 20);
    const usedSet = new Set(result.differentialsUsed);

    for (const d of recent20) {
      const isUsed = usedSet.has(Number(d.score_differential));
      if (d.is_used_in_handicap !== isUsed) {
        d.is_used_in_handicap = isUsed;
        await this.diffRepo.save(d);
      }
    }

    // 4. Save history record and update user
    if (result.isEstablished && result.handicapIndex !== null) {
      const latestDiff = allDiffs[0];
      const historyEntry = this.historyRepo.create({
        user_id: userId,
        round_id: latestDiff ? latestDiff.round_id : null,
        score_differential: latestDiff ? latestDiff.score_differential : 0.0,
        resulting_handicap_index: result.handicapIndex,
        rounds_count: result.roundsCount,
        differentials_used_count: result.differentialsUsed.length,
        differentials_used_json: JSON.stringify(result.differentialsUsed),
        status: 'VALID',
        calculated_at: new Date(),
      });

      await this.historyRepo.save(historyEntry);

      user.handicap_index = result.handicapIndex;
      await this.userRepo.save(user);
    } else {
      // Record insufficient rounds snapshot
      const historyEntry = this.historyRepo.create({
        user_id: userId,
        round_id: allDiffs[0]?.round_id || null,
        score_differential: allDiffs[0]?.score_differential || 0.0,
        resulting_handicap_index: user.handicap_index || 54.0,
        rounds_count: result.roundsCount,
        differentials_used_count: 0,
        differentials_used_json: JSON.stringify([]),
        status: 'INSUFFICIENT_ROUNDS',
        calculated_at: new Date(),
      });

      await this.historyRepo.save(historyEntry);
    }

    return {
      handicapResult: result,
      pccStatus: 'UNAVAILABLE (0.0 standard adjustment applied)',
      newDifferentialsCount: newDiffsCount,
    };
  }
}
