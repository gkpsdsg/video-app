import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { RedisService } from './redis/redis.service';
import { MinioService } from './minio/minio.service';

describe('AppController', () => {
  let appController: AppController;

  const mockRedisService = {
    ping: jest.fn().mockResolvedValue('PONG'),
    set: jest.fn().mockResolvedValue('OK'),
    get: jest.fn().mockResolvedValue('hello-redis'),
    del: jest.fn().mockResolvedValue(1),
  };

  const mockMinioService = {
    testConnection: jest.fn().mockResolvedValue({ success: true, buckets: [] }),
    uploadFile: jest.fn().mockResolvedValue('file.mp4'),
    getFileUrl: jest
      .fn()
      .mockResolvedValue('http://localhost:9000/video-app/file.mp4'),
  };

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        { provide: RedisService, useValue: mockRedisService },
        { provide: MinioService, useValue: mockMinioService },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(appController.getHello()).toBe('Hello World!');
    });
  });

  describe('health', () => {
    it('should return status ok', () => {
      const result = appController.getHealth();
      expect(result.status).toBe('ok');
      expect(result.timestamp).toBeDefined();
    });
  });

  describe('testRedis', () => {
    it('should return redis connection success', async () => {
      const result = await appController.testRedis();
      expect(result.success).toBe(true);
      expect(result.ping).toBe('PONG');
    });
  });

  describe('testMinio', () => {
    it('should return minio connection success', async () => {
      const result = await appController.testMinio();
      expect(result.success).toBe(true);
    });
  });
});
