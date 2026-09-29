import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'golfer@example.com', description: 'User email address' })
  @IsEmail({}, { message: 'Invalid email format' })
  @IsNotEmpty({ message: 'Email is required' })
  email: string;

  @ApiProperty({ example: 'SecurePassword123!', description: 'Password (min 6 characters)' })
  @IsString()
  @MinLength(6, { message: 'Password must be at least 6 characters long' })
  @IsNotEmpty({ message: 'Password is required' })
  password: string;

  @ApiProperty({ example: 'Tiger Woods', description: 'Full name of golfer' })
  @IsString()
  @IsNotEmpty({ message: 'Full name is required' })
  full_name: string;

  @ApiProperty({ example: 12.5, required: false, description: 'Initial handicap index' })
  @IsOptional()
  @IsNumber({}, { message: 'Handicap index must be a number' })
  handicap_index?: number;
}
