import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Round } from '../../rounds/entities/round.entity';
import { Course } from '../../courses/entities/course.entity';
import { CourseTee } from '../../courses/entities/course-tee.entity';

@Entity('score_differentials')
@Unique('uq_score_diff_round_user', ['round_id', 'user_id'])
export class ScoreDifferential {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_score_diff_user_id')
  @Column({ type: 'uuid' })
  user_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Index('idx_score_diff_round_id')
  @Column({ type: 'uuid' })
  round_id: string;

  @ManyToOne(() => Round, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'round_id' })
  round: Round;

  @Column({ type: 'uuid' })
  course_id: string;

  @ManyToOne(() => Course, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'course_id' })
  course: Course;

  @Column({ type: 'uuid', nullable: true })
  course_tee_id: string | null;

  @ManyToOne(() => CourseTee, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'course_tee_id' })
  courseTee: CourseTee | null;

  @Column({ type: 'int' })
  gross_score: number;

  @Column({ type: 'int' })
  adjusted_gross_score: number;

  @Column({ type: 'decimal', precision: 4, scale: 1 })
  course_rating: number;

  @Column({ type: 'int' })
  slope_rating: number;

  @Column({ type: 'decimal', precision: 3, scale: 1, default: 0.0 })
  pcc: number;

  @Column({ type: 'varchar', length: 20, default: 'UNAVAILABLE' })
  pcc_status: string;

  @Column({ type: 'decimal', precision: 4, scale: 1 })
  score_differential: number;

  @Column({ type: 'boolean', default: false })
  is_used_in_handicap: boolean;

  @Index('idx_score_diff_played_at')
  @Column({ type: 'timestamp with time zone' })
  played_at: Date;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
