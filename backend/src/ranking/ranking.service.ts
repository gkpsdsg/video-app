import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { RedisService } from '../redis/redis.service';
import { Video, VideoStatus } from '../video/video.entity';
import { Follow } from '../social/follow.entity';

@Injectable()
export class RankingService {
  private readonly HOT_KEY = 'hot:videos';

  constructor(
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    @InjectRepository(Follow) private followRepo: Repository<Follow>,
    private redisService: RedisService,
  ) {}

  async getHotVideos(page: number = 1, limit: number = 20) {
    const hotCount = Math.floor(limit / 2);
    const randomCount = limit - hotCount;

    const [hotVideos, randomVideos, total] = await Promise.all([
      // Hot picks: random slice from Redis ZSET top 100
      (async () => {
        const members = await this.redisService.zRangeWithScores(this.HOT_KEY, 0, 99, { REV: true });
        const hotIds = members.map((m: Record<string, unknown>) => m.value as string);
        const shuffled = hotIds.sort(() => Math.random() - 0.5).slice(0, hotCount);
        if (shuffled.length === 0) return [];
        return this.videoRepo.find({
          where: { id: In(shuffled), status: VideoStatus.READY },
          relations: ['author'],
        });
      })(),
      // Random picks: DB-level random sample
      this.videoRepo
        .createQueryBuilder('v')
        .leftJoinAndSelect('v.author', 'author')
        .where('v.status = :status', { status: VideoStatus.READY })
        .orderBy('RANDOM()')
        .take(randomCount)
        .getMany(),
      this.videoRepo.count({ where: { status: VideoStatus.READY } }),
    ]);

    // Interleave: hot and random mixed evenly
    const hotQueue = [...hotVideos];
    const randQueue = [...randomVideos];
    const mixed: Video[] = [];
    for (let i = 0; i < limit; i++) {
      if (i % 2 === 0 && hotQueue.length > 0) {
        mixed.push(hotQueue.shift()!);
      } else if (randQueue.length > 0) {
        mixed.push(randQueue.shift()!);
      } else if (hotQueue.length > 0) {
        mixed.push(hotQueue.shift()!);
      }
    }

    return { items: mixed, total, page, limit };
  }

  async getFollowingVideos(userId: string, page: number = 1, limit: number = 20) {
    const follows = await this.followRepo.find({ where: { followerId: userId } });
    const followingIds = follows.map((f) => f.followingId);

    if (followingIds.length === 0) {
      return { items: [], total: 0, page, limit };
    }

    const [items, total] = await this.videoRepo.findAndCount({
      where: { authorId: In(followingIds), status: VideoStatus.READY },
      relations: ['author'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  @Cron('*/30 * * * *')
  async updateHotRanking() {
    const videos = await this.videoRepo.find({
      where: { status: VideoStatus.READY },
    });

    const now = Date.now();

    const members: { score: number; value: string }[] = [];

    for (const video of videos) {
      const ageHours = (now - video.createdAt.getTime()) / (1000 * 3600);
      const heatScore =
        video.playCount * 1 + video.likeCount * 2 + video.commentCount * 5;
      const timeDecay = Math.pow(ageHours + 2, 1.5);
      members.push({ score: heatScore / timeDecay, value: video.id });
    }

    await this.redisService.zAddMany(this.HOT_KEY, members);
  }
}
