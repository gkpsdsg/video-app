import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Query,
  UseGuards,
  Req,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { VideoService } from './video.service';

@ApiTags('视频')
@Controller('video')
export class VideoController {
  constructor(private readonly videoService: VideoService) {}

  @Post('upload')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '上传视频' })
  @UseInterceptors(FileInterceptor('file'))
  async upload(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 100 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: /^video\// }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Req() req: any,
  ) {
    const title = req.body?.title || file.originalname;
    return this.videoService.upload(file, title, req.user.id);
  }

  @Get('list')
  @ApiOperation({ summary: '视频列表（分页）' })
  findAll(@Query('page') page: number = 1, @Query('limit') limit: number = 20) {
    return this.videoService.findAll(+page, +limit);
  }

  @Get(':id')
  @ApiOperation({ summary: '视频详情' })
  findOne(@Param('id') id: string) {
    return this.videoService.findOne(id);
  }

  @Get(':id/stream')
  @ApiOperation({ summary: '获取视频播放签名 URL' })
  getStreamUrl(@Param('id') id: string) {
    return this.videoService.getStreamUrl(id);
  }

  @Get(':id/cover')
  @ApiOperation({ summary: '获取视频封面签名 URL' })
  getCoverUrl(@Param('id') id: string) {
    return this.videoService.getCoverUrl(id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '删除视频（作者或管理员）' })
  delete(@Param('id') id: string, @Req() req: any) {
    return this.videoService.delete(id, req.user.id, req.user.role);
  }
}
