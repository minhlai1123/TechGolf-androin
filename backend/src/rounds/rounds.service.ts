import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Round, RoundStatus } from './entities/round.entity';
import { RoundPlayer } from './entities/round-player.entity';
import { RoundScore } from './entities/round-score.entity';
import { Course } from '../courses/entities/course.entity';
import { Hole } from '../courses/entities/hole.entity';
import { CreateRoundDto } from './dto/create-round.dto';
import { SaveScoreDto } from './dto/save-score.dto';
import { GameModeEngine, GameModeResult } from './game-mode.engine';

@Injectable()
export class RoundsService {
  constructor(
    @InjectRepository(Round)
    private readonly roundRepo: Repository<Round>,
    @InjectRepository(RoundPlayer)
    private readonly playerRepo: Repository<RoundPlayer>,
    @InjectRepository(RoundScore)
    private readonly scoreRepo: Repository<RoundScore>,
    @InjectRepository(Course)
    private readonly courseRepo: Repository<Course>,
    @InjectRepository(Hole)
    private readonly holeRepo: Repository<Hole>,
  ) {}

  /**
   * Creates a new round with 1 to 4 players
   */
  async createRound(userId: string, dto: CreateRoundDto): Promise<Round> {
    const course = await this.courseRepo.findOne({ where: { id: dto.courseId } });
    if (!course) {
      throw new NotFoundException(`Course not found with id: ${dto.courseId}`);
    }

    if (!dto.players || dto.players.length === 0) {
      throw new BadRequestException('Round must have at least 1 player');
    }
    if (dto.players.length > 4) {
      throw new BadRequestException('Round cannot exceed 4 players');
    }

    // Validate unique player orders
    const orders = new Set<number>();
    const userIds = new Set<string>();
    for (const p of dto.players) {
      if (orders.has(p.playerOrder)) {
        throw new BadRequestException(`Duplicate player order: ${p.playerOrder}`);
      }
      orders.add(p.playerOrder);

      if (p.userId) {
        if (userIds.has(p.userId)) {
          throw new BadRequestException(`Duplicate user in round: ${p.userId}`);
        }
        userIds.add(p.userId);
      }
    }

    const round = this.roundRepo.create({
      courseId: dto.courseId,
      gameMode: dto.gameMode,
      status: RoundStatus.NOT_STARTED,
      currentHole: 1,
      createdBy: userId,
    });

    const savedRound = await this.roundRepo.save(round);

    const playersToSave = dto.players.map((p) =>
      this.playerRepo.create({
        roundId: savedRound.id,
        userId: p.userId || null,
        playerName: p.playerName,
        playerOrder: p.playerOrder,
        teamId: p.teamId || null,
        teeId: p.teeId || null,
      }),
    );

    await this.playerRepo.save(playersToSave);

    return this.getRound(savedRound.id, userId);
  }

  /**
   * Retrieves a round with players and course info
   */
  async getRound(roundId: string, userId: string): Promise<Round> {
    const round = await this.roundRepo.findOne({
      where: { id: roundId },
      relations: ['course', 'players', 'players.user'],
      order: { players: { playerOrder: 'ASC' } },
    });

    if (!round) {
      throw new NotFoundException(`Round not found: ${roundId}`);
    }

    this._checkRoundAccess(round, userId);
    return round;
  }

  /**
   * Starts a round (transitions from NOT_STARTED to IN_PROGRESS)
   */
  async startRound(roundId: string, userId: string): Promise<Round> {
    const round = await this.getRound(roundId, userId);

    if (round.status !== RoundStatus.NOT_STARTED) {
      throw new BadRequestException(`Round is already in status: ${round.status}`);
    }

    round.status = RoundStatus.IN_PROGRESS;
    round.startedAt = new Date();
    return this.roundRepo.save(round);
  }

  /**
   * Updates the current hole number of a round
   */
  async updateCurrentHole(
    roundId: string,
    userId: string,
    currentHole: number,
  ): Promise<Round> {
    const round = await this.getRound(roundId, userId);

    if (round.status !== RoundStatus.IN_PROGRESS) {
      throw new BadRequestException('Round is not currently in progress');
    }

    round.currentHole = currentHole;
    return this.roundRepo.save(round);
  }

  /**
   * Finishes a round (transitions to COMPLETED)
   */
  async finishRound(roundId: string, userId: string): Promise<Round> {
    const round = await this.getRound(roundId, userId);

    if (round.status === RoundStatus.COMPLETED) {
      return round;
    }

    round.status = RoundStatus.COMPLETED;
    round.finishedAt = new Date();
    return this.roundRepo.save(round);
  }

  /**
   * Saves or updates a score for a specific player on a specific hole
   */
  async saveScore(roundId: string, userId: string, dto: SaveScoreDto): Promise<RoundScore> {
    const round = await this.getRound(roundId, userId);

    if (round.status === RoundStatus.COMPLETED || round.status === RoundStatus.CANCELLED) {
      throw new BadRequestException('Cannot enter scores for a completed or cancelled round');
    }

    // Verify player is part of this round
    const player = round.players.find((p) => p.id === dto.playerId);
    if (!player) {
      throw new BadRequestException(`Player ${dto.playerId} does not belong to this round`);
    }

    // Verify hole belongs to course
    const hole = await this.holeRepo.findOne({
      where: { id: dto.holeId, course_id: round.courseId },
    });
    if (!hole) {
      throw new BadRequestException(
        `Hole ${dto.holeId} does not belong to course ${round.courseId}`,
      );
    }

    // Validate score logic
    const putts = dto.putts ?? 0;
    const penalties = dto.penalties ?? 0;

    if (putts > dto.grossScore) {
      throw new BadRequestException('Putts cannot be greater than gross score');
    }

    // Find existing score or create new
    let score = await this.scoreRepo.findOne({
      where: {
        roundId,
        playerId: dto.playerId,
        holeId: dto.holeId,
      },
    });

    if (score) {
      score.grossScore = dto.grossScore;
      score.putts = putts;
      score.penalties = penalties;
      score.fairwayHit = dto.fairwayHit ?? null;
      score.gir = dto.gir ?? null;
    } else {
      score = this.scoreRepo.create({
        roundId,
        playerId: dto.playerId,
        holeId: dto.holeId,
        grossScore: dto.grossScore,
        putts,
        penalties,
        fairwayHit: dto.fairwayHit ?? null,
        gir: dto.gir ?? null,
      });
    }

    return this.scoreRepo.save(score);
  }

