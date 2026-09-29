import { ApiProperty } from '@nestjs/swagger';
import {
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CreateCourseTeeDto {
  @ApiProperty({ example: 'Blue', description: 'Tee marker name (Red, White, Blue, Black, etc.)' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: '#2563EB', description: 'Hex or color name' })
  @IsString()
  @IsNotEmpty()
  color: string;

  @ApiProperty({ example: 73.5, description: 'USGA / WHS Course Rating' })
  @IsNumber()
  @Min(50)
  @Max(90)
  @IsNotEmpty()
  rating: number;

  @ApiProperty({ example: 135, description: 'USGA / WHS Slope Rating (55 - 155)' })
  @IsInt()
  @Min(55)
  @Max(155)
  @IsNotEmpty()
  slope_rating: number;

  @ApiProperty({ example: 6850, required: false, description: 'Total course yardage from this tee' })
  @IsOptional()
  @IsInt()
  @Min(1000)
  total_yardage?: number;
}
