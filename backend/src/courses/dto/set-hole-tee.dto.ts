import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsInt, IsNotEmpty, IsOptional, IsUUID, Min } from 'class-validator';

export class SetHoleTeeDto {
  @ApiProperty({ example: '3fa85f64-5717-4562-b3fc-2c963f66afa6', description: 'Course tee UUID' })
  @IsUUID()
  @IsNotEmpty()
  course_tee_id: string;

  @ApiProperty({ example: [-74.9721, 39.7902], description: 'Tee box position [lng, lat]' })
  @IsArray()
  @IsNotEmpty()
  tee_position: [number, number];

  @ApiProperty({ example: 385, required: false, description: 'Distance to green center in meters' })
  @IsOptional()
  @IsInt()
  @Min(0)
  distance_meters?: number;
}
