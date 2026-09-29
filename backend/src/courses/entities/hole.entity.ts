import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { Course } from './course.entity';
import { HoleTee } from './hole-tee.entity';
import { HolePolygon } from './hole-polygon.entity';

@Entity('holes')
@Unique('uq_holes_course_hole_number', ['course_id', 'hole_number'])
export class Hole {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_holes_course_id')
  @Column({ type: 'uuid' })
  course_id: string;

  @ManyToOne(() => Course, (course) => course.holes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'course_id' })
  course: Course;

  @Column({ type: 'int' })
  hole_number: number;

  @Column({ type: 'int' })
  par: number;

  @Column({ type: 'int' })
  handicap_index: number;

  @Column({
    type: 'geometry',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true,
  })
  green_center: any;

  @Column({
    type: 'geometry',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true,
  })
  green_front: any;

  @Column({
    type: 'geometry',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true,
  })
  green_back: any;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;

  @OneToMany(() => HoleTee, (ht) => ht.hole, { cascade: true })
  tees: HoleTee[];

  @OneToMany(() => HolePolygon, (hp) => hp.hole, { cascade: true })
  polygons: HolePolygon[];
}
