import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { Review } from './review.entity';
import { Video, VideoStatus } from '../video/video.entity';
import { MinioService } from '../minio/minio.service';
import { AlibabaGreenService } from './alibaba-green.service';

@Injectable()
export class ReviewService {
  constructor(
    @InjectRepository(Review) private reviewRepo: Repository<Review>,
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    @InjectQueue('video') private videoQueue: Queue,
    private minioService: MinioService,
    private alibabaGreenService: AlibabaGreenService,
  ) {}

  async submitForReview(videoId: string) {
    const review = this.reviewRepo.create({ videoId, status: 'pending', reviewType: 'auto' });
    await this.reviewRepo.save(review);
    await this.videoQueue.add('auto-review', { videoId, reviewId: review.id });
    return review;
  }

  async autoReview(videoId: string, reviewId: string) {
    const video = await this.videoRepo.findOne({ where: { id: videoId } });
    if (!video) {
      await this.reviewRepo.update(reviewId, { status: 'rejected', reason: '视频不存在' });
      return { passed: false, reviewId, reason: '视频不存在' };
    }

    try {
      const videoUrl = await this.minioService.getFileUrl(video.minioObjectName, 3600);

      console.log(`[审核] 提交视频到阿里云内容安全: ${videoId} URL: ${videoUrl.substring(0, 80)}...`);

      const { taskId } = await this.alibabaGreenService.videoAsyncScan(videoUrl, videoId);
      console.log(`[审核] 阿里云返回 taskId: ${taskId}`);

      // Poll for results (retry up to 5 times, 3s interval)
      let result = { passed: false, reason: '审核超时' };
      for (let i = 0; i < 5; i++) {
        await new Promise((r) => setTimeout(r, 3000));
        result = await this.alibabaGreenService.getVideoResults(taskId);
        if (result.reason !== '审核处理中' && result.reason !== '审核查询中') break;
      }

      console.log(`[审核] 结果 videoId=${videoId}: passed=${result.passed} reason=${result.reason}`);

      if (result.passed) {
        await this.reviewRepo.update(reviewId, { status: 'passed', reason: '机审通过' });
        await this.videoRepo.update(videoId, { status: VideoStatus.READY });
      } else {
        await this.reviewRepo.update(reviewId, { status: 'pending', reviewType: 'manual', reason: result.reason || '机审未通过' });
        await this.videoRepo.update(videoId, { status: VideoStatus.BLOCKED });
      }

      return { passed: result.passed, reviewId, reason: result.reason };
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : String(error);
      console.error(`[审核] 阿里云 API 调用失败:`, msg);

      // Fail closed: require manual review on API failure
      await this.reviewRepo.update(reviewId, { status: 'pending', reviewType: 'manual', reason: '机审API不可用，等待人工审核' });
      await this.videoRepo.update(videoId, { status: VideoStatus.BLOCKED });

      return { passed: false, reviewId };
    }
  }

  async manualReview(reviewId: string, passed: boolean, reason?: string) {
    const review = await this.reviewRepo.findOne({ where: { id: reviewId } });
    if (!review) throw new Error('审核记录不存在');

    review.status = passed ? 'passed' : 'rejected';
    review.reason = reason || (passed ? '人工审核通过' : '人工审核拒绝');
    review.reviewType = 'manual';
    await this.reviewRepo.save(review);

    await this.videoRepo.update(review.videoId, {
      status: passed ? VideoStatus.READY : VideoStatus.BLOCKED,
    });

    return review;
  }

  async getPendingReviews() {
    return this.reviewRepo.find({
      where: { status: 'pending', reviewType: 'manual' },
      relations: ['video', 'video.author'],
      order: { createdAt: 'ASC' },
    });
  }
}
