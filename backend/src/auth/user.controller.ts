import {
  Controller,
  Get,
  Put,
  Param,
  Query,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from './jwt-auth.guard';
import { User } from './user.entity';
import { Video, VideoStatus, VideoVisibility } from '../video/video.entity';
import { Follow } from '../social/follow.entity';

@ApiTags('用户')
@Controller('user')
export class UserController {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    @InjectRepository(Follow) private followRepo: Repository<Follow>,
  ) {}

  @Get(':id/profile')
  @ApiOperation({ summary: '获取用户公开信息' })
  async getProfile(@Param('id') id: string) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) return null;

    const [videoCount, totalLikesResult, followerCount, followingCount] =
      await Promise.all([
        this.videoRepo.count({
          where: { authorId: id, status: VideoStatus.READY },
        }),
        this.videoRepo
          .createQueryBuilder('video')
          .select('COALESCE(SUM(video.likeCount), 0)', 'total')
          .where('video.authorId = :id', { id })
          .getRawOne(),
        this.followRepo.count({ where: { followingId: id } }),
        this.followRepo.count({ where: { followerId: id } }),
      ]);

    return {
      id: user.id,
      username: user.username,
      nickname: user.nickname,
      avatar: user.avatar,
      videoCount,
      followerCount,
      followingCount,
      totalLikes: parseInt(totalLikesResult?.total || '0', 10),
      createdAt: user.createdAt,
    };
  }

  @Get(':id/videos')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '获取用户的视频列表' })
  async getUserVideos(
    @Param('id') id: string,
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    const where: any = { authorId: id, status: VideoStatus.READY };
    // Show private videos only to the owner
    if (req.user?.id !== id) {
      where.visibility = VideoVisibility.PUBLIC;
    }
    const [items, total] = await this.videoRepo.findAndCount({
      where,
      relations: ['author'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  @Put('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '编辑个人资料（昵称/头像）' })
  async updateProfile(
    @Req() req: any,
    @Body('nickname') nickname?: string,
    @Body('avatar') avatar?: string,
  ) {
    const updateData: any = {};
    if (nickname !== undefined) updateData.nickname = nickname;
    if (avatar !== undefined) updateData.avatar = avatar;
    await this.userRepo.update(req.user.id, updateData);
    return this.userRepo.findOne({ where: { id: req.user.id } });
  }
}
