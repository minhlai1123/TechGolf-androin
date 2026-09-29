import { ApiProperty } from '@nestjs/swagger';
import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  Max,
  Min,
} from 'class-validator';

export class CreateHoleDto {
  @ApiProperty({ example: 1, description: 'Hole number on the course' })
  @IsInt()
  @Min(1)
  @Max(72)
  @IsNotEmpty()
  hole_number: number;

  @ApiProperty({ example: 4, description: 'Par value for this hole (typically 3, 4, or 5)' })
  @IsInt()
  @Min(3)
  @Max(6)
  @IsNotEmpty()
  par: number;

  @ApiProperty({ example: 7, description: 'Stroke index / handicap ranking for this hole (1-18)' })
  @IsInt()
  @Min(1)
  @Max(72)
  @IsNotEmpty()
  handicap_index: number;

  @ApiProperty({ example: [-74.9688, 39.7925], required: false, description: 'Green center [lng, lat]' })
  @IsOptional()
  @IsArray()
  green_center?: [number, number];

  @ApiProperty({ example: [-74.9691, 39.7923], required: false, description: 'Green front [lng, lat]' })
  @IsOptional()
  @IsArray()
  green_front?: [number, number];

  @ApiProperty({ example: [-74.9685, 39.7927], required: false, description: 'Green back [lng, lat]' })
  @IsOptional()
  @IsArray()
  green_back?: [number, number];
}
