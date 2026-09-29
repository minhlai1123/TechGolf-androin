import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, IsUrl } from 'class-validator';

export class UpdateUserDto {
  @ApiProperty({ example: 'Tiger Woods', required: false })
  @IsOptional()
  @IsString()
  full_name?: string;

  @ApiProperty({ example: 'https://example.com/avatar.jpg', required: false })
  @IsOptional()
  @IsUrl({}, { message: 'avatar_url must be a valid URL' })
  avatar_url?: string;

  @ApiProperty({ example: 14.2, required: false })
  @IsOptional()
  @IsNumber({}, { message: 'handicap_index must be a number' })
  handicap_index?: number;
}
