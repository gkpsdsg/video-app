import { Processor, Process } from '@nestjs/bull';
import type { Job } from 'bull';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Video, VideoStatus } from './video.entity';
import { MinioService } from '../minio/minio.service';

const execAsync = promisify(exec);

@Processor('video')
export class TranscodeProcessor {
  constructor(
    @InjectRepository(Video) private videoRepo: Repository<Video>,
    private minioService: MinioService,
  ) {}

  @Process('transcode')
  async handleTranscode(job: Job<{ videoId: string }>) {
    const { videoId } = job.data;
    const video = await this.videoRepo.findOne({ where: { id: videoId } });
    if (!video) return;

    const tmpDir = os.tmpdir();
    const inputPath = path.join(tmpDir, `${videoId}_input`);
    const outputPath = path.join(tmpDir, `${videoId}_output.mp4`);
    const coverPath = path.join(tmpDir, `${videoId}_cover.jpg`);

    try {
      video.status = VideoStatus.TRANSCODING;
      await this.videoRepo.save(video);

      const downloadUrl = await this.minioService.getFileUrl(
        video.minioObjectName,
      );
      const response = await fetch(downloadUrl);
      const buffer = Buffer.from(await response.arrayBuffer());
      await fs.writeFile(inputPath, buffer);

      await execAsync(
        `ffmpeg -i "${inputPath}" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart "${outputPath}"`,
      );

      await execAsync(
        `ffmpeg -i "${outputPath}" -vframes 1 -q:v 2 "${coverPath}"`,
      );

      const { stdout } = await execAsync(
        `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${outputPath}"`,
      );

      const outputBuffer = await fs.readFile(outputPath);
      await this.minioService.uploadFile(
        outputBuffer,
        video.minioObjectName,
        'video/mp4',
      );

      const coverBuffer = await fs.readFile(coverPath);
      const coverName = `covers/${videoId}.jpg`;
      await this.minioService.uploadFile(coverBuffer, coverName, 'image/jpeg');

      video.status = VideoStatus.READY;
      video.duration = Math.round(parseFloat(stdout.trim()));
      video.coverObjectName = coverName;
      video.fileSize = outputBuffer.length;
      await this.videoRepo.save(video);
    } catch (error) {
      video.status = VideoStatus.FAILED;
      await this.videoRepo.save(video);
      console.error(`视频 ${videoId} 转码失败:`, error);
      throw error;
    } finally {
      await Promise.all(
        [inputPath, outputPath, coverPath].map(async (p) => {
          try {
            await fs.unlink(p);
          } catch (_) {}
        }),
      );
    }
  }
}
