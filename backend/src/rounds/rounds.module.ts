import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Round } from './entities/round.entity';
import { RoundPlayer } from './entities/round-player.entity';
import { RoundScore } from './entities/round-score.entity';
import { Course } from '../courses/entities/course.entity';
import { Hole } from '../courses/entities/hole.entity';
import { RoundsService } from './rounds.service';
import { RoundsController } from './rounds.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Round, RoundPlayer, RoundScore, Course, Hole]),
  ],
  providers: [RoundsService],
  controllers: [RoundsController],
  exports: [RoundsService],
})
export class RoundsModule {}
