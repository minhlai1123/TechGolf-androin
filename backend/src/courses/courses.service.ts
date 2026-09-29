import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { Course } from './entities/course.entity';
import { CreateCourseDto } from './dto/create-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';
import { GeoJsonHelper } from '../common/gis/geojson.helper';

@Injectable()
export class CoursesService {
  constructor(
    @InjectRepository(Course)
    private readonly courseRepository: Repository<Course>,
  ) {}

  async findAll(search?: string, city?: string): Promise<Course[]> {
    const where: any = {};
    if (search) {
      where.name = ILike(`%${search}%`);
    }
    if (city) {
      where.city = ILike(`%${city}%`);
    }

    return this.courseRepository.find({
      where,
      relations: ['tees'],
      order: { name: 'ASC' },
    });
  }

  async findById(id: string): Promise<Course> {
    const course = await this.courseRepository.findOne({
      where: { id },
      relations: ['tees', 'holes'],
    });

    if (!course) {
      throw new NotFoundException(`Golf course with ID '${id}' not found`);
    }

    // Sort holes by hole_number
    if (course.holes) {
      course.holes.sort((a, b) => a.hole_number - b.hole_number);
    }

    return course;
  }

  async create(dto: CreateCourseDto): Promise<Course> {
    const locationWkt = GeoJsonHelper.pointToWkt(dto.longitude, dto.latitude);

    const course = this.courseRepository.create({
      ...dto,
      location: locationWkt,
    });

    return this.courseRepository.save(course);
  }

  async update(id: string, dto: UpdateCourseDto): Promise<Course> {
    const course = await this.findById(id);

    if (dto.name !== undefined) course.name = dto.name.trim();
    if (dto.address !== undefined) course.address = dto.address.trim();
    if (dto.city !== undefined) course.city = dto.city.trim();
    if (dto.country !== undefined) course.country = dto.country.trim();
    if (dto.timezone !== undefined) course.timezone = dto.timezone;
    if (dto.total_holes !== undefined) course.total_holes = dto.total_holes;
    if (dto.description !== undefined) course.description = dto.description;
    if (dto.status !== undefined) course.status = dto.status;

    if (dto.latitude !== undefined || dto.longitude !== undefined) {
      course.latitude = dto.latitude ?? course.latitude;
      course.longitude = dto.longitude ?? course.longitude;
      course.location = GeoJsonHelper.pointToWkt(course.longitude, course.latitude);
    }

    return this.courseRepository.save(course);
  }

  async remove(id: string): Promise<{ success: boolean; message: string }> {
    const course = await this.findById(id);
    await this.courseRepository.remove(course);
    return { success: true, message: `Course '${course.name}' deleted successfully` };
  }
}
