import {
  IsUUID,
  IsInt,
  Min,
  IsOptional,
  IsEnum,
  IsBoolean,
  IsNotEmpty,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FairwayHit } from '../entities/round-score.entity';

export class LivePlayJoinDto {
  @ApiProperty({ description: 'Round UUID to join for live session' })
  @IsUUID()
  @IsNotEmpty()
  roundId: string;
}

export class LivePlayScoreUpdateDto {
  @ApiProperty({ description: 'Round UUID' })
  @IsUUID()
  @IsNotEmpty()
  roundId: string;

  @ApiProperty({ description: 'Hole UUID' })
  @IsUUID()
  @IsNotEmpty()
  holeId: string;

  @ApiPropertyOptional({ description: 'Player UUID in round' })
  @IsUUID()
  @IsOptional()
  playerId?: string;

  @ApiProperty({ description: 'Gross score (strokes taken on hole)', minimum: 1 })
  @IsInt()
  @Min(1)
  grossScore: number;

  @ApiPropertyOptional({ description: 'Number of putts on hole', minimum: 0, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  putts?: number;

  @ApiPropertyOptional({ description: 'Penalty strokes', minimum: 0, default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  penalties?: number;

  @ApiPropertyOptional({
    description: 'Fairway hit result on Par 4/5',
    enum: FairwayHit,
    nullable: true,
  })
  @IsEnum(FairwayHit)
  @IsOptional()
  fairwayHit?: FairwayHit | null;

  @ApiPropertyOptional({
    description: 'Green in regulation reached',
    nullable: true,
  })
  @IsBoolean()
  @IsOptional()
  gir?: boolean | null;
}
