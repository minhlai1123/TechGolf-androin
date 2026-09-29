import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Course } from './entities/course.entity';
import { CourseTee } from './entities/course-tee.entity';
import { Hole } from './entities/hole.entity';
import { HoleTee } from './entities/hole-tee.entity';
import { HolePolygon } from './entities/hole-polygon.entity';
import { CoursesService } from './courses.service';
import { CoursesController } from './courses.controller';
import { HolesService } from './holes.service';
import { HolesController } from './holes.controller';
import { CourseTeesService } from './course-tees.service';
import { CourseTeesController } from './course-tees.controller';
import { HolePolygonsService } from './hole-polygons.service';
import { HolePolygonsController } from './hole-polygons.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Course,
      CourseTee,
      Hole,
      HoleTee,
      HolePolygon,
    ]),
  ],
  controllers: [
    CoursesController,
    HolesController,
    CourseTeesController,
    HolePolygonsController,
  ],
  providers: [
    CoursesService,
    HolesService,
    CourseTeesService,
    HolePolygonsService,
  ],
  exports: [
    CoursesService,
    HolesService,
    CourseTeesService,
    HolePolygonsService,
  ],
})
export class CoursesModule {}
