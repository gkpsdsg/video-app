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
import { Video } from '../video/video.entity';

@Entity('likes')
@Unique(['userId', 'videoId'])
@Index(['videoId'])
@Index(['userId'])
export class Like {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  videoId: string;

  @ManyToOne(() => Video)
  @JoinColumn({ name: 'videoId' })
  video: Video;

  @CreateDateColumn()
  createdAt: Date;
}
