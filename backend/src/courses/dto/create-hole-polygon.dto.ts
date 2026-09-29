import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsEnum, IsNotEmpty, IsOptional } from 'class-validator';
import { PolygonType } from '../entities/hole-polygon.entity';

export class CreateHolePolygonDto {
  @ApiProperty({
    enum: PolygonType,
    example: PolygonType.FAIRWAY,
    description: 'Vector polygon layer type (FAIRWAY, ROUGH, GREEN, BUNKER, WATER_HAZARD, TEE)',
  })
  @IsEnum(PolygonType, { message: 'Invalid polygon type' })
  @IsNotEmpty()
  polygon_type: PolygonType;

  @ApiProperty({
    example: [
      [
        [-74.972, 39.7905],
        [-74.970, 39.7915],
        [-74.969, 39.7922],
        [-74.971, 39.7912],
        [-74.972, 39.7905],
      ],
    ],
    description: 'GeoJSON Polygon coordinates [ring1, ring2, ...] where ring is an array of [lng, lat] positions',
  })
  @IsArray()
  @IsNotEmpty()
  coordinates: number[][][];

  @ApiProperty({ example: { notes: 'Primary landing zone' }, required: false })
  @IsOptional()
  metadata?: Record<string, any>;
}
