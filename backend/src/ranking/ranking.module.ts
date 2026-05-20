import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Video } from '../video/video.entity';
import { RedisModule } from '../redis/redis.module';
import { RankingService } from './ranking.service';
import { RankingController } from './ranking.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Video]), RedisModule],
  controllers: [RankingController],
  providers: [RankingService],
})
export class RankingModule {}
