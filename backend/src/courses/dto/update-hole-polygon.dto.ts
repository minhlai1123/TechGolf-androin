import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsEnum, IsOptional } from 'class-validator';
import { PolygonType } from '../entities/hole-polygon.entity';

export class UpdateHolePolygonDto {
  @ApiProperty({ enum: PolygonType, required: false })
  @IsOptional()
  @IsEnum(PolygonType)
  polygon_type?: PolygonType;

  @ApiProperty({ required: false, description: 'Updated GeoJSON Polygon coordinates' })
  @IsOptional()
  @IsArray()
  coordinates?: number[][][];

  @ApiProperty({ required: false })
  @IsOptional()
  metadata?: Record<string, any>;
}
