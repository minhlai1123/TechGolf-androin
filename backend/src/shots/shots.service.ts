import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Shot, ShotStatus, DistanceUnit } from './entities/shot.entity';
import { Round } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { Hole } from '../courses/entities/hole.entity';
import { GolfBagClub } from '../golf-bag/entities/golf-bag-club.entity';
import { StartShotDto } from './dto/start-shot.dto';
import { SaveShotDto } from './dto/save-shot.dto';
import { RecommendClubDto } from './dto/recommend-club.dto';
import { PlaysLikeEngine } from './plays-like.engine';
import { ClubRecommendationEngine } from './club-recommendation.engine';

@Injectable()
export class ShotsService {
  constructor(
    @InjectRepository(Shot)
    private readonly shotRepo: Repository<Shot>,
    @InjectRepository(Round)
    private readonly roundRepo: Repository<Round>,
    @InjectRepository(RoundPlayer)
    private readonly playerRepo: Repository<RoundPlayer>,
    @InjectRepository(Hole)
    private readonly holeRepo: Repository<Hole>,
    @InjectRepository(GolfBagClub)
    private readonly clubRepo: Repository<GolfBagClub>,
  ) {}

  /**
   * Start a shot at ball's initial GPS position
   */
  async startShot(
    userId: string,
    roundId: string,
    dto: StartShotDto,
  ): Promise<Shot> {
    const round = await this.roundRepo.findOne({
      where: { id: roundId },
      relations: ['players'],
    });

    if (!round) {
      throw new NotFoundException(`Round not found: ${roundId}`);
    }

    const player = round.players.find((p) => p.id === dto.playerId);
    if (!player) {
      throw new BadRequestException(`Player ${dto.playerId} does not belong to this round`);
    }

    // Authorize: creator of round or player itself
    if (round.createdBy !== userId && player.userId !== userId) {
      throw new ForbiddenException('Not authorized to track shots for this player');
    }

    // Hole must belong to round's course
    const hole = await this.holeRepo.findOne({
      where: { id: dto.holeId, course_id: round.courseId },
    });
    if (!hole) {
      throw new BadRequestException('Hole does not belong to this round course');
    }

    // If clubId provided, verify it belongs to user
    if (dto.clubId) {
      const club = await this.clubRepo.findOne({
        where: { id: dto.clubId, user_id: userId },
      });
      if (!club) {
        throw new NotFoundException('Specified club not found in your golf bag');
      }
    }

    const shot = this.shotRepo.create({
      roundId,
      playerId: dto.playerId,
      userId: player.userId || userId,
      holeId: dto.holeId,
      clubId: dto.clubId || null,
      status: ShotStatus.STARTED,
      startLatitude: dto.latitude,
      startLongitude: dto.longitude,
      startElevation: dto.elevation ?? null,
      distanceUnit: dto.unit || DistanceUnit.YARDS,
    });

    return this.shotRepo.save(shot);
  }

  /**
   * Save a shot after golfer reaches the ball with end coordinates and club
   */
  async saveShot(
    userId: string,
    roundId: string,
    shotId: string,
    dto: SaveShotDto,
  ): Promise<Shot> {
    const shot = await this.shotRepo.findOne({
      where: { id: shotId, roundId },
      relations: ['round', 'player'],
    });

    if (!shot) {
      throw new NotFoundException(`Shot not found: ${shotId}`);
    }

    // Authorize: creator of round, owner of shot, or player user
    if (
      shot.round.createdBy !== userId &&
      shot.userId !== userId &&
      shot.player.userId !== userId
    ) {
      throw new ForbiddenException('Not authorized to save this shot');
    }

    if (shot.status !== ShotStatus.STARTED) {
      throw new BadRequestException(
        `Cannot save shot with status ${shot.status}. Must be STARTED.`,
      );
    }

    // Verify club exists and belongs to user
    const club = await this.clubRepo.findOne({
      where: { id: dto.clubId, user_id: userId },
    });
    if (!club) {
      throw new NotFoundException('Selected club not found in your golf bag');
    }

    const unit = dto.unit || shot.distanceUnit || DistanceUnit.YARDS;

    // Calculate actual geodesic distance Start -> End using Haversine
    const distanceVal =
      unit === DistanceUnit.YARDS
        ? PlaysLikeEngine.distanceBetweenYards(
            shot.startLatitude,
            shot.startLongitude,
            dto.latitude,
            dto.longitude,
          )
        : PlaysLikeEngine.distanceBetweenMeters(
            shot.startLatitude,
            shot.startLongitude,
            dto.latitude,
            dto.longitude,
          );

    let elevationDelta: number | null = null;
    if (
      shot.startElevation !== null &&
      shot.startElevation !== undefined &&
      dto.elevation !== null &&
      dto.elevation !== undefined
    ) {
      elevationDelta = dto.elevation - shot.startElevation;
    }

    shot.endLatitude = dto.latitude;
    shot.endLongitude = dto.longitude;
    shot.endElevation = dto.elevation ?? null;
    shot.elevationDelta = elevationDelta;
    shot.distance = Number(distanceVal.toFixed(1));
    shot.distanceUnit = unit;
    shot.clubId = club.id;
    shot.status = ShotStatus.SAVED;

    const saved = await this.shotRepo.save(shot);

    // Recalculate average distance and shot count for this club
    await this.recalculateClubAverage(club.id);

    return saved;
  }

