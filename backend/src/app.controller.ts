import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { RedisService } from './redis/redis.service';
import { MinioService } from './minio/minio.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly redisService: RedisService,
    private readonly minioService: MinioService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  getHealth(): { status: string; timestamp: string } {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('test/redis')
  async testRedis() {
    try {
      const pong = await this.redisService.ping();
      await this.redisService.set('test-key', 'hello-redis', 60);
      const value = await this.redisService.get('test-key');
      return {
        success: true,
        ping: pong,
        setGetTest: value,
        message: 'Redis is working!',
      };
    } catch (error) {
      const err = error as Error;
      return { success: false, error: err.message };
    }
  }

  @Get('test/minio')
  async testMinio() {
    const result = await this.minioService.testConnection();
    return result;
  }

  @Get('test/all')
  async testAll() {
    const [redisTest, minioTest] = await Promise.all([
      this.testRedis(),
      this.testMinio(),
    ]);

    return {
      redis: redisTest,
      minio: minioTest,
      postgres: 'TypeORM connection should be verified via app startup logs',
      overall:
        redisTest.success && minioTest.success
          ? 'All services ready!'
          : 'Some services failed',
    };
  }
}
