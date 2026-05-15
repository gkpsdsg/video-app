import { Injectable, OnModuleInit } from '@nestjs/common';
import * as Minio from 'minio';

@Injectable()
export class MinioService implements OnModuleInit {
  private minioClient: Minio.Client;
  private readonly bucketName: string;

  constructor() {
    this.bucketName = process.env.MINIO_BUCKET || 'video-app';
  }

  onModuleInit() {
    const endPoint = process.env.MINIO_ENDPOINT || 'localhost';
    const port = parseInt(process.env.MINIO_PORT || '9000', 10);
    const useSSL = false;
    const accessKey = process.env.MINIO_ACCESS_KEY || 'minioadmin';
    const secretKey = process.env.MINIO_SECRET_KEY || 'minioadmin';

    this.minioClient = new Minio.Client({
      endPoint,
      port,
      useSSL,
      accessKey,
      secretKey,
    });

    void this.ensureBucket();
  }

  private async ensureBucket() {
    try {
      const exists = await this.minioClient.bucketExists(this.bucketName);
      if (!exists) {
        await this.minioClient.makeBucket(this.bucketName);
        console.log(`Bucket '${this.bucketName}' created`);
      } else {
        console.log(`Bucket '${this.bucketName}' already exists`);
      }
    } catch (error) {
      console.error('MinIO bucket error:', error);
    }
  }

  async testConnection() {
    try {
      const buckets = await this.minioClient.listBuckets();
      return {
        success: true,
        buckets: buckets.map((b) => b.name),
        defaultBucket: this.bucketName,
        bucketExists: await this.minioClient.bucketExists(this.bucketName),
      };
    } catch (error) {
      const err = error as Error;
      return {
        success: false,
        error: err.message,
      };
    }
  }

  async uploadFile(buffer: Buffer, fileName: string, mimeType: string) {
    // 修复：putObject 参数为 (bucket, name, stream, size, metaData)
    // 这里使用 buffer，需要指定大小和 metaData
    await this.minioClient.putObject(
      this.bucketName,
      fileName,
      buffer,
      buffer.length,
      {
        'Content-Type': mimeType,
      },
    );
    return fileName;
  }

  async getFileUrl(fileName: string, expiry = 3600) {
    return await this.minioClient.presignedUrl(
      'GET',
      this.bucketName,
      fileName,
      expiry,
    );
  }
}
