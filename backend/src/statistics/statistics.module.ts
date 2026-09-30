import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StatisticsService } from './statistics.service';
import { StatisticsController } from './statistics.controller';
import { User } from '../users/entities/user.entity';
import { Round } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { RoundScore } from '../rounds/entities/round-score.entity';
import { ScoreDifferential } from '../handicap/entities/score-differential.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Round,
      RoundPlayer,
      RoundScore,
      ScoreDifferential,
    ]),
  ],
  controllers: [StatisticsController],
  providers: [StatisticsService],
  exports: [StatisticsService],
})
export class StatisticsModule {}
