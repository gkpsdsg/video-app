import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { RedisService } from '../redis/redis.service';
import { Video, VideoStatus } from '../video/video.entity';

@Injectable()
export class RankingService {
  private readonly HOT_KEY = 'hot:videos';

  constructor(
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    private redisService: RedisService,
  ) {}

  async getHotVideos(page: number = 1, limit: number = 20) {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const members = await this.redisService.zRangeWithScores(this.HOT_KEY, start, end, { REV: true });

    if (members.length === 0) {
      const [items, total] = await this.videoRepo.findAndCount({
        where: { status: VideoStatus.READY },
        relations: ['author'],
        order: { playCount: 'DESC' },
        skip: start,
        take: limit,
      });
      return { items, total, page, limit };
    }

    const videoIds = members.map((m: Record<string, unknown>) => m.value as string);
    const videos = await this.videoRepo.find({ where: { id: In(videoIds) }, relations: ['author'] });

    const videoMap = new Map(videos.map((v) => [v.id, v]));
    const sorted = videoIds.map((id: string) => videoMap.get(id)).filter(Boolean);

    return { items: sorted, total: members.length, page, limit };
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
