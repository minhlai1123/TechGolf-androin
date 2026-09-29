import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { Hole } from './hole.entity';
import { CourseTee } from './course-tee.entity';

@Entity('hole_tees')
@Unique('uq_hole_tees_hole_course_tee', ['hole_id', 'course_tee_id'])
export class HoleTee {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_hole_tees_hole_id')
  @Column({ type: 'uuid' })
  hole_id: string;

  @ManyToOne(() => Hole, (hole) => hole.tees, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'hole_id' })
  hole: Hole;

  @Index('idx_hole_tees_course_tee_id')
  @Column({ type: 'uuid' })
  course_tee_id: string;

  @ManyToOne(() => CourseTee, (ct) => ct.holeTees, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'course_tee_id' })
  courseTee: CourseTee;

  @Column({
    type: 'geometry',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  tee_position: any;

  @Column({ type: 'int', nullable: true })
  distance_meters: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
