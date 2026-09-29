import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, Min, IsOptional, IsEnum } from 'class-validator';
import { DistanceUnit } from '../entities/shot.entity';

export class RecommendClubDto {
  @ApiProperty({ example: 150, description: 'Remaining distance to green / flag' })
  @IsNumber({}, { message: 'remainingDistance must be a number' })
  @Min(0, { message: 'remainingDistance cannot be negative' })
  remainingDistance: number;

  @ApiProperty({ enum: DistanceUnit, default: DistanceUnit.YARDS, required: false })
  @IsOptional()
  @IsEnum(DistanceUnit, { message: 'Invalid distance unit' })
  unit?: DistanceUnit;

  @ApiProperty({ example: 10.0, description: 'Current elevation at ball in meters', required: false })
  @IsOptional()
  @IsNumber()
  startElevation?: number;

  @ApiProperty({ example: 18.5, description: 'Target elevation at green in meters', required: false })
  @IsOptional()
  @IsNumber()
  targetElevation?: number;
}
