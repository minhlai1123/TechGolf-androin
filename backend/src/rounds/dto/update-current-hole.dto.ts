import { IsInt, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateCurrentHoleDto {
  @ApiProperty({ description: 'New current hole number (>= 1)', example: 2 })
  @IsInt()
  @Min(1)
  currentHole: number;
}
