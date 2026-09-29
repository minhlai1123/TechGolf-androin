import {
  IsUUID,
  IsEnum,
  IsArray,
  ValidateNested,
  ArrayMinSize,
  ArrayMaxSize,
  IsString,
  IsInt,
  Min,
  Max,
  IsOptional,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GameMode } from '../entities/round.entity';

export class RoundPlayerInputDto {
  @ApiPropertyOptional({ description: 'Optional User ID if registered user', format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  userId?: string;

  @ApiProperty({ description: 'Player display name', example: 'Minh Lai' })
  @IsString()
  playerName: string;

  @ApiProperty({ description: 'Player order in flight (1 to 4)', example: 1 })
  @IsInt()
  @Min(1)
  @Max(4)
  playerOrder: number;

  @ApiPropertyOptional({ description: 'Team ID for team modes (Scramble/Four-Ball)', example: 'Team A' })
  @IsOptional()
  @IsString()
  teamId?: string;
}

export class CreateRoundDto {
  @ApiProperty({ description: 'Golf course UUID', format: 'uuid' })
  @IsUUID('4')
  courseId: string;

  @ApiProperty({ enum: GameMode, example: GameMode.STROKE_PLAY })
  @IsEnum(GameMode)
  gameMode: GameMode;

  @ApiProperty({
    description: 'List of players in flight (1 to 4 players)',
    type: [RoundPlayerInputDto],
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'Round must have at least 1 player' })
  @ArrayMaxSize(4, { message: 'Round cannot exceed 4 players' })
  @ValidateNested({ each: true })
  @Type(() => RoundPlayerInputDto)
  players: RoundPlayerInputDto[];
}
