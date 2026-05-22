import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from './app.module';
import { AuthService } from './auth/auth.service';
import { MinioService } from './minio/minio.service';
import { Video, VideoStatus } from './video/video.entity';
import { User } from './auth/user.entity';
import { SocialService } from './social/social.service';
import { get } from 'https';
import { v4 as uuidv4 } from 'uuid';

// Public domain short test videos
const TEST_VIDEOS = [
  { title: '海浪拍岸·治愈系海景', url: 'https://www.w3schools.com/html/mov_bbb.mp4' },
  { title: '城市夜景延时摄影', url: 'https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4' },
  { title: '森林小溪·自然白噪音', url: 'https://files.testfile.org/Video%20MP4%2050MB-1.mp4' },
];

const TEST_USERS = [
  { username: 'admin', password: 'admin123', nickname: '管理员', role: 'admin' },
  { username: 'traveler', password: '123456', nickname: '旅行者小A', role: 'user' },
  { username: 'foodie', password: '123456', nickname: '美食探店家', role: 'user' },
  { username: 'musician', password: '123456', nickname: '音乐达人', role: 'user' },
  { username: 'athlete', password: '123456', nickname: '运动健身', role: 'user' },
  { username: 'geek', password: '123456', nickname: '科技极客', role: 'user' },
];

function downloadFile(url: string): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    console.log(`  ↓ Downloading: ${url.split('/').pop()} ...`);
    get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(downloadFile(res.headers.location));
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode}`));
      }
      const chunks: Buffer[] = [];
      res.on('data', (chunk: Buffer) => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    }).on('error', reject);
  });
}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const authService = app.get(AuthService);
  const minioService = app.get(MinioService);
  const socialService = app.get(SocialService);
  const videoRepo: Repository<Video> = app.get(getRepositoryToken(Video));
  const userRepo: Repository<User> = app.get(getRepositoryToken(User));

  console.log('\n🌱 Starting database seed...\n');

  // 1. Create test users
  console.log('📝 Creating test users...');
  const users: User[] = [];
  for (const u of TEST_USERS) {
    try {
      await authService.register(u);
      const created = await userRepo.findOne({ where: { username: u.username } });
      if (created) {
        if (u.role === 'admin') {
          created.role = 'admin';
          await userRepo.save(created);
        }
        users.push(created);
      }
      console.log(`  ✓ ${u.nickname} (@${u.username})${u.role === 'admin' ? ' ⚡admin' : ''}`);
    } catch {
      const existing = await userRepo.findOne({ where: { username: u.username } });
      if (existing) {
        users.push(existing);
        console.log(`  • ${u.nickname} (@${u.username}) — already exists`);
      }
    }
  }

  // 2. Download sample videos and upload to MinIO
  console.log('\n🎬 Seeding test videos...');
  let videoCount = 0;
  const createdVideos: Video[] = [];

  for (let i = 0; i < users.length; i++) {
    const user = users[i];
    const cfg = TEST_VIDEOS[i % TEST_VIDEOS.length];

    try {
      const buffer = await downloadFile(cfg.url);
      const objectName = `videos/seed-${uuidv4()}.mp4`;

      await minioService.uploadFile(buffer, objectName, 'video/mp4');

      const video = videoRepo.create({
        title: cfg.title,
        originalFileName: `seed-video-${i + 1}.mp4`,
        minioObjectName: objectName,
        fileSize: buffer.length,
        authorId: user.id,
        status: VideoStatus.READY,
        duration: 15 + i * 3,
        playCount: Math.floor(Math.random() * 5000) + 800,
        likeCount: Math.floor(Math.random() * 300) + 20,
        commentCount: 0,
      });
      await videoRepo.save(video);
      createdVideos.push(video);
      console.log(`  ✓ "${cfg.title}" by @${user.username} (${(buffer.length / 1024 / 1024).toFixed(1)}MB)`);
      videoCount++;
    } catch (e: any) {
      console.log(`  ✗ @${user.username}: ${e.message}`);
    }
  }

  // 3. Seed follows between users
  console.log('\n👥 Creating follow relationships...');
  for (let i = 0; i < users.length; i++) {
    for (let j = 0; j < users.length; j++) {
      if (i === j) continue;
      try {
        await socialService.toggleFollow(users[j].id, users[i].id);
      } catch {}
    }
  }
  console.log(`  ✓ Created follow mesh for ${users.length} users`);

  // 4. Seed likes on videos
  console.log('\n❤️  Seeding likes...');
  let likeCount = 0;
  for (const video of createdVideos) {
    for (const user of users) {
      if (user.id === video.authorId) continue;
      if (Math.random() > 0.6) {
        try {
          await socialService.toggleLike(video.id, user.id);
          likeCount++;
        } catch {}
      }
    }
  }
  console.log(`  ✓ ${likeCount} likes created`);

  // 5. Seed comments (top-level + replies)
  console.log('\n💬 Seeding comments...');
  const commentTexts = [
    '太美了！这是在哪里拍的？',
    '求背景音乐！',
    '已关注，期待更多作品',
    '这个色调绝了',
    '看了一遍又一遍',
    '好想去这里旅行',
    '拍得真好👍',
    '请问是用什么设备拍的？',
    '太治愈了',
    '收藏了！',
  ];
  const replyTexts = [
    '谢谢支持！',
    '在云南大理拍的哦',
    '用iPhone拍的',
    '感谢喜欢~',
    '下次会出教程',
  ];

  let commentCount = 0;
  for (const video of createdVideos) {
    // Top-level comments from random users
    for (const user of users) {
      if (user.id === video.authorId) continue;
      if (Math.random() > 0.5) {
        const content = commentTexts[Math.floor(Math.random() * commentTexts.length)];
        try {
          const comment = await socialService.addComment(video.id, user.id, content);
          if (!comment) continue;
          commentCount++;

          // Video author replies to some comments
          if (Math.random() > 0.4) {
            const reply = replyTexts[Math.floor(Math.random() * replyTexts.length)];
            await socialService.addComment(video.id, video.authorId, reply, comment.id);
            commentCount++;
          }
        } catch {}
      }
    }
  }
  console.log(`  ✓ ${commentCount} comments created`);

  // 6. Update comment counts
  console.log('\n📊 Updating video stats...');
  for (const video of createdVideos) {
    const stats = await socialService.getComments(video.id);
    video.commentCount = stats.total;
    await videoRepo.save(video);
  }
  console.log('  ✓ Stats updated');

  console.log(`\n✅ Seed complete!`);
  console.log(`   ${users.length} users, ${videoCount} videos, ${likeCount} likes, ${commentCount} comments`);
  console.log(`   Login: any @username above, password: 123456\n`);

  await app.close();
  process.exit(0);
}

bootstrap().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
