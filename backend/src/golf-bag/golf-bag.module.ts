import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GolfBagClub } from './entities/golf-bag-club.entity';
import { GolfBagService } from './golf-bag.service';
import { GolfBagController } from './golf-bag.controller';

@Module({
  imports: [TypeOrmModule.forFeature([GolfBagClub])],
  controllers: [GolfBagController],
  providers: [GolfBagService],
  exports: [GolfBagService],
})
export class GolfBagModule {}
