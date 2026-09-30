import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Round } from './entities/round.entity';
import { RoundPlayer } from './entities/round-player.entity';
import { RoundScore } from './entities/round-score.entity';
import { Course } from '../courses/entities/course.entity';
import { Hole } from '../courses/entities/hole.entity';
import { User } from '../users/entities/user.entity';
import { AuthModule } from '../auth/auth.module';
import { RoundsService } from './rounds.service';
import { RoundsController } from './rounds.controller';
import { LivePlayGateway } from './liveplay/liveplay.gateway';

@Module({
  imports: [
    TypeOrmModule.forFeature([Round, RoundPlayer, RoundScore, Course, Hole, User]),
    AuthModule,
  ],
  providers: [RoundsService, LivePlayGateway],
  controllers: [RoundsController],
  exports: [RoundsService, LivePlayGateway],
})
export class RoundsModule {}
