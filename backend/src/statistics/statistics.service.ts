import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Round, RoundStatus } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { RoundScore } from '../rounds/entities/round-score.entity';
import { ScoreDifferential } from '../handicap/entities/score-differential.entity';
import { User } from '../users/entities/user.entity';
import {
  StatisticsEngine,
  ScoreItem,
  FirResult,
  GirResult,
  PuttsResult,
  ScramblingResult,
  ScoreDistribution,
  ParBreakdown,
} from './statistics.engine';

export interface StatsOverviewResult {
  roundsPlayed: number;
  totalHolesPlayed: number;
  scoringAverage: number | null;
  bestScore: number | null;
  fir: FirResult;
  gir: GirResult;
  putts: PuttsResult;
  scrambling: ScramblingResult;
  parBreakdown: ParBreakdown;
  scoreDistribution: ScoreDistribution;
}

export interface TrendPoint {
  roundId: string;
  roundDate: Date;
  courseName: string;
  grossScore: number;
  scoreDifferential: number | null;
  firPercentage: number | null;
  girPercentage: number | null;
  totalPutts: number | null;
}

@Injectable()
export class StatisticsService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Round)
    private readonly roundRepo: Repository<Round>,
    @InjectRepository(RoundPlayer)
    private readonly playerRepo: Repository<RoundPlayer>,
    @InjectRepository(RoundScore)
    private readonly scoreRepo: Repository<RoundScore>,
    @InjectRepository(ScoreDifferential)
    private readonly diffRepo: Repository<ScoreDifferential>,
  ) {}

  /**
   * Helper to fetch completed rounds and player references for a given user.
   */
  private async getUserCompletedRounds(
    userId: string,
    roundsLimit?: number,
  ): Promise<{ round: Round; player: RoundPlayer }[]> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    const players = await this.playerRepo.find({
      where: { userId },
      relations: ['round', 'round.course'],
      order: { createdAt: 'DESC' },
    });

    const completed = players
      .filter((p) => p.round && p.round.status === RoundStatus.COMPLETED)
      .map((p) => ({ round: p.round, player: p }));

    if (roundsLimit && roundsLimit > 0) {
      return completed.slice(0, roundsLimit);
    }
    return completed;
  }

  /**
   * Helper to retrieve all ScoreItems for specified player round participations.
   */
  private async getScoreItemsForPlayers(playerIds: string[]): Promise<ScoreItem[]> {
    if (playerIds.length === 0) return [];

    const scores = await this.scoreRepo.find({
      where: { playerId: In(playerIds) },
      relations: ['hole'],
      order: { createdAt: 'ASC' },
    });

    return scores.map((s) => ({
      holeNumber: s.hole ? s.hole.hole_number : 0,
      par: s.hole ? s.hole.par : 4,
      grossScore: s.grossScore,
      putts: s.putts,
      penalties: s.penalties,
      fairwayHit: s.fairwayHit,
      gir: s.gir,
    }));
  }

  /**
   * Comprehensive Statistics Overview.
   */
  async getOverview(userId: string, roundsLimit?: number): Promise<StatsOverviewResult> {
    const userRounds = await this.getUserCompletedRounds(userId, roundsLimit);
    const playerIds = userRounds.map((ur) => ur.player.id);
    const scoreItems = await this.getScoreItemsForPlayers(playerIds);

    const roundsPlayed = userRounds.length;
    const totalHolesPlayed = scoreItems.length;

    // Calculate round gross totals for scoring average & best score
    const roundTotals: number[] = [];
    for (const ur of userRounds) {
      const roundScores = await this.scoreRepo.find({
        where: { playerId: ur.player.id },
      });
      if (roundScores.length > 0) {
        const sumGross = roundScores.reduce((acc, s) => acc + s.grossScore, 0);
        roundTotals.push(sumGross);
      }
    }

    const scoringAverage =
      roundTotals.length > 0
        ? Number(
            (roundTotals.reduce((acc, val) => acc + val, 0) / roundTotals.length).toFixed(1),
          )
        : null;

    const bestScore = roundTotals.length > 0 ? Math.min(...roundTotals) : null;

    const fir = StatisticsEngine.calculateFIR(scoreItems);
    const gir = StatisticsEngine.calculateGIR(scoreItems);
    const putts = StatisticsEngine.calculatePutts(scoreItems);
    const scrambling = StatisticsEngine.calculateScrambling(scoreItems);
    const parBreakdown = StatisticsEngine.calculateParBreakdown(scoreItems);
    const scoreDistribution = StatisticsEngine.calculateScoreDistribution(scoreItems);

    return {
      roundsPlayed,
      totalHolesPlayed,
      scoringAverage,
      bestScore,
      fir,
      gir,
      putts,
      scrambling,
      parBreakdown,
      scoreDistribution,
    };
  }

  /**
   * Performance Trends across rounds (chronological sequence).
   */
  async getTrends(userId: string, roundsLimit?: number): Promise<TrendPoint[]> {
    const userRounds = await this.getUserCompletedRounds(userId, roundsLimit);
    // Sort oldest to newest for chronological trend charting
    const sorted = [...userRounds].reverse();

    const diffs = await this.diffRepo.find({
      where: { user_id: userId },
    });
    const diffMap = new Map<string, number>();
    for (const d of diffs) {
      diffMap.set(d.round_id, Number(d.score_differential));
    }

    const trends: TrendPoint[] = [];

    for (const ur of sorted) {
      const scores = await this.scoreRepo.find({
        where: { playerId: ur.player.id },
        relations: ['hole'],
      });

      const scoreItems: ScoreItem[] = scores.map((s) => ({
        holeNumber: s.hole ? s.hole.hole_number : 0,
        par: s.hole ? s.hole.par : 4,
        grossScore: s.grossScore,
        putts: s.putts,
        penalties: s.penalties,
        fairwayHit: s.fairwayHit,
        gir: s.gir,
      }));

      const grossScore = scoreItems.reduce((acc, s) => acc + s.grossScore, 0);
      const fir = StatisticsEngine.calculateFIR(scoreItems);
      const gir = StatisticsEngine.calculateGIR(scoreItems);
      const putts = StatisticsEngine.calculatePutts(scoreItems);

      trends.push({
        roundId: ur.round.id,
        roundDate: ur.round.createdAt,
        courseName: ur.round.course ? ur.round.course.name : 'Unknown Course',
        grossScore,
        scoreDifferential: diffMap.get(ur.round.id) ?? null,
        firPercentage: fir.percentage,
        girPercentage: gir.percentage,
        totalPutts: putts.totalPutts > 0 ? putts.totalPutts : null,
      });
    }

    return trends;
  }

  /**
   * FIR & GIR specific statistics.
   */
  async getFirGir(userId: string, roundsLimit?: number) {
    const userRounds = await this.getUserCompletedRounds(userId, roundsLimit);
    const playerIds = userRounds.map((ur) => ur.player.id);
    const scoreItems = await this.getScoreItemsForPlayers(playerIds);

    const fir = StatisticsEngine.calculateFIR(scoreItems);
    const gir = StatisticsEngine.calculateGIR(scoreItems);

    return {
      fir,
      gir,
      roundsSampled: userRounds.length,
    };
  }

  /**
   * Putting specific statistics.
   */
  async getPutting(userId: string, roundsLimit?: number) {
    const userRounds = await this.getUserCompletedRounds(userId, roundsLimit);
    const playerIds = userRounds.map((ur) => ur.player.id);
    const scoreItems = await this.getScoreItemsForPlayers(playerIds);

    const putts = StatisticsEngine.calculatePutts(scoreItems);

    return {
      putts,
      roundsSampled: userRounds.length,
    };
  }

  /**
   * Scrambling specific statistics.
   */
  async getScrambling(userId: string, roundsLimit?: number) {
    const userRounds = await this.getUserCompletedRounds(userId, roundsLimit);
    const playerIds = userRounds.map((ur) => ur.player.id);
    const scoreItems = await this.getScoreItemsForPlayers(playerIds);

    const scrambling = StatisticsEngine.calculateScrambling(scoreItems);

    return {
      scrambling,
      roundsSampled: userRounds.length,
    };
  }
}
