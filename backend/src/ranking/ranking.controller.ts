import { Controller, Get, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RankingService } from './ranking.service';

@ApiTags('推荐')
@Controller('feed')
export class RankingController {
  constructor(private readonly rankingService: RankingService) {}

  @Get('hot')
  @ApiOperation({ summary: '热门视频 Feed（热度排序）' })
  getHotVideos(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.rankingService.getHotVideos(+page, +limit);
  }

  @Get('following')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '关注用户视频 Feed' })
  getFollowingVideos(
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.rankingService.getFollowingVideos(req.user.id, +page, +limit);
  }
}
