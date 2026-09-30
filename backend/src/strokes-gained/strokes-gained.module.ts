import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StrokesGainedService } from './strokes-gained.service';
import { StrokesGainedController } from './strokes-gained.controller';
import { Shot } from '../shots/entities/shot.entity';
import { Round } from '../rounds/entities/round.entity';
import { RoundPlayer } from '../rounds/entities/round-player.entity';
import { Hole } from '../courses/entities/hole.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Shot,
      Round,
      RoundPlayer,
      Hole,
    ]),
  ],
  controllers: [StrokesGainedController],
  providers: [StrokesGainedService],
  exports: [StrokesGainedService],
})
export class StrokesGainedModule {}
