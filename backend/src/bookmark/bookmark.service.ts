import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Bookmark } from './bookmark.entity';

@Injectable()
export class BookmarkService {
  constructor(
    @InjectRepository(Bookmark) private bookmarkRepo: Repository<Bookmark>,
  ) {}

  async toggleBookmark(videoId: string, userId: string) {
    const existing = await this.bookmarkRepo.findOne({ where: { videoId, userId } });
    if (existing) {
      await this.bookmarkRepo.remove(existing);
      return { bookmarked: false };
    }
    await this.bookmarkRepo.save({ videoId, userId });
    return { bookmarked: true };
  }

  async getBookmarkStatus(videoId: string, userId: string) {
    const existing = await this.bookmarkRepo.findOne({ where: { videoId, userId } });
    return { bookmarked: !!existing };
  }

  async getBookmarkCount(videoId: string) {
    return this.bookmarkRepo.count({ where: { videoId } });
  }

  async getUserBookmarks(userId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.bookmarkRepo.findAndCount({
      where: { userId },
      relations: ['video', 'video.author'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }
}
