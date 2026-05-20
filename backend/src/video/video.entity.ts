import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../auth/user.entity';

export enum VideoStatus {
  UPLOADING = 'uploading',
  TRANSCODING = 'transcoding',
  READY = 'ready',
  FAILED = 'failed',
  BLOCKED = 'blocked',
}

@Entity('videos')
export class Video {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  description: string;

  @Column()
  originalFileName: string;

  @Column()
  minioObjectName: string;

  @Column({ nullable: true })
  coverObjectName: string;

  @Column('bigint', { default: 0 })
  fileSize: number;

  @Column({ nullable: true, type: 'float' })
  duration: number;

  @Column({ type: 'enum', enum: VideoStatus, default: VideoStatus.UPLOADING })
  status: VideoStatus;

  @Column({ default: 0 })
  playCount: number;

  @Column({ default: 0 })
  likeCount: number;

  @Column({ default: 0 })
  commentCount: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'authorId' })
  author: User;

  @Column()
  authorId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
