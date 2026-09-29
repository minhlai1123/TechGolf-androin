import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('handicap_history')
export class HandicapHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_handicap_history_user_id')
  @Column({ type: 'uuid' })
  user_id: string;

  @ManyToOne(() => User, (user) => user.handicapHistory, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'uuid', nullable: true })
  round_id: string;

  @Column({ type: 'decimal', precision: 4, scale: 1 })
  score_differential: number;

  @Column({ type: 'decimal', precision: 4, scale: 1 })
  resulting_handicap_index: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  calculated_at: Date;
}
