import { Module } from '@nestjs/common';
import { RedisService } from './redis.service';

@Module({
  providers: [RedisService],
  exports: [RedisService], // ← 添加这行，导出供其他模块使用
})
export class RedisModule {}
