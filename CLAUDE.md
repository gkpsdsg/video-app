# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A short-video application (类似抖音/快手) with a NestJS backend and Flutter frontend. Uses Docker Compose for local infrastructure (PostgreSQL, Redis, MinIO).

### Module Priority Order

| # | Module | Status |
|---|--------|--------|
| 1 | 账号体系 (Auth: register/login/JWT) | 依赖已装，逻辑待实现 |
| 2 | 视频上传及存储 (Upload → MinIO → transcode) | 依赖已装，逻辑待实现 |
| 3 | 简洁版播放界面 (上下滑切换/全屏/预加载) | 前端待开发 |
| 4 | 基础内容审核 (机审 + 人工审核队列) | 待实现 |
| 5 | 基础互动体系 (点赞/评论/关注) | 待实现 |
| 6 | 用户主页 (信息/视频列表/粉丝) | 待实现 |
| 7 | 基础搜索 (PostgreSQL全文搜索) | 待实现 |
| 8 | 推荐和分发 (热度排序/Redis ZSET) | 待实现 |

## Backend (NestJS)

- **Framework**: NestJS 11 (TypeScript, pnpm)
- **ORM**: TypeORM with PostgreSQL
- **Infra services**: Redis (`src/redis/`), MinIO (`src/minio/`)
- **Auth**: JWT via Passport (`@nestjs/jwt`, `@nestjs/passport`)
- **Queue**: Bull (`@nestjs/bull`) for async tasks (transcoding, review)
- **API docs**: Swagger (`@nestjs/swagger`)
- **Config**: `@nestjs/config` for env vars

### Backend Commands

```bash
cd backend
pnpm install
pnpm run start:dev    # watch mode
pnpm run build
pnpm run test         # unit tests (Jest, *.spec.ts)
pnpm run test:e2e     # e2e tests (test/jest-e2e.json)
pnpm run test:cov
pnpm run lint         # ESLint + Prettier
pnpm run format
```

Single test: `pnpm run test -- --testPathPattern=app.controller.spec`

### Backend Architecture

- `src/main.ts` — bootstrap on port 3000
- `src/app.module.ts` — root module (TypeORM, RedisModule, MinioModule)
- `src/redis/` — `RedisService` wrapper (set/get/del/ping)
- `src/minio/` — `MinioService` wrapper (uploadFile, getFileUrl, bucket mgmt)
- `.env` — DB/Redis/MinIO/JWT config
- Domain modules (auth, video, etc.) to be added under `src/` as feature modules

## Frontend (Flutter)

- **Flutter** (Dart, SDK ^3.11.5)
- Currently default template — all business logic pending

```bash
cd frontend
flutter pub get
flutter run
flutter test
flutter analyze
```

Dependencies to add per module:
- 网络请求: `dio`
- 视频选取: `image_picker`
- 视频播放: `video_player` + `chewie`
- 图片缓存: `cached_network_image`
- Token存储: `shared_preferences` / `flutter_secure_storage`
- 状态管理: `provider` / `riverpod`

## Infrastructure (Docker Compose)

```bash
docker compose up -d    # starts postgres, redis, minio
```

| Service    | Port(s)     | Default Credentials     |
|------------|-------------|-------------------------|
| PostgreSQL | 5432        | postgres / 123456       |
| Redis      | 6379        | —                       |
| MinIO      | 9000, 9001  | minioadmin / minioadmin |

## Development Notes

- FFmpeg required for video transcoding (install locally or in Docker)
- Content review via 阿里云/腾讯云 API (HTTP call, no SDK needed)
- Search uses PostgreSQL full-text search (tsvector), can migrate to ES later
- Detailed planning doc at `项目结构.txt`
