import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { RankingService } from './ranking.service';

@ApiTags('推荐')
@Controller('feed')
export class RankingController {
  constructor(private readonly rankingService: RankingService) {}

  @Get('hot')
  @ApiOperation({ summary: '热门视频 Feed（热度排序）' })
  getHotVideos(@Query('page') page: number = 1, @Query('limit') limit: number = 20) {
    return this.rankingService.getHotVideos(+page, +limit);
  }
}
