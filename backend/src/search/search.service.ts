import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Video, VideoStatus } from '../video/video.entity';

@Injectable()
export class SearchService {
  constructor(
    @InjectRepository(Video) private videoRepo: Repository<Video>,
  ) {}

  async search(keyword: string, page: number = 1, limit: number = 20) {
    if (!keyword || keyword.trim().length === 0) {
      return { items: [], total: 0, page, limit };
    }

    const queryBuilder = this.videoRepo
      .createQueryBuilder('video')
      .leftJoinAndSelect('video.author', 'author')
      .where('video.status = :status', { status: VideoStatus.READY })
      .andWhere(
        '(video.title ILIKE :keyword OR video.description ILIKE :keyword)',
        { keyword: `%${keyword.trim()}%` },
      )
      .orderBy('video.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    const [items, total] = await queryBuilder.getManyAndCount();
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }
}
