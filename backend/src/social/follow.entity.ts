import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
  Index,
} from 'typeorm';
import { User } from '../auth/user.entity';

@Entity('follows')
@Unique(['followerId', 'followingId'])
@Index(['followerId'])
@Index(['followingId'])
export class Follow {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  followerId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'followerId' })
  follower: User;

  @Column()
  followingId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'followingId' })
  following: User;

  @CreateDateColumn()
  createdAt: Date;
}
