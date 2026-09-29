import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CourseTee } from './entities/course-tee.entity';
import { HoleTee } from './entities/hole-tee.entity';
import { Course } from './entities/course.entity';
import { Hole } from './entities/hole.entity';
import { CreateCourseTeeDto } from './dto/create-course-tee.dto';
import { UpdateCourseTeeDto } from './dto/update-course-tee.dto';
import { SetHoleTeeDto } from './dto/set-hole-tee.dto';
import { GeoJsonHelper } from '../common/gis/geojson.helper';

@Injectable()
export class CourseTeesService {
  constructor(
    @InjectRepository(CourseTee)
    private readonly courseTeeRepository: Repository<CourseTee>,
    @InjectRepository(HoleTee)
    private readonly holeTeeRepository: Repository<HoleTee>,
    @InjectRepository(Course)
    private readonly courseRepository: Repository<Course>,
    @InjectRepository(Hole)
    private readonly holeRepository: Repository<Hole>,
  ) {}

  async findByCourse(courseId: string): Promise<CourseTee[]> {
    return this.courseTeeRepository.find({
      where: { course_id: courseId },
      order: { rating: 'DESC' },
    });
  }

  async createCourseTee(courseId: string, dto: CreateCourseTeeDto): Promise<CourseTee> {
    const course = await this.courseRepository.findOne({ where: { id: courseId } });
    if (!course) {
      throw new NotFoundException(`Course with ID '${courseId}' not found`);
    }

    const tee = this.courseTeeRepository.create({
      course_id: courseId,
      ...dto,
    });

    return this.courseTeeRepository.save(tee);
  }

  async updateCourseTee(id: string, dto: UpdateCourseTeeDto): Promise<CourseTee> {
    const tee = await this.courseTeeRepository.findOne({ where: { id } });
    if (!tee) {
      throw new NotFoundException(`Course tee with ID '${id}' not found`);
    }

    Object.assign(tee, dto);
    return this.courseTeeRepository.save(tee);
  }

  async removeCourseTee(id: string): Promise<{ success: boolean; message: string }> {
    const tee = await this.courseTeeRepository.findOne({ where: { id } });
    if (!tee) {
      throw new NotFoundException(`Course tee with ID '${id}' not found`);
    }

    await this.courseTeeRepository.remove(tee);
    return { success: true, message: `Course tee '${tee.name}' removed` };
  }

  // --- Hole Tee Marker Operations ---

  async findHoleTees(holeId: string): Promise<HoleTee[]> {
    return this.holeTeeRepository.find({
      where: { hole_id: holeId },
      relations: ['courseTee'],
    });
  }

  async setHoleTee(holeId: string, dto: SetHoleTeeDto): Promise<HoleTee> {
    const hole = await this.holeRepository.findOne({ where: { id: holeId } });
    if (!hole) {
      throw new NotFoundException(`Hole with ID '${holeId}' not found`);
    }

    const courseTee = await this.courseTeeRepository.findOne({
      where: { id: dto.course_tee_id },
    });
    if (!courseTee) {
      throw new NotFoundException(`Course tee with ID '${dto.course_tee_id}' not found`);
    }

    GeoJsonHelper.validatePointCoordinates(dto.tee_position);
    const wktPosition = GeoJsonHelper.pointToWkt(dto.tee_position[0], dto.tee_position[1]);

    let holeTee = await this.holeTeeRepository.findOne({
      where: { hole_id: holeId, course_tee_id: dto.course_tee_id },
    });

    if (holeTee) {
      holeTee.tee_position = wktPosition;
      holeTee.distance_meters = dto.distance_meters ?? holeTee.distance_meters;
    } else {
      holeTee = this.holeTeeRepository.create({
        hole_id: holeId,
        course_tee_id: dto.course_tee_id,
        tee_position: wktPosition,
        distance_meters: dto.distance_meters,
      });
    }

    return this.holeTeeRepository.save(holeTee);
  }

  async removeHoleTee(id: string): Promise<{ success: boolean; message: string }> {
    const holeTee = await this.holeTeeRepository.findOne({ where: { id } });
    if (!holeTee) {
      throw new NotFoundException(`Hole tee marker with ID '${id}' not found`);
    }

    await this.holeTeeRepository.remove(holeTee);
    return { success: true, message: 'Hole tee marker removed' };
  }
}
