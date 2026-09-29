import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { ClubType } from '../entities/golf-bag-club.entity';

export class CreateClubDto {
  @ApiProperty({
    enum: ClubType,
    example: ClubType.DRIVER,
    description: 'Type of club (DRIVER, 7_IRON, PUTTER, etc.)',
  })
  @IsEnum(ClubType, { message: 'Invalid club type' })
  @IsNotEmpty({ message: 'club_type is required' })
  club_type: ClubType;

  @ApiProperty({ example: 'TaylorMade Stealth 2', required: false })
  @IsOptional()
  @IsString()
  custom_name?: string;

  @ApiProperty({ example: 230.5, required: false, description: 'Average distance in meters' })
  @IsOptional()
  @IsNumber({}, { message: 'average_distance_meters must be a number' })
  @Min(0, { message: 'average_distance_meters cannot be negative' })
  average_distance_meters?: number;

  @ApiProperty({ example: 0, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  total_shots_recorded?: number;

  @ApiProperty({ example: true, required: false })
  @IsOptional()
  is_active?: boolean;
}
