import { ApiProperty } from '@nestjs/swagger';
import {
  IsUUID,
  IsNotEmpty,
  IsNumber,
  Min,
  Max,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { DistanceUnit } from '../entities/shot.entity';

export class StartShotDto {
  @ApiProperty({ description: 'Player UUID in round' })
  @IsUUID('4', { message: 'playerId must be a valid UUID' })
  @IsNotEmpty({ message: 'playerId is required' })
  playerId: string;

  @ApiProperty({ description: 'Hole UUID' })
  @IsUUID('4', { message: 'holeId must be a valid UUID' })
  @IsNotEmpty({ message: 'holeId is required' })
  holeId: string;

  @ApiProperty({ description: 'Initial club used (optional at start)', required: false })
  @IsOptional()
  @IsUUID('4', { message: 'clubId must be a valid UUID' })
  clubId?: string;

  @ApiProperty({ example: 21.028511, description: 'GPS start latitude' })
  @IsNumber({}, { message: 'latitude must be a valid number' })
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ example: 105.854444, description: 'GPS start longitude' })
  @IsNumber({}, { message: 'longitude must be a valid number' })
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiProperty({ example: 12.5, description: 'Altitude / elevation at start in meters', required: false })
  @IsOptional()
  @IsNumber()
  elevation?: number;

  @ApiProperty({ enum: DistanceUnit, default: DistanceUnit.YARDS, required: false })
  @IsOptional()
  @IsEnum(DistanceUnit, { message: 'Invalid distance unit' })
  unit?: DistanceUnit;
}
