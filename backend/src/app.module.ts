import { Module } from '@nestjs/common';
import { AppConfigModule } from './config/config.module';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { GolfBagModule } from './golf-bag/golf-bag.module';
import { HealthModule } from './health/health.module';
import { CoursesModule } from './courses/courses.module';
import { RoundsModule } from './rounds/rounds.module';
import { ShotsModule } from './shots/shots.module';
import { HandicapModule } from './handicap/handicap.module';
import { StatisticsModule } from './statistics/statistics.module';
import { StrokesGainedModule } from './strokes-gained/strokes-gained.module';

@Module({
  imports: [
    AppConfigModule,
    DatabaseModule,
    AuthModule,
    UsersModule,
    GolfBagModule,
    HealthModule,
    CoursesModule,
    RoundsModule,
    ShotsModule,
    HandicapModule,
    StatisticsModule,
    StrokesGainedModule,
  ],
})
export class AppModule {}
