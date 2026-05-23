import {
  Controller,
  Get,
  Put,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NotificationService } from './notification.service';

@ApiTags('通知')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get('notifications')
  @ApiOperation({ summary: '获取通知列表' })
  getNotifications(
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    return this.notificationService.getNotifications(
      req.user.id,
      +page,
      +limit,
    );
  }

  @Get('notifications/unread-count')
  @ApiOperation({ summary: '获取未读通知数' })
  getUnreadCount(@Req() req: any) {
    return this.notificationService.getUnreadCount(req.user.id);
  }

  @Put('notifications/:id/read')
  @ApiOperation({ summary: '标记通知已读' })
  markRead(@Param('id') id: string, @Req() req: any) {
    return this.notificationService.markRead(id, req.user.id);
  }
}
