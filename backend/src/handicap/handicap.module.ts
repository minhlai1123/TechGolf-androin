import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HandicapHistory } from './entities/handicap-history.entity';
import { ScoreDifferential } from './entities/score-differential.entity';
import { User } from '../users/entities/user.entity';
import { Round } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { RoundScore } from '../rounds/entities/round-score.entity';
import { CourseTee } from '../courses/entities/course-tee.entity';
import { HandicapService } from './handicap.service';
import { HandicapController } from './handicap.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      HandicapHistory,
      ScoreDifferential,
      User,
      Round,
      RoundPlayer,
      RoundScore,
      CourseTee,
    ]),
  ],
  controllers: [HandicapController],
  providers: [HandicapService],
  exports: [HandicapService],
})
export class HandicapModule {}
