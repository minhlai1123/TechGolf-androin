import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async findById(id: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async update(id: string, dto: UpdateUserDto): Promise<User> {
    const user = await this.findById(id);

    if (dto.full_name !== undefined) {
      user.full_name = dto.full_name.trim();
    }
    if (dto.avatar_url !== undefined) {
      user.avatar_url = dto.avatar_url.trim();
    }
    if (dto.handicap_index !== undefined) {
      user.handicap_index = dto.handicap_index;
    }

    return this.userRepository.save(user);
  }
}
