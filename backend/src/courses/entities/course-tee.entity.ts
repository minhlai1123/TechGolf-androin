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
} from 'typeorm';
import { Course } from './course.entity';
import { HoleTee } from './hole-tee.entity';

@Entity('course_tees')
export class CourseTee {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_course_tees_course_id')
  @Column({ type: 'uuid' })
  course_id: string;

  @ManyToOne(() => Course, (course) => course.tees, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'course_id' })
  course: Course;

  @Column({ type: 'varchar', length: 50 })
  name: string;

  @Column({ type: 'varchar', length: 30 })
  color: string;

  @Column({ type: 'decimal', precision: 4, scale: 1 })
  rating: number;

  @Column({ type: 'int' })
  slope_rating: number;

  @Column({ type: 'int', nullable: true })
  total_yardage: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;

  @OneToMany(() => HoleTee, (ht) => ht.courseTee, { cascade: true })
  holeTees: HoleTee[];
}
