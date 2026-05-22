import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { MinioModule } from '../minio/minio.module';
import { Video } from './video.entity';
import { VideoService } from './video.service';
import { VideoController } from './video.controller';
import { TranscodeProcessor } from './transcode.processor';
import { Comment } from '../social/comment.entity';
import { Like } from '../social/like.entity';
import { Bookmark } from '../bookmark/bookmark.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Video, Comment, Like, Bookmark]),
    BullModule.registerQueue({ name: 'video' }),
    MinioModule,
  ],
  controllers: [VideoController],
  providers: [VideoService, TranscodeProcessor],
  exports: [VideoService],
})
export class VideoModule {}
