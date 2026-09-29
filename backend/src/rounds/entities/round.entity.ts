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
import { Course } from '../../courses/entities/course.entity';
import { User } from '../../users/entities/user.entity';
import { RoundPlayer } from './round-player.entity';
import { RoundScore } from './round-score.entity';

export enum GameMode {
  STROKE_PLAY = 'STROKE_PLAY',
  STABLEFORD = 'STABLEFORD',
  MATCH_PLAY = 'MATCH_PLAY',
  SCRAMBLE = 'SCRAMBLE',
  FOUR_BALL = 'FOUR_BALL',
}

export enum RoundStatus {
  NOT_STARTED = 'NOT_STARTED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

@Entity('rounds')
@Index('idx_rounds_course_id', ['courseId'])
@Index('idx_rounds_created_by', ['createdBy'])
@Index('idx_rounds_status', ['status'])
export class Round {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'course_id', type: 'uuid' })
  courseId: string;

  @ManyToOne(() => Course, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'course_id' })
  course: Course;

  @Column({
    name: 'game_mode',
    type: 'varchar',
    length: 50,
  })
  gameMode: GameMode;

  @Column({
    type: 'varchar',
    length: 50,
    default: RoundStatus.NOT_STARTED,
  })
  status: RoundStatus;

  @Column({ name: 'current_hole', type: 'int', default: 1 })
  currentHole: number;

  @Column({ name: 'started_at', type: 'timestamptz', nullable: true })
  startedAt: Date | null;

  @Column({ name: 'finished_at', type: 'timestamptz', nullable: true })
  finishedAt: Date | null;

  @Column({ name: 'created_by', type: 'uuid' })
  createdBy: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'created_by' })
  creator: User;

  @OneToMany(() => RoundPlayer, (player) => player.round, { cascade: true })
  players: RoundPlayer[];

  @OneToMany(() => RoundScore, (score) => score.round, { cascade: true })
  scores: RoundScore[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
