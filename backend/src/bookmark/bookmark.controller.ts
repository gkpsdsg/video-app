import {
  Controller,
  Post,
  Get,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { BookmarkService } from './bookmark.service';

@ApiTags('收藏')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class BookmarkController {
  constructor(private readonly bookmarkService: BookmarkService) {}

  @Post('bookmark/:videoId')
  @ApiOperation({ summary: '收藏/取消收藏' })
  toggleBookmark(@Param('videoId') videoId: string, @Req() req: any) {
    return this.bookmarkService.toggleBookmark(videoId, req.user.id);
  }

  @Get('bookmark/:videoId/status')
  @ApiOperation({ summary: '查看收藏状态' })
  getBookmarkStatus(@Param('videoId') videoId: string, @Req() req: any) {
    return this.bookmarkService.getBookmarkStatus(videoId, req.user.id);
  }

  @Get('bookmark/:videoId/count')
  @ApiOperation({ summary: '获取视频收藏数' })
  async getBookmarkCount(@Param('videoId') videoId: string) {
    const count = await this.bookmarkService.getBookmarkCount(videoId);
    return { count };
  }

  @Get('bookmarks')
  @ApiOperation({ summary: '获取我的收藏列表' })
  getUserBookmarks(
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.bookmarkService.getUserBookmarks(req.user.id, +page, +limit);
  }
}
