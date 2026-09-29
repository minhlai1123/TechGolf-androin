import { ApiProperty } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { CourseStatus } from '../entities/course.entity';

export class CreateCourseDto {
  @ApiProperty({ example: 'Pine Valley Golf Club', description: 'Name of the golf course' })
  @IsString()
  @IsNotEmpty({ message: 'Course name is required' })
  name: string;

  @ApiProperty({ example: '1 Golf Course Way', description: 'Street address' })
  @IsString()
  @IsNotEmpty({ message: 'Address is required' })
  address: string;

  @ApiProperty({ example: 'Pine Valley', description: 'City location' })
  @IsString()
  @IsNotEmpty({ message: 'City is required' })
  city: string;

  @ApiProperty({ example: 'United States', description: 'Country' })
  @IsString()
  @IsNotEmpty({ message: 'Country is required' })
  country: string;

  @ApiProperty({ example: 39.7915, description: 'Latitude coordinate' })
  @IsLatitude({ message: 'Latitude must be between -90 and 90' })
  latitude: number;

  @ApiProperty({ example: -74.9702, description: 'Longitude coordinate' })
  @IsLongitude({ message: 'Longitude must be between -180 and 180' })
  longitude: number;

  @ApiProperty({ example: 'America/New_York', required: false, default: 'UTC' })
  @IsOptional()
  @IsString()
  timezone?: string;

  @ApiProperty({ example: 18, required: false, default: 18 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(72)
  total_holes?: number;

  @ApiProperty({ example: 'World renowned championship golf course.', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ enum: CourseStatus, required: false, default: CourseStatus.ACTIVE })
  @IsOptional()
  @IsEnum(CourseStatus)
  status?: CourseStatus;
}
