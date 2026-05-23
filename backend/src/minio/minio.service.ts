import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';

@Injectable()
export class MinioService implements OnModuleInit {
  private minioClient: Minio.Client;
  private readonly bucketName: string;

  constructor(private configService: ConfigService) {
    this.bucketName = configService.get<string>('MINIO_BUCKET') || 'video-app';
  }

  onModuleInit() {
    const endPoint =
      this.configService.get<string>('MINIO_ENDPOINT') || 'localhost';
    const port = this.configService.get<number>('MINIO_PORT') || 9000;
    const accessKey =
      this.configService.get<string>('MINIO_ACCESS_KEY') || 'minioadmin';
    const secretKey =
      this.configService.get<string>('MINIO_SECRET_KEY') || 'minioadmin';

    this.minioClient = new Minio.Client({
      endPoint,
      port,
      useSSL: false,
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

  async deleteFile(fileName: string) {
    await this.minioClient.removeObject(this.bucketName, fileName);
  }
}
