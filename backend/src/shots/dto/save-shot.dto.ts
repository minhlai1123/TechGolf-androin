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

export class SaveShotDto {
  @ApiProperty({ description: 'Club used for the shot' })
  @IsUUID('4', { message: 'clubId must be a valid UUID' })
  @IsNotEmpty({ message: 'clubId is required when saving shot' })
  clubId: string;

  @ApiProperty({ example: 21.029800, description: 'GPS end latitude (where ball landed)' })
  @IsNumber({}, { message: 'latitude must be a valid number' })
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ example: 105.855200, description: 'GPS end longitude (where ball landed)' })
  @IsNumber({}, { message: 'longitude must be a valid number' })
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiProperty({ example: 15.2, description: 'Altitude / elevation at end in meters', required: false })
  @IsOptional()
  @IsNumber()
  elevation?: number;

  @ApiProperty({ enum: DistanceUnit, default: DistanceUnit.YARDS, required: false })
  @IsOptional()
  @IsEnum(DistanceUnit, { message: 'Invalid distance unit' })
  unit?: DistanceUnit;
}
