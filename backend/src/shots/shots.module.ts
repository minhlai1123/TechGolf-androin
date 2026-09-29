import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Shot } from './entities/shot.entity';
import { Round } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { Hole } from '../courses/entities/hole.entity';
import { GolfBagClub } from '../golf-bag/entities/golf-bag-club.entity';
import { ShotsService } from './shots.service';
import { ShotsController } from './shots.controller';
import { ClubDistanceController } from './club-distance.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Shot,
      Round,
      RoundPlayer,
      Hole,
      GolfBagClub,
    ]),
  ],
  controllers: [ShotsController, ClubDistanceController],
  providers: [ShotsService],
  exports: [ShotsService],
})
export class ShotsModule {}