  /**
   * Recalculates average distance for a club based on all saved shots
   */
  async recalculateClubAverage(clubId: string): Promise<void> {
    const savedShots = await this.shotRepo.find({
      where: { clubId, status: ShotStatus.SAVED },
    });

    if (savedShots.length === 0) {
      await this.clubRepo.update(clubId, {
        average_distance_meters: 0.0,
        total_shots_recorded: 0,
      });
      return;
    }

    const distancesInMeters = savedShots.map((s) => {
      const rawDist = Number(s.distance) || 0;
      return s.distanceUnit === DistanceUnit.YARDS
        ? rawDist * PlaysLikeEngine.YARDS_TO_METERS
        : rawDist;
    });

    const sumMeters = distancesInMeters.reduce((acc, val) => acc + val, 0);
    const avgMeters = Number((sumMeters / distancesInMeters.length).toFixed(1));

    await this.clubRepo.update(clubId, {
      average_distance_meters: avgMeters,
      total_shots_recorded: distancesInMeters.length,
    });
  }

  /**
   * List all shots in a round
   */
  async getShotsByRound(roundId: string, userId: string): Promise<Shot[]> {
    const round = await this.roundRepo.findOne({
      where: { id: roundId },
      relations: ['players'],
    });

    if (!round) {
      throw new NotFoundException(`Round not found: ${roundId}`);
    }

    const isMember =
      round.createdBy === userId ||
      round.players.some((p) => p.userId === userId);

    if (!isMember) {
      throw new ForbiddenException('Not authorized to view shots for this round');
    }

    return this.shotRepo.find({
      where: { roundId },
      relations: ['player', 'club', 'hole'],
      order: { createdAt: 'ASC' },
    });
  }

  /**
   * List shots for a specific hole in a round
   */
  async getShotsByHole(
    roundId: string,
    holeId: string,
    userId: string,
  ): Promise<Shot[]> {
    const round = await this.roundRepo.findOne({
      where: { id: roundId },
      relations: ['players'],
    });

    if (!round) {
      throw new NotFoundException(`Round not found: ${roundId}`);
    }

    const isMember =
      round.createdBy === userId ||
      round.players.some((p) => p.userId === userId);

    if (!isMember) {
      throw new ForbiddenException('Not authorized to view shots for this round');
    }

    return this.shotRepo.find({
      where: { roundId, holeId },
      relations: ['player', 'club'],
      order: { createdAt: 'ASC' },
    });
  }

  /**
   * Get user's clubs with calculated distances in Yards and Meters
   */
  async getClubDistances(userId: string): Promise<any[]> {
    const clubs = await this.clubRepo.find({
      where: { user_id: userId },
      order: { created_at: 'ASC' },
    });

    return clubs.map((c) => {
      const avgMeters = Number(c.average_distance_meters) || 0.0;
      const avgYards = Number(
        (avgMeters * PlaysLikeEngine.METERS_TO_YARDS).toFixed(1),
      );
      return {
        id: c.id,
        clubType: c.club_type,
        customName: c.custom_name,
        averageDistanceMeters: avgMeters,
        averageDistanceYards: avgYards,
        totalShotsRecorded: c.total_shots_recorded,
        isActive: c.is_active,
      };
    });
  }

  /**
   * Get historical saved shots for a specific club
   */
  async getClubShotHistory(userId: string, clubId: string): Promise<Shot[]> {
    const club = await this.clubRepo.findOne({
      where: { id: clubId, user_id: userId },
    });

    if (!club) {
      throw new NotFoundException('Club not found or does not belong to user');
    }

    return this.shotRepo.find({
      where: { clubId, status: ShotStatus.SAVED },
      relations: ['hole', 'round'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Recommend club and compute Plays Like Distance
   */
  async recommendClub(userId: string, dto: RecommendClubDto): Promise<any> {
    const unit = dto.unit || DistanceUnit.YARDS;

    // 1. Calculate Plays Like Distance if elevations provided
    const playsLike = PlaysLikeEngine.calculate(
      dto.remainingDistance,
      dto.startElevation,
      dto.targetElevation,
      unit,
    );

    // 2. Load active clubs for user
    const clubs = await this.clubRepo.find({
      where: { user_id: userId, is_active: true },
    });

    const clubInfos = clubs.map((c) => ({
      id: c.id,
      clubType: c.club_type,
      customName: c.custom_name,
      averageDistanceMeters: Number(c.average_distance_meters) || 0,
      totalShotsRecorded: c.total_shots_recorded,
      isActive: c.is_active,
    }));

    // Use Plays Like distance for recommendation if elevation available, else actual
    const targetDistance = playsLike.hasElevation
      ? playsLike.playsLikeDistance
      : dto.remainingDistance;

    const recommendation = ClubRecommendationEngine.recommend(
      targetDistance,
      unit,
      clubInfos,
    );

    return {
      playsLike,
      recommendation,
    };
  }
}
