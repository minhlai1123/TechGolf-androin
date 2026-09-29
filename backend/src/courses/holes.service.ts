import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Hole } from './entities/hole.entity';
import { Course } from './entities/course.entity';
import { CreateHoleDto } from './dto/create-hole.dto';
import { UpdateHoleDto } from './dto/update-hole.dto';
import { GeoJsonHelper, GeoJsonFeatureCollection, GeoJsonFeature } from '../common/gis/geojson.helper';

@Injectable()
export class HolesService {
  constructor(
    @InjectRepository(Hole)
    private readonly holeRepository: Repository<Hole>,
    @InjectRepository(Course)
    private readonly courseRepository: Repository<Course>,
  ) {}

  async findByCourse(courseId: string): Promise<Hole[]> {
    const course = await this.courseRepository.findOne({ where: { id: courseId } });
    if (!course) {
      throw new NotFoundException(`Course with ID '${courseId}' not found`);
    }

    return this.holeRepository.find({
      where: { course_id: courseId },
      order: { hole_number: 'ASC' },
      relations: ['tees', 'tees.courseTee', 'polygons'],
    });
  }

  async findById(id: string): Promise<Hole> {
    const hole = await this.holeRepository.findOne({
      where: { id },
      relations: ['course', 'tees', 'tees.courseTee', 'polygons'],
    });

    if (!hole) {
      throw new NotFoundException(`Hole with ID '${id}' not found`);
    }

    return hole;
  }

  async create(courseId: string, dto: CreateHoleDto): Promise<Hole> {
    const course = await this.courseRepository.findOne({ where: { id: courseId } });
    if (!course) {
      throw new NotFoundException(`Course with ID '${courseId}' not found`);
    }

    const existingHole = await this.holeRepository.findOne({
      where: { course_id: courseId, hole_number: dto.hole_number },
    });
    if (existingHole) {
      throw new ConflictException(
        `Hole number ${dto.hole_number} already exists for this golf course`,
      );
    }

    const hole = this.holeRepository.create({
      course_id: courseId,
      hole_number: dto.hole_number,
      par: dto.par,
      handicap_index: dto.handicap_index,
      green_center: dto.green_center
        ? GeoJsonHelper.pointToWkt(dto.green_center[0], dto.green_center[1])
        : null,
      green_front: dto.green_front
        ? GeoJsonHelper.pointToWkt(dto.green_front[0], dto.green_front[1])
        : null,
      green_back: dto.green_back
        ? GeoJsonHelper.pointToWkt(dto.green_back[0], dto.green_back[1])
        : null,
    });

    return this.holeRepository.save(hole);
  }

  async update(id: string, dto: UpdateHoleDto): Promise<Hole> {
    const hole = await this.findById(id);

    if (dto.hole_number !== undefined && dto.hole_number !== hole.hole_number) {
      const existing = await this.holeRepository.findOne({
        where: { course_id: hole.course_id, hole_number: dto.hole_number },
      });
      if (existing && existing.id !== id) {
        throw new ConflictException(
          `Hole number ${dto.hole_number} already exists on this course`,
        );
      }
      hole.hole_number = dto.hole_number;
    }

    if (dto.par !== undefined) hole.par = dto.par;
    if (dto.handicap_index !== undefined) hole.handicap_index = dto.handicap_index;

    if (dto.green_center !== undefined) {
      hole.green_center = dto.green_center
        ? GeoJsonHelper.pointToWkt(dto.green_center[0], dto.green_center[1])
        : null;
    }
    if (dto.green_front !== undefined) {
      hole.green_front = dto.green_front
        ? GeoJsonHelper.pointToWkt(dto.green_front[0], dto.green_front[1])
        : null;
    }
    if (dto.green_back !== undefined) {
      hole.green_back = dto.green_back
        ? GeoJsonHelper.pointToWkt(dto.green_back[0], dto.green_back[1])
        : null;
    }

    return this.holeRepository.save(hole);
  }

  async remove(id: string): Promise<{ success: boolean; message: string }> {
    const hole = await this.findById(id);
    await this.holeRepository.remove(hole);
    return { success: true, message: `Hole ${hole.hole_number} deleted successfully` };
  }

  /**
   * Generates a complete GeoJSON FeatureCollection containing all map layers for the hole:
   * 1. Green Target Points (Center, Front, Back)
   * 2. Tee Markers (Red, White, Blue, Black, etc.)
   * 3. Vector Polygons (Fairway, Rough, Green, Bunker, Water Hazard, Tee)
   */
  async getHoleMapData(id: string): Promise<GeoJsonFeatureCollection> {
    const hole = await this.findById(id);
    const features: GeoJsonFeature[] = [];

    // 1. Green Points
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

    // 2. Tee Markers
    if (hole.tees && hole.tees.length > 0) {
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

    // 3. Vector Polygons
    if (hole.polygons && hole.polygons.length > 0) {
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
      type: 'FeatureCollection',
      features,
    };
  }
}
