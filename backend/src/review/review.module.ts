import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { MinioModule } from '../minio/minio.module';
import { Review } from './review.entity';
import { Video } from '../video/video.entity';
import { ReviewService } from './review.service';
import { ReviewController } from './review.controller';
import { ReviewProcessor } from './review.processor';
import { AlibabaGreenService } from './alibaba-green.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Review, Video]),
    BullModule.registerQueue({ name: 'video' }),
    MinioModule,
  ],
  controllers: [ReviewController],
  providers: [ReviewService, ReviewProcessor, AlibabaGreenService],
  exports: [ReviewService],
})
export class ReviewModule {}
