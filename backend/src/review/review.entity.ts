import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Video } from '../video/video.entity';

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Video)
  @JoinColumn({ name: 'videoId' })
  video: Video;

  @Column()
  videoId: string;

  @Column({ type: 'enum', enum: ['pending', 'passed', 'rejected'], default: 'pending' })
  status: string;

  @Column({ nullable: true })
  reason: string;

  @Column({ type: 'enum', enum: ['auto', 'manual'], default: 'auto' })
  reviewType: string;

  @CreateDateColumn()
  createdAt: Date;
}
