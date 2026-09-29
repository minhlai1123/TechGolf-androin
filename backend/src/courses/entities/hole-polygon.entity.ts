import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Hole } from './hole.entity';

export enum PolygonType {
  FAIRWAY = 'FAIRWAY',
  ROUGH = 'ROUGH',
  GREEN = 'GREEN',
  BUNKER = 'BUNKER',
  WATER_HAZARD = 'WATER_HAZARD',
  TEE = 'TEE',
}

@Entity('hole_polygons')
export class HolePolygon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_hole_polygons_hole_id')
  @Column({ type: 'uuid' })
  hole_id: string;

  @ManyToOne(() => Hole, (hole) => hole.polygons, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'hole_id' })
  hole: Hole;

  @Column({
    type: 'varchar',
    length: 50,
  })
  polygon_type: PolygonType;

  @Column({
    type: 'geometry',
    spatialFeatureType: 'Polygon',
    srid: 4326,
  })
  geometry: any;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
