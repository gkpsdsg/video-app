import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ReviewService } from './review.service';

@ApiTags('审核')
@Controller('review')
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @Post('submit/:videoId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '提交视频审核' })
  submitForReview(@Param('videoId') videoId: string) {
    return this.reviewService.submitForReview(videoId);
  }

  @Get('pending')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '获取待审核列表（管理员）' })
  getPendingReviews() {
    return this.reviewService.getPendingReviews();
  }

  @Post('approve/:reviewId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '人工审核通过/拒绝' })
  manualReview(
    @Param('reviewId') reviewId: string,
    @Body('passed') passed: boolean,
    @Body('reason') reason?: string,
  ) {
    return this.reviewService.manualReview(reviewId, passed, reason);
  }
}
