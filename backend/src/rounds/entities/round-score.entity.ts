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
  Check,
} from 'typeorm';
import { Round } from './round.entity';
import { RoundPlayer } from './round-player.entity';
import { Hole } from '../../courses/entities/hole.entity';

export enum FairwayHit {
  LEFT = 'LEFT',
  STRAIGHT = 'STRAIGHT',
  RIGHT = 'RIGHT',
}

@Entity('round_scores')
@Unique('uq_round_scores_round_player_hole', ['roundId', 'playerId', 'holeId'])
@Check('chk_round_scores_gross', '"gross_score" > 0')
@Check('chk_round_scores_putts', '"putts" >= 0')
@Check('chk_round_scores_penalties', '"penalties" >= 0')
@Check('chk_putts_lte_gross', '"putts" <= "gross_score"')
@Index('idx_round_scores_round_id', ['roundId'])
@Index('idx_round_scores_player_id', ['playerId'])
@Index('idx_round_scores_hole_id', ['holeId'])
export class RoundScore {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'round_id', type: 'uuid' })
  roundId: string;

  @ManyToOne(() => Round, (round) => round.scores, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'round_id' })
  round: Round;

  @Column({ name: 'player_id', type: 'uuid' })
  playerId: string;

  @ManyToOne(() => RoundPlayer, (player) => player.scores, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'player_id' })
  player: RoundPlayer;

  @Column({ name: 'hole_id', type: 'uuid' })
  holeId: string;

  @ManyToOne(() => Hole, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'hole_id' })
  hole: Hole;

  @Column({ name: 'gross_score', type: 'int' })
  grossScore: number;

  @Column({ type: 'int', default: 0 })
  putts: number;

  @Column({ type: 'int', default: 0 })
  penalties: number;

  @Column({
    name: 'fairway_hit',
    type: 'varchar',
    length: 20,
    nullable: true,
  })
  fairwayHit: FairwayHit | null;

  @Column({ type: 'boolean', nullable: true })
  gir: boolean | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
