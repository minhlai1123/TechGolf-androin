import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { ClubType } from '../entities/golf-bag-club.entity';

export class UpdateClubDto {
  @ApiProperty({ enum: ClubType, required: false })
  @IsOptional()
  @IsEnum(ClubType, { message: 'Invalid club type' })
  club_type?: ClubType;

  @ApiProperty({ example: 'Callaway Paradym Driver', required: false })
  @IsOptional()
  @IsString()
  custom_name?: string;

  @ApiProperty({ example: 240.0, required: false })
  @IsOptional()
  @IsNumber({}, { message: 'average_distance_meters must be a number' })
  @Min(0, { message: 'average_distance_meters cannot be negative' })
  average_distance_meters?: number;

  @ApiProperty({ example: 25, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  total_shots_recorded?: number;
}
