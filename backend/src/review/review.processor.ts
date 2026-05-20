import { Processor, Process } from '@nestjs/bull';
import type { Job } from 'bull';
import { ReviewService } from './review.service';

@Processor('video')
export class ReviewProcessor {
  constructor(private readonly reviewService: ReviewService) {}

  @Process('auto-review')
  async handleAutoReview(job: Job<{ videoId: string; reviewId: string }>) {
    const { videoId, reviewId } = job.data;
    await this.reviewService.autoReview(videoId, reviewId);
  }
}
