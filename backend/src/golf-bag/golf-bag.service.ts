import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GolfBagClub } from './entities/golf-bag-club.entity';
import { CreateClubDto } from './dto/create-club.dto';
import { UpdateClubDto } from './dto/update-club.dto';

@Injectable()
export class GolfBagService {
  constructor(
    @InjectRepository(GolfBagClub)
    private readonly clubRepository: Repository<GolfBagClub>,
  ) {}

  async getClubsByUser(userId: string): Promise<GolfBagClub[]> {
    return this.clubRepository.find({
      where: { user_id: userId },
      order: { created_at: 'ASC' },
    });
  }

  async getClubById(userId: string, clubId: string): Promise<GolfBagClub> {
    const club = await this.clubRepository.findOne({
      where: { id: clubId },
    });

    if (!club) {
      throw new NotFoundException('Golf club not found');
    }

    if (club.user_id !== userId) {
      throw new ForbiddenException('You do not have permission to access this club');
    }

    return club;
  }

  async createClub(userId: string, dto: CreateClubDto): Promise<GolfBagClub> {
    const club = this.clubRepository.create({
      user_id: userId,
      club_type: dto.club_type,
      custom_name: dto.custom_name?.trim(),
      average_distance_meters: dto.average_distance_meters ?? 0.0,
      total_shots_recorded: dto.total_shots_recorded ?? 0,
      is_active: dto.is_active ?? true,
    });

    return this.clubRepository.save(club);
  }

  async updateClub(
    userId: string,
    clubId: string,
    dto: UpdateClubDto,
  ): Promise<GolfBagClub> {
    const club = await this.getClubById(userId, clubId);

    if (dto.club_type !== undefined) {
      club.club_type = dto.club_type;
    }
    if (dto.custom_name !== undefined) {
      club.custom_name = dto.custom_name.trim();
    }
    if (dto.average_distance_meters !== undefined) {
      club.average_distance_meters = dto.average_distance_meters;
    }
    if (dto.total_shots_recorded !== undefined) {
      club.total_shots_recorded = dto.total_shots_recorded;
    }
    if (dto.is_active !== undefined) {
      club.is_active = dto.is_active;
    }

    return this.clubRepository.save(club);
  }

  async deleteClub(userId: string, clubId: string): Promise<{ success: boolean; message: string }> {
    const club = await this.getClubById(userId, clubId);
    await this.clubRepository.remove(club);
    return { success: true, message: 'Club deleted successfully' };
  }
}
