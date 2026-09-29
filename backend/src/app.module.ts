import { Module } from '@nestjs/common';
import { AppConfigModule } from './config/config.module';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { GolfBagModule } from './golf-bag/golf-bag.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    AppConfigModule,
    DatabaseModule,
    AuthModule,
    UsersModule,
    GolfBagModule,
    HealthModule,
  ],
})
export class AppModule {}
