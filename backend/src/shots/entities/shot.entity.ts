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
import { Round } from '../../rounds/entities/round.entity';
import { RoundPlayer } from '../../rounds/entities/round-player.entity';
import { User } from '../../users/entities/user.entity';
import { Hole } from '../../courses/entities/hole.entity';
import { GolfBagClub } from '../../golf-bag/entities/golf-bag-club.entity';

export enum ShotStatus {
  READY = 'READY',
  STARTED = 'STARTED',
  SAVED = 'SAVED',
}

export enum DistanceUnit {
  YARDS = 'YARDS',
  METERS = 'METERS',
}

@Entity('shots')
@Index('idx_shots_round_id', ['roundId'])
@Index('idx_shots_player_id', ['playerId'])
@Index('idx_shots_hole_id', ['holeId'])
@Index('idx_shots_club_id', ['clubId'])
@Index('idx_shots_user_id', ['userId'])
export class Shot {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'round_id', type: 'uuid' })
  roundId: string;

  @ManyToOne(() => Round, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'round_id' })
  round: Round;

  @Column({ name: 'player_id', type: 'uuid' })
  playerId: string;

  @ManyToOne(() => RoundPlayer, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'player_id' })
  player: RoundPlayer;

  @Column({ name: 'user_id', type: 'uuid', nullable: true })
  userId: string | null;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User | null;

  @Column({ name: 'hole_id', type: 'uuid' })
  holeId: string;

  @ManyToOne(() => Hole, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'hole_id' })
  hole: Hole;

  @Column({ name: 'club_id', type: 'uuid', nullable: true })
  clubId: string | null;

  @ManyToOne(() => GolfBagClub, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'club_id' })
  club: GolfBagClub | null;

  @Column({
    type: 'varchar',
    length: 20,
    default: ShotStatus.STARTED,
  })
  status: ShotStatus;

  @Column({ name: 'start_latitude', type: 'double precision' })
  startLatitude: number;

  @Column({ name: 'start_longitude', type: 'double precision' })
  startLongitude: number;

  @Column({ name: 'start_elevation', type: 'double precision', nullable: true })
  startElevation: number | null;

  @Column({ name: 'end_latitude', type: 'double precision', nullable: true })
  endLatitude: number | null;

  @Column({ name: 'end_longitude', type: 'double precision', nullable: true })
  endLongitude: number | null;

  @Column({ name: 'end_elevation', type: 'double precision', nullable: true })
  endElevation: number | null;

  @Column({ name: 'elevation_delta', type: 'double precision', nullable: true })
  elevationDelta: number | null;

  @Column({ type: 'double precision', nullable: true })
  distance: number | null;

  @Column({
    name: 'distance_unit',
    type: 'varchar',
    length: 10,
    default: DistanceUnit.YARDS,
  })
  distanceUnit: DistanceUnit;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
