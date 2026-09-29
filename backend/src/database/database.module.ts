import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { User } from '../users/entities/user.entity';
import { GolfBagClub } from '../golf-bag/entities/golf-bag-club.entity';
import { HandicapHistory } from '../handicap/entities/handicap-history.entity';
import { Course } from '../courses/entities/course.entity';
import { CourseTee } from '../courses/entities/course-tee.entity';
import { Hole } from '../courses/entities/hole.entity';
import { HoleTee } from '../courses/entities/hole-tee.entity';
import { HolePolygon } from '../courses/entities/hole-polygon.entity';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('database.host'),
        port: configService.get<number>('database.port'),
        username: configService.get<string>('database.username'),
        password: configService.get<string>('database.password'),
        database: configService.get<string>('database.database'),
        entities: [
          User,
          GolfBagClub,
          HandicapHistory,
          Course,
          CourseTee,
          Hole,
          HoleTee,
          HolePolygon,
        ],
        synchronize: false,
        autoLoadEntities: true,
        logging: configService.get<string>('nodeEnv') === 'development',
      }),
    }),
  ],
})
export class DatabaseModule {}
