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

    // 1. Fetch hot-ranked video IDs from Redis
    const members = await this.redisService.zRangeWithScores(this.HOT_KEY, 0, 99, { REV: true });
    const hotIds = members.map((m: Record<string, unknown>) => m.value as string);

    // 2. Pick a random slice of hot videos (different each call, even on page 1)
    const shuffledHot = hotIds.sort(() => Math.random() - 0.5);
    const pickedHot = shuffledHot.slice(0, hotCount);

    // 3. Fetch random videos from DB (excluding hot picks)
    const allVideos = await this.videoRepo.find({
      where: { status: VideoStatus.READY },
      relations: ['author'],
    });

    const hotSet = new Set(pickedHot);
    const nonHot = allVideos.filter((v) => !hotSet.has(v.id));
    const shuffledNonHot = nonHot.sort(() => Math.random() - 0.5);
    const pickedRandom = shuffledNonHot.slice(0, randomCount);

    // 4. Combine hot videos with their full data
    const hotVideos = allVideos.filter((v) => hotSet.has(v.id));
    const hotMap = new Map(hotVideos.map((v) => [v.id, v]));
    const hotSorted = pickedHot.map((id) => hotMap.get(id)).filter(Boolean);

    // 5. Interleave: hot and random mixed evenly
    const mixed: Video[] = [];
    for (let i = 0; i < limit; i++) {
      if (i % 2 === 0 && hotSorted.length > 0) {
        mixed.push(hotSorted.shift()!);
      } else if (pickedRandom.length > 0) {
        mixed.push(pickedRandom.shift()!);
      } else if (hotSorted.length > 0) {
        mixed.push(hotSorted.shift()!);
      }
    }

    return { items: mixed, total: allVideos.length, page, limit };
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
