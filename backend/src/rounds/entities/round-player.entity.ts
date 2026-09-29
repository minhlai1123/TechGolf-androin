import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { Round } from './round.entity';
import { User } from '../../users/entities/user.entity';
import { RoundScore } from './round-score.entity';

@Entity('round_players')
@Unique('uq_round_players_round_order', ['roundId', 'playerOrder'])
@Index('idx_round_players_round_id', ['roundId'])
@Index('idx_round_players_user_id', ['userId'])
export class RoundPlayer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'round_id', type: 'uuid' })
  roundId: string;

  @ManyToOne(() => Round, (round) => round.players, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'round_id' })
  round: Round;

  @Column({ name: 'user_id', type: 'uuid', nullable: true })
  userId: string | null;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User | null;

  @Column({ name: 'player_name', type: 'varchar', length: 100 })
  playerName: string;

  @Column({ name: 'player_order', type: 'int' })
  playerOrder: number;

  @Column({ name: 'team_id', type: 'varchar', length: 50, nullable: true })
  teamId: string | null;

  @OneToMany(() => RoundScore, (score) => score.player, { cascade: true })
  scores: RoundScore[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
