import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { v4 as uuidv4 } from 'uuid';
import { MinioService } from '../minio/minio.service';
import { Video, VideoStatus, VideoVisibility } from './video.entity';
import { Comment } from '../social/comment.entity';
import { Like } from '../social/like.entity';
import { Bookmark } from '../bookmark/bookmark.entity';

@Injectable()
export class VideoService {
  constructor(
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    @InjectRepository(Comment) private commentRepo: Repository<Comment>,
    @InjectRepository(Like) private likeRepo: Repository<Like>,
    @InjectRepository(Bookmark) private bookmarkRepo: Repository<Bookmark>,
    @InjectQueue('video') private videoQueue: Queue,
    private minioService: MinioService,
  ) {}

  async upload(file: Express.Multer.File, title: string, authorId: string) {
    const ext = file.originalname.split('.').pop() || 'mp4';
    const objectName = `videos/${uuidv4()}.${ext}`;

    await this.minioService.uploadFile(file.buffer, objectName, file.mimetype);

    const video = this.videoRepo.create({
      title,
      originalFileName: file.originalname,
      minioObjectName: objectName,
      fileSize: file.size,
      authorId,
      status: VideoStatus.UPLOADING,
    });
    await this.videoRepo.save(video);

    await this.videoQueue.add('transcode', { videoId: video.id });

    return video;
  }

  async findAll(page: number = 1, limit: number = 20) {
    const [items, total] = await this.videoRepo.findAndCount({
      where: { status: VideoStatus.READY, visibility: VideoVisibility.PUBLIC },
      relations: ['author'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findOne(id: string) {
    const video = await this.videoRepo.findOne({
      where: { id },
      relations: ['author'],
    });
    if (!video) throw new NotFoundException('视频不存在');
    return video;
  }

  async getStreamUrl(id: string) {
    const video = await this.findOne(id);
    const url = await this.minioService.getFileUrl(video.minioObjectName);
    return { url, video };
  }

  async getCoverUrl(id: string) {
    const video = await this.videoRepo.findOne({ where: { id } });
    if (!video || !video.coverObjectName) {
      throw new NotFoundException('封面不存在');
    }
    const url = await this.minioService.getFileUrl(video.coverObjectName);
    return { url };
  }

  async findByUser(authorId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.videoRepo.findAndCount({
      where: { authorId, status: VideoStatus.READY },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateVisibility(
    id: string,
    userId: string,
    role: string,
    visibility: VideoVisibility,
  ) {
    const video = await this.videoRepo.findOne({ where: { id } });
    if (!video) throw new NotFoundException('视频不存在');
    if (video.authorId !== userId && role !== 'admin') {
      throw new ForbiddenException('无权修改此视频');
    }
    await this.videoRepo.update(id, { visibility });
    return { id, visibility };
  }

  async delete(id: string, userId: string, role: string) {
    const video = await this.videoRepo.findOne({ where: { id } });
    if (!video) throw new NotFoundException('视频不存在');

    if (video.authorId !== userId && role !== 'admin') {
      throw new ForbiddenException('无权删除此视频');
    }

    // Delete from MinIO
    await Promise.all([
      this.minioService.deleteFile(video.minioObjectName).catch(() => {}),
      video.coverObjectName
        ? this.minioService.deleteFile(video.coverObjectName).catch(() => {})
        : Promise.resolve(),
    ]);

    await Promise.all([
      this.commentRepo.delete({ videoId: id }),
      this.likeRepo.delete({ videoId: id }),
      this.bookmarkRepo.delete({ videoId: id }),
    ]);

    // Delete the video record
    await this.videoRepo.remove(video);

    return { deleted: true };
  }
}
