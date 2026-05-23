import {
  Controller,
  Post,
  Get,
  Param,
  Query,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MessageService } from './message.service';

@ApiTags('私信')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MessageController {
  constructor(private readonly messageService: MessageService) {}

  @Post('message/send')
  @ApiOperation({ summary: '发送私信' })
  sendMessage(
    @Req() req: any,
    @Body('recipientId') recipientId: string,
    @Body('content') content: string,
  ) {
    return this.messageService.sendMessage(req.user.id, recipientId, content);
  }

  @Get('conversations')
  @ApiOperation({ summary: '获取对话列表' })
  getConversations(@Req() req: any) {
    return this.messageService.getConversations(req.user.id);
  }

  @Get('message/:conversationId')
  @ApiOperation({ summary: '获取对话消息' })
  getMessages(
    @Param('conversationId') conversationId: string,
    @Req() req: any,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 50,
  ) {
    return this.messageService.getMessages(
      conversationId,
      req.user.id,
      +page,
      +limit,
    );
  }

  @Post('message/:conversationId/read')
  @ApiOperation({ summary: '标记对话已读' })
  markRead(@Param('conversationId') conversationId: string, @Req() req: any) {
    return this.messageService.markRead(conversationId, req.user.id);
  }
}
