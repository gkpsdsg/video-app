import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from './notification.entity';

@Injectable()
export class NotificationService {
  constructor(
    @InjectRepository(Notification) private notifRepo: Repository<Notification>,
  ) {}

  async create(
    recipientId: string,
    actorId: string,
    type: NotificationType,
    targetId?: string,
  ) {
    if (recipientId === actorId) return null;
    const notif = this.notifRepo.create({
      recipientId,
      actorId,
      type,
      targetId,
    });
    return this.notifRepo.save(notif);
  }

  async getNotifications(userId: string, page: number = 1, limit: number = 20) {
    const [items, total] = await this.notifRepo.findAndCount({
      where: { recipientId: userId },
      relations: ['actor'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getUnreadCount(userId: string) {
    const count = await this.notifRepo.count({
      where: { recipientId: userId, isRead: false },
    });
    return { count };
  }

  async markRead(id: string, userId: string) {
    await this.notifRepo.update({ id, recipientId: userId }, { isRead: true });
    return { success: true };
  }
}
