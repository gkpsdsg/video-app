import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _red = Color(0xFFFE2C55);
const _cyan = Color(0xFF00FAF0);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);
const _textSecondary = Color(0xFFB0B0B0);

const _notifyItems = [
  {'icon': Icons.favorite, 'label': '赞和@我', 'badge': 5, 'gradient': [Color(0xFFFE2C55), Color(0xFFFF4D6A)]},
  {'icon': Icons.chat_bubble, 'label': '评论', 'badge': 2, 'gradient': [Color(0xFF3B82F6), Color(0xFF60A5FA)]},
  {'icon': Icons.person_add, 'label': '新增粉丝', 'badge': 12, 'gradient': [Color(0xFF22C55E), Color(0xFF4ADE80)]},
  {'icon': Icons.campaign, 'label': '系统通知', 'badge': 0, 'gradient': [Color(0xFFF59E0B), Color(0xFFFBBF24)]},
];

const _conversations = [
  {'name': '小莉', 'msg': '好的，明天见！😊', 'time': '刚刚', 'unread': 2, 'online': true},
  {'name': '张老师', 'msg': '今天的作业记得提交哦', 'time': '5分钟前', 'unread': 0, 'online': false},
  {'name': '李华', 'msg': '那个视频太搞笑了哈哈哈', 'time': '20分钟前', 'unread': 1, 'online': true},
  {'name': '王同学', 'msg': '周末一起出去拍照吗？', 'time': '1小时前', 'unread': 0, 'online': false},
  {'name': '设计师小王', 'msg': '最新版的设计稿发你了', 'time': '2小时前', 'unread': 3, 'online': true},
  {'name': '陈哥', 'msg': '谢谢你送的礼物！', 'time': '昨天', 'unread': 0, 'online': false},
  {'name': 'Linda', 'msg': 'Can you send me the link?', 'time': '昨天', 'unread': 1, 'online': false},
  {'name': '健身教练', 'msg': '明天下午3点有空吗？', 'time': '3天前', 'unread': 0, 'online': true},
  {'name': '小明', 'msg': '这个怎么弄的？教我一下', 'time': '5天前', 'unread': 0, 'online': false},
  {'name': '官方助手', 'msg': '您有新的活动通知', 'time': '1周前', 'unread': 0, 'online': false},
];

const _avatarGradients = [
  [Color(0xFFFE2C55), Color(0xFFFF4D6A)],
  [Color(0xFFF59E0B), Color(0xFFF97316)],
  [Color(0xFF8B5CF6), Color(0xFFA855F7)],
  [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
  [Color(0xFF22C55E), Color(0xFF4ADE80)],
  [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  [Color(0xFFEC4899), Color(0xFFF472B6)],
  [Color(0xFF10B981), Color(0xFF14B8A6)],
];

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _pageIndex = 0; // 0=私信, 1=互动

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : Colors.white;
    final border = isDark ? _dkBorder : const Color(0xFFE0E0E0);
    final muted = isDark ? _textMuted : const Color(0xFF999999);
    final secondary = isDark ? _textSecondary : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Text('消息', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70, size: 22),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, color: Colors.white70, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Sub-tabs
            Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  _MsgTab(label: '私信', active: _pageIndex == 0, onTap: () => setState(() => _pageIndex = 0)),
                  const SizedBox(width: 24),
                  _MsgTab(label: '互动', active: _pageIndex == 1, onTap: () => setState(() => _pageIndex = 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Notification quick-access row
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _notifyItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 18),
                itemBuilder: (context, index) {
                  final item = _notifyItems[index];
                  final grad = item['gradient'] as List<Color>;
                  return SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: grad),
                              ),
                              child: Icon(item['icon'] as IconData, color: Colors.white, size: 22),
                            ),
                            if ((item['badge'] as int) > 0)
                              Positioned(
                                right: -2, top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: const BoxDecoration(color: _red, borderRadius: BorderRadius.all(Radius.circular(9))),
                                  child: Text('${item['badge']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item['label'] as String, style: TextStyle(color: secondary, fontSize: 11)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: border),
            // Conversations
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _conversations.length,
                separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: border),
                itemBuilder: (context, index) {
                  final c = _conversations[index];
                  final grad = _avatarGradients[index % _avatarGradients.length];
                  final name = c['name'] as String;
                  final online = c['online'] as bool;
                  final unread = c['unread'] as int;

                  return ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('暂无聊天记录'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: grad),
                          ),
                          child: Center(
                            child: Text(name.characters.first, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        if (online)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(color: _cyan, shape: BoxShape.circle),
                              child: const Center(child: Icon(Icons.check, color: Colors.black, size: 10)),
                            ),
                          ),
                      ],
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(c['msg'] as String, style: TextStyle(color: muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(c['time'] as String, style: TextStyle(color: muted, fontSize: 11)),
                        if (unread > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(color: _red, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(9))),
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MsgTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MsgTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : _textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 20, height: 2.5, decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          )),
        ],
      ),
    );
  }
}