  /**
   * Updates an existing score record by scoreId
   */
  async updateScore(
    roundId: string,
    scoreId: string,
    userId: string,
    dto: Partial<SaveScoreDto>,
  ): Promise<RoundScore> {
    const round = await this.getRound(roundId, userId);

    if (round.status === RoundStatus.COMPLETED || round.status === RoundStatus.CANCELLED) {
      throw new BadRequestException('Cannot update scores for a completed or cancelled round');
    }

    const score = await this.scoreRepo.findOne({
      where: { id: scoreId, roundId },
    });
    if (!score) {
      throw new NotFoundException(`Score not found: ${scoreId}`);
    }

    const gross = dto.grossScore ?? score.grossScore;
    const putts = dto.putts ?? score.putts;

    if (putts > gross) {
      throw new BadRequestException('Putts cannot be greater than gross score');
    }

    if (dto.grossScore !== undefined) score.grossScore = dto.grossScore;
    if (dto.putts !== undefined) score.putts = dto.putts;
    if (dto.penalties !== undefined) score.penalties = dto.penalties;
    if (dto.fairwayHit !== undefined) score.fairwayHit = dto.fairwayHit;
    if (dto.gir !== undefined) score.gir = dto.gir;

    return this.scoreRepo.save(score);
  }

  /**
   * Retrieves structured scorecard matrix for rendering in Mobile
   */
  async getScorecard(roundId: string, userId: string) {
    const round = await this.getRound(roundId, userId);

    const holes = await this.holeRepo.find({
      where: { course_id: round.courseId },
      order: { hole_number: 'ASC' },
    });

    const scores = await this.scoreRepo.find({
      where: { roundId },
    });

    const holeMap = new Map<string, Hole>();
    for (const h of holes) {
      holeMap.set(h.id, h);
    }

    const totals = round.players.map((p) => {
      const pScores = scores.filter((s) => s.playerId === p.id);
      let gross = 0;
      let putts = 0;
      let penalties = 0;
      let firCount = 0;
      let firPossible = 0;
      let girCount = 0;
      let girPossible = 0;

      for (const s of pScores) {
        gross += s.grossScore;
        putts += s.putts;
        penalties += s.penalties;

        const hole = holeMap.get(s.holeId);
        if (hole && hole.par > 3) {
          firPossible++;
          if (s.fairwayHit === 'STRAIGHT') {
            firCount++;
          }
        }

        if (s.gir !== null && s.gir !== undefined) {
          girPossible++;
          if (s.gir) {
            girCount++;
          }
        }
      }

      return {
        playerId: p.id,
        playerName: p.playerName,
        playerOrder: p.playerOrder,
        teamId: p.teamId,
        grossScore: gross,
        putts,
        penalties,
        firCount,
        firPossible,
        girCount,
        girPossible,
        holesCompleted: pScores.length,
      };
    });

    return {
      round: {
        id: round.id,
        courseId: round.courseId,
        gameMode: round.gameMode,
        status: round.status,
        currentHole: round.currentHole,
        startedAt: round.startedAt,
        finishedAt: round.finishedAt,
      },
      course: round.course,
      holes: holes.map((h) => ({
        id: h.id,
        holeNumber: h.hole_number,
        par: h.par,
        handicapIndex: h.handicap_index,
      })),
      players: round.players.map((p) => ({
        id: p.id,
        userId: p.userId,
        playerName: p.playerName,
        playerOrder: p.playerOrder,
        teamId: p.teamId,
      })),
      scores: scores.map((s) => ({
        id: s.id,
        playerId: s.playerId,
        holeId: s.holeId,
        grossScore: s.grossScore,
        putts: s.putts,
        penalties: s.penalties,
        fairwayHit: s.fairwayHit,
        gir: s.gir,
      })),
      totals,
    };
  }

  /**
   * Retrieves game mode specific result
   */
  async getRoundResult(roundId: string, userId: string): Promise<GameModeResult> {
    const round = await this.getRound(roundId, userId);

    const holes = await this.holeRepo.find({
      where: { course_id: round.courseId },
      order: { hole_number: 'ASC' },
    });

    const scores = await this.scoreRepo.find({
      where: { roundId },
    });

    return GameModeEngine.calculateResult(
      round.gameMode,
      round.players,
      holes,
      scores,
      round.status === RoundStatus.COMPLETED,
    );
  }

  private _checkRoundAccess(round: Round, userId: string): void {
    if (round.createdBy === userId) {
      return;
    }
    const isPlayer = round.players?.some((p) => p.userId === userId);
    if (!isPlayer) {
      throw new ForbiddenException('You do not have access to this round');
    }
  }
}
