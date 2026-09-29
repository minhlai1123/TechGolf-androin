import {
  IsUUID,
  IsInt,
  Min,
  IsOptional,
  IsEnum,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FairwayHit } from '../entities/round-score.entity';

export class SaveScoreDto {
  @ApiProperty({ description: 'Round Player UUID', format: 'uuid' })
  @IsUUID('4')
  playerId: string;

  @ApiProperty({ description: 'Hole UUID', format: 'uuid' })
  @IsUUID('4')
  holeId: string;

  @ApiProperty({ description: 'Gross Score for hole (must be > 0)', example: 4 })
  @IsInt()
  @Min(1, { message: 'Gross score must be greater than 0' })
  grossScore: number;

  @ApiPropertyOptional({ description: 'Putts taken on green (>= 0, <= grossScore)', example: 2 })
  @IsOptional()
  @IsInt()
  @Min(0)
  putts?: number;

  @ApiPropertyOptional({ description: 'Penalty strokes incurred (>= 0)', example: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  penalties?: number;

  @ApiPropertyOptional({ enum: FairwayHit, example: FairwayHit.STRAIGHT })
  @IsOptional()
  @IsEnum(FairwayHit)
  fairwayHit?: FairwayHit;

  @ApiPropertyOptional({ description: 'Green in Regulation hit', example: true })
  @IsOptional()
  @IsBoolean()
  gir?: boolean;
}
