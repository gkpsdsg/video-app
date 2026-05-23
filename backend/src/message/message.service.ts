import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conversation } from './conversation.entity';
import { Message } from './message.entity';

@Injectable()
export class MessageService {
  constructor(
    @InjectRepository(Conversation) private convRepo: Repository<Conversation>,
    @InjectRepository(Message) private msgRepo: Repository<Message>,
  ) {}

  async sendMessage(senderId: string, recipientId: string, content: string) {
    if (senderId === recipientId) {
      throw new BadRequestException('不能给自己发消息');
    }

    const p1 = senderId < recipientId ? senderId : recipientId;
    const p2 = senderId < recipientId ? recipientId : senderId;

    let conversation = await this.convRepo.findOne({
      where: { participant1Id: p1, participant2Id: p2 },
    });

    if (!conversation) {
      conversation = this.convRepo.create({
        participant1Id: p1,
        participant2Id: p2,
        lastMessageAt: new Date(),
      });
      await this.convRepo.save(conversation);
    } else {
      await this.convRepo.update(conversation.id, {
        lastMessageAt: new Date(),
      });
    }

    const message = this.msgRepo.create({
      conversationId: conversation.id,
      senderId,
      content,
    });
    await this.msgRepo.save(message);

    return this.msgRepo.findOne({
      where: { id: message.id },
      relations: ['sender'],
    });
  }

  async getConversations(userId: string) {
    const conversations = await this.convRepo.find({
      where: [{ participant1Id: userId }, { participant2Id: userId }],
      relations: ['participant1', 'participant2'],
      order: { lastMessageAt: 'DESC' },
    });

    if (conversations.length === 0) return [];

    // Use PostgreSQL DISTINCT ON to fetch only the latest message per conversation
    const convIds = conversations.map((c) => c.id);
    const latestRows: any[] = await this.msgRepo.query(
      `SELECT DISTINCT ON (m."conversationId") m.*, u."username" AS "sender_username", u."nickname" AS "sender_nickname", u."avatar" AS "sender_avatar"
       FROM messages m
       LEFT JOIN users u ON u.id = m."senderId"
       WHERE m."conversationId" = ANY($1)
       ORDER BY m."conversationId", m."createdAt" DESC`,
      [convIds],
    );

    const lastMsgMap = new Map<string, any>();
    for (const row of latestRows) {
      lastMsgMap.set(row.conversationId, {
        id: row.id,
        conversationId: row.conversationId,
        senderId: row.senderId,
        content: row.content,
        readAt: row.readAt,
        createdAt: row.createdAt,
        sender: {
          id: row.senderId,
          username: row.sender_username,
          nickname: row.sender_nickname,
          avatar: row.sender_avatar,
        },
      });
    }

    return conversations.map((conv) => ({
      id: conv.id,
      lastMessageAt: conv.lastMessageAt,
      otherParticipant:
        conv.participant1Id === userId ? conv.participant2 : conv.participant1,
      lastMessage: lastMsgMap.get(conv.id) || null,
    }));
  }

  async getMessages(
    conversationId: string,
    userId: string,
    page: number = 1,
    limit: number = 50,
  ) {
    const [items, total] = await this.msgRepo.findAndCount({
      where: { conversationId },
      relations: ['sender'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    const unreadIds = items
      .filter((m) => m.senderId !== userId && !m.readAt)
      .map((m) => m.id);

    if (unreadIds.length > 0) {
      await this.msgRepo.update(unreadIds, { readAt: new Date() });
    }

    return {
      items: items.reverse(),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async markRead(conversationId: string, userId: string) {
    await this.msgRepo
      .createQueryBuilder()
      .update()
      .set({ readAt: new Date() })
      .where('conversationId = :conversationId', { conversationId })
      .andWhere('senderId != :userId', { userId })
      .andWhere('readAt IS NULL')
      .execute();
    return { success: true };
  }
}
