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

  async getCourseBundle(id: string) {
    const course = await this.courseRepository.findOne({
      where: { id },
      relations: ['tees', 'holes', 'holes.tees', 'holes.tees.courseTee', 'holes.polygons'],
    });

    if (!course) {
      throw new NotFoundException(`Golf course with ID '${id}' not found`);
    }

    if (course.holes) {
      course.holes.sort((a, b) => a.hole_number - b.hole_number);
    }

    const holesBundle = (course.holes || []).map((hole) => {
      const features: any[] = [];

      if (hole.green_center) {
        features.push({
          type: 'Feature',
          geometry: GeoJsonHelper.toGeoJsonPoint(hole.green_center),
          properties: {
            element: 'GREEN_POINT',
            target: 'CENTER',
            name: 'Green Center',
            hole_number: hole.hole_number,
          },
        });
      }
      if (hole.green_front) {
        features.push({
          type: 'Feature',
          geometry: GeoJsonHelper.toGeoJsonPoint(hole.green_front),
          properties: {
            element: 'GREEN_POINT',
            target: 'FRONT',
            name: 'Green Front',
            hole_number: hole.hole_number,
          },
        });
      }
      if (hole.green_back) {
        features.push({
          type: 'Feature',
          geometry: GeoJsonHelper.toGeoJsonPoint(hole.green_back),
          properties: {
            element: 'GREEN_POINT',
            target: 'BACK',
            name: 'Green Back',
            hole_number: hole.hole_number,
          },
        });
      }

      if (hole.tees) {
        for (const ht of hole.tees) {
          if (ht.tee_position) {
            features.push({
              type: 'Feature',
              id: ht.id,
              geometry: GeoJsonHelper.toGeoJsonPoint(ht.tee_position),
              properties: {
                element: 'TEE_MARKER',
                tee_id: ht.id,
                course_tee_id: ht.course_tee_id,
                tee_name: ht.courseTee?.name || 'Tee',
                tee_color: ht.courseTee?.color || '#000000',
                distance_meters: ht.distance_meters,
                hole_number: hole.hole_number,
              },
            });
          }
        }
      }

      if (hole.polygons) {
        for (const poly of hole.polygons) {
          if (poly.geometry) {
            features.push({
              type: 'Feature',
              id: poly.id,
              geometry: GeoJsonHelper.toGeoJsonPolygon(poly.geometry),
              properties: {
                element: 'VECTOR_POLYGON',
                polygon_id: poly.id,
                type: poly.polygon_type,
                metadata: poly.metadata,
                hole_number: hole.hole_number,
              },
            });
          }
        }
      }

      return {
        id: hole.id,
        hole_number: hole.hole_number,
        par: hole.par,
        handicap_index: hole.handicap_index,
        green_center: GeoJsonHelper.toGeoJsonPoint(hole.green_center),
        green_front: GeoJsonHelper.toGeoJsonPoint(hole.green_front),
        green_back: GeoJsonHelper.toGeoJsonPoint(hole.green_back),
        map: {
          type: 'FeatureCollection',
          features,
        },
      };
    });

    return {
      course: {
        id: course.id,
        name: course.name,
        address: course.address,
        city: course.city,
        country: course.country,
        latitude: course.latitude,
        longitude: course.longitude,
        timezone: course.timezone,
        total_holes: course.total_holes,
        description: course.description,
        status: course.status,
      },
      tees: course.tees || [],
      holes: holesBundle,
      downloaded_at: new Date().toISOString(),
    };
  }
}
