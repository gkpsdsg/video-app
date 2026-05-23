import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from 'redis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: ReturnType<typeof createClient>;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    const host = this.configService.get<string>('REDIS_HOST');
    const port = this.configService.get<string>('REDIS_PORT');
    this.client = createClient({ url: `redis://${host}:${port}` });

    this.client.on('error', (err) => console.error('Redis Client Error', err));
    await this.client.connect();
    console.log('Redis connected successfully');
  }

  async onModuleDestroy() {
    await this.client.quit();
    console.log('Redis disconnected');
  }

  async set(key: string, value: string, ttl?: number) {
    if (ttl !== undefined) {
      await this.client.setEx(key, ttl, value);
    } else {
      await this.client.set(key, value);
    }
  }

  async get(key: string): Promise<string | null> {
    return await this.client.get(key);
  }

  async del(key: string) {
    await this.client.del(key);
  }

  async ping(): Promise<string> {
    return await this.client.ping();
  }

  async zAdd(key: string, value: string, score: number) {
    await this.client.zAdd(key, { score, value });
  }

  async zRangeWithScores(
    key: string,
    start: number,
    end: number,
    options?: { REV: boolean },
  ) {
    return this.client.zRangeWithScores(key, start, end, options);
  }

  async zAddMany(key: string, members: { score: number; value: string }[]) {
    if (members.length === 0) return;
    await this.client.zAdd(key, members);
  }

  async incr(key: string) {
    return this.client.incr(key);
  }
}
