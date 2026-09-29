import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { GolfBagClub } from '../../golf-bag/entities/golf-bag-club.entity';
import { HandicapHistory } from '../../handicap/entities/handicap-history.entity';

export enum UserRole {
  USER = 'USER',
  ADMIN = 'ADMIN',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 20, default: UserRole.USER })
  role: UserRole;

  @Index('idx_users_email', { unique: true })
  @Column({ type: 'varchar', length: 255, unique: true })
  email: string;

  @Column({ type: 'varchar', length: 255, select: false })
  password_hash: string;

  @Column({ type: 'varchar', length: 255 })
  full_name: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  avatar_url: string;

  @Column({ type: 'decimal', precision: 4, scale: 1, nullable: true, default: 54.0 })
  handicap_index: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;

  @OneToMany(() => GolfBagClub, (club) => club.user, { cascade: true })
  clubs: GolfBagClub[];

  @OneToMany(() => HandicapHistory, (history) => history.user)
  handicapHistory: HandicapHistory[];
}
