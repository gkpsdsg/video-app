import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Like } from './like.entity';
import { Comment } from './comment.entity';
import { Follow } from './follow.entity';
import { Video } from '../video/video.entity';
import { Bookmark } from '../bookmark/bookmark.entity';
import { NotificationModule } from '../notification/notification.module';
import { SocialService } from './social.service';
import { SocialController } from './social.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Like, Comment, Follow, Video, Bookmark]),
    forwardRef(() => NotificationModule),
  ],
  controllers: [SocialController],
  providers: [SocialService],
  exports: [SocialService],
})
export class SocialModule {}
