import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HolePolygon } from './entities/hole-polygon.entity';
import { Hole } from './entities/hole.entity';
import { CreateHolePolygonDto } from './dto/create-hole-polygon.dto';
import { UpdateHolePolygonDto } from './dto/update-hole-polygon.dto';
import { GeoJsonHelper } from '../common/gis/geojson.helper';

@Injectable()
export class HolePolygonsService {
  constructor(
    @InjectRepository(HolePolygon)
    private readonly polygonRepository: Repository<HolePolygon>,
    @InjectRepository(Hole)
    private readonly holeRepository: Repository<Hole>,
  ) {}

  async findByHole(holeId: string): Promise<HolePolygon[]> {
    return this.polygonRepository.find({
      where: { hole_id: holeId },
      order: { created_at: 'ASC' },
    });
  }

  async findById(id: string): Promise<HolePolygon> {
    const poly = await this.polygonRepository.findOne({ where: { id } });
    if (!poly) {
      throw new NotFoundException(`Polygon with ID '${id}' not found`);
    }
    return poly;
  }

  async create(holeId: string, dto: CreateHolePolygonDto): Promise<HolePolygon> {
    const hole = await this.holeRepository.findOne({ where: { id: holeId } });
    if (!hole) {
      throw new NotFoundException(`Hole with ID '${holeId}' not found`);
    }

    const wktGeometry = GeoJsonHelper.polygonToWkt(dto.coordinates);

    const polygon = this.polygonRepository.create({
      hole_id: holeId,
      polygon_type: dto.polygon_type,
      geometry: wktGeometry,
      metadata: dto.metadata,
    });

    return this.polygonRepository.save(polygon);
  }

  async update(id: string, dto: UpdateHolePolygonDto): Promise<HolePolygon> {
    const polygon = await this.findById(id);

    if (dto.polygon_type !== undefined) {
      polygon.polygon_type = dto.polygon_type;
    }
    if (dto.coordinates !== undefined) {
      polygon.geometry = GeoJsonHelper.polygonToWkt(dto.coordinates);
    }
    if (dto.metadata !== undefined) {
      polygon.metadata = dto.metadata;
    }

    return this.polygonRepository.save(polygon);
  }

  async remove(id: string): Promise<{ success: boolean; message: string }> {
    const polygon = await this.findById(id);
    await this.polygonRepository.remove(polygon);
    return { success: true, message: `Hole polygon '${id}' removed successfully` };
  }
}
