import { Injectable, NotFoundException, BadRequestException, Inject, forwardRef, Optional } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Like } from './like.entity';
import { Comment } from './comment.entity';
import { Follow } from './follow.entity';
import { Video } from '../video/video.entity';
import { NotificationService } from '../notification/notification.service';
import { NotificationType } from '../notification/notification.entity';

@Injectable()
export class SocialService {
  constructor(
    @InjectRepository(Like) private likeRepo: Repository<Like>,
    @InjectRepository(Comment) private commentRepo: Repository<Comment>,
    @InjectRepository(Follow) private followRepo: Repository<Follow>,
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    @Optional() @Inject(forwardRef(() => NotificationService)) private notificationService?: NotificationService,
  ) {}

  // ── Like ──

  async toggleLike(videoId: string, userId: string) {
    const existing = await this.likeRepo.findOne({ where: { videoId, userId } });
    if (existing) {
      await this.likeRepo.remove(existing);
      await this.videoRepo.decrement({ id: videoId }, 'likeCount', 1);
      return { liked: false };
    }
    await this.likeRepo.save({ videoId, userId });
    await this.videoRepo.increment({ id: videoId }, 'likeCount', 1);

    // Trigger notification
    const video = await this.videoRepo.findOne({ where: { id: videoId } });
    if (video && video.authorId !== userId && this.notificationService) {
      await this.notificationService.create(video.authorId, userId, NotificationType.LIKE, videoId);
    }

    return { liked: true };
  }

  async getLikeStatus(videoId: string, userId: string) {
    const existing = await this.likeRepo.findOne({ where: { videoId, userId } });
    return { liked: !!existing };
  }

  // ── Comment ──

  async addComment(videoId: string, userId: string, content: string, parentId?: string) {
    let parentAuthorId: string | undefined;
    if (parentId) {
      const parent = await this.commentRepo.findOne({ where: { id: parentId } });
      if (!parent) throw new NotFoundException('父评论不存在');
      parentAuthorId = parent.userId;
    }
    const comment = this.commentRepo.create({ videoId, userId, content, parentId });
    await this.commentRepo.save(comment);
    await this.videoRepo.increment({ id: videoId }, 'commentCount', 1);

    // Trigger notification: reply → parent comment author; top-level → video author
    if (this.notificationService) {
      if (parentAuthorId && parentAuthorId !== userId) {
        await this.notificationService.create(parentAuthorId, userId, NotificationType.COMMENT, videoId);
      } else if (!parentAuthorId) {
        const video = await this.videoRepo.findOne({ where: { id: videoId } });
        if (video && video.authorId !== userId) {
          await this.notificationService.create(video.authorId, userId, NotificationType.COMMENT, videoId);
        }
      }
    }

    return this.commentRepo.findOne({
      where: { id: comment.id },
      relations: ['user', 'parent'],
    });
  }

  async getComments(videoId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.commentRepo.findAndCount({
      where: { videoId, parentId: null as any },
      relations: ['user', 'children', 'children.user'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  // ── Follow ──

  async toggleFollow(followingId: string, followerId: string) {
    if (followingId === followerId) {
      throw new BadRequestException('不能关注自己');
    }
    const existing = await this.followRepo.findOne({
      where: { followerId, followingId },
    });
    if (existing) {
      await this.followRepo.remove(existing);
      return { following: false };
    }
    await this.followRepo.save({ followerId, followingId });

    // Trigger notification
    if (this.notificationService) {
      await this.notificationService.create(followingId, followerId, NotificationType.FOLLOW);
    }

    return { following: true };
  }

  async getFollowStatus(followingId: string, followerId: string) {
    const existing = await this.followRepo.findOne({
      where: { followerId, followingId },
    });
    return { following: !!existing };
  }

  async getFollowers(userId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.followRepo.findAndCount({
      where: { followingId: userId },
      relations: ['follower'],
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit };
  }

  async getFollowing(userId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.followRepo.findAndCount({
      where: { followerId: userId },
      relations: ['following'],
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit };
  }

  async getUserStats(userId: string) {
    const [followerCount, followingCount] = await Promise.all([
      this.followRepo.count({ where: { followingId: userId } }),
      this.followRepo.count({ where: { followerId: userId } }),
    ]);
    return { followerCount, followingCount };
  }

  async getUserLikedVideos(userId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.likeRepo.findAndCount({
      where: { userId },
      relations: ['video', 'video.author'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }
}
