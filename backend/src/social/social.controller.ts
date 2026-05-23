import {
  Controller,
  Post,
  Get,
  Param,
  Query,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SocialService } from './social.service';

@ApiTags('互动')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @Post('like/:videoId')
  @ApiOperation({ summary: '点赞/取消点赞' })
  toggleLike(@Param('videoId') videoId: string, @Req() req: any) {
    return this.socialService.toggleLike(videoId, req.user.id);
  }

  @Get('like/:videoId/status')
  @ApiOperation({ summary: '查看点赞状态' })
  getLikeStatus(@Param('videoId') videoId: string, @Req() req: any) {
    return this.socialService.getLikeStatus(videoId, req.user.id);
  }

  @Post('batch-status')
  @ApiOperation({ summary: '批量查询点赞/收藏/关注状态及收藏数' })
  getBatchStatus(@Req() req: any, @Body('videoIds') videoIds: string[]) {
    return this.socialService.getBatchStatus(videoIds ?? [], req.user.id);
  }

  @Post('comment/:videoId')
  @ApiOperation({ summary: '发表评论' })
  addComment(
    @Param('videoId') videoId: string,
    @Req() req: any,
    @Body('content') content: string,
    @Body('parentId') parentId?: string,
  ) {
    return this.socialService.addComment(
      videoId,
      req.user.id,
      content,
      parentId,
    );
  }

  @Get('comment/:videoId')
  @ApiOperation({ summary: '获取评论列表' })
  getComments(
    @Param('videoId') videoId: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.socialService.getComments(videoId, +page, +limit);
  }

  @Post('follow/:userId')
  @ApiOperation({ summary: '关注/取消关注' })
  toggleFollow(@Param('userId') userId: string, @Req() req: any) {
    return this.socialService.toggleFollow(userId, req.user.id);
  }

  @Get('follow/:userId/status')
  @ApiOperation({ summary: '查看关注状态' })
  getFollowStatus(@Param('userId') userId: string, @Req() req: any) {
    return this.socialService.getFollowStatus(userId, req.user.id);
  }

  @Get('followers')
  @ApiOperation({ summary: '我的粉丝列表' })
  getFollowers(
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.socialService.getFollowers(req.user.id, +page, +limit);
  }

  @Get('following')
  @ApiOperation({ summary: '我关注的人列表' })
  getFollowing(
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.socialService.getFollowing(req.user.id, +page, +limit);
  }

  @Get('user/:id/likes')
  @ApiOperation({ summary: '获取用户点赞的视频' })
  getUserLikedVideos(
    @Param('id') userId: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.socialService.getUserLikedVideos(userId, +page, +limit);
  }
}
