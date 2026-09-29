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
import { User } from '../../users/entities/user.entity';

export enum ClubType {
  DRIVER = 'DRIVER',
  WOOD_3 = 'WOOD_3',
  WOOD_5 = 'WOOD_5',
  HYBRID_3 = 'HYBRID_3',
  HYBRID_4 = 'HYBRID_4',
  IRON_3 = 'IRON_3',
  IRON_4 = 'IRON_4',
  IRON_5 = 'IRON_5',
  IRON_6 = 'IRON_6',
  IRON_7 = 'IRON_7',
  IRON_8 = 'IRON_8',
  IRON_9 = 'IRON_9',
  PITCHING_WEDGE = 'PITCHING_WEDGE',
  GAP_WEDGE = 'GAP_WEDGE',
  SAND_WEDGE = 'SAND_WEDGE',
  LOB_WEDGE = 'LOB_WEDGE',
  PUTTER = 'PUTTER',
  OTHER = 'OTHER',
}

@Entity('golf_bag_clubs')
export class GolfBagClub {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_golf_bag_clubs_user_id')
  @Column({ type: 'uuid' })
  user_id: string;

  @ManyToOne(() => User, (user) => user.clubs, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 50 })
  club_type: ClubType;

  @Column({ type: 'varchar', length: 100, nullable: true })
  custom_name: string;

  @Column({ type: 'decimal', precision: 5, scale: 1, default: 0.0 })
  average_distance_meters: number;

  @Column({ type: 'int', default: 0 })
  total_shots_recorded: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
