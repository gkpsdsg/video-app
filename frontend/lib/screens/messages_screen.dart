import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_box.dart';
import '../constants/app_colors.dart';
import 'chat_screen.dart';

const _red = appRed;
const _dkS1 = dkSurface1;
const _dkS2 = dkSurface2;
const _dkBorder = dkBorder;
const _textMuted = textMuted;
const _textSecondary = textSecondary;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _api = ApiService();
  int _pageIndex = 0;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _convLoading = true;
  bool _notifLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadNotifications();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await _api.dio.get('/conversations');
      final items = res.data is List ? res.data as List : (res.data['items'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _conversations = items.cast<Map<String, dynamic>>();
          _convLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _convLoading = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await _api.dio.get('/notifications');
      final items = (res.data['items'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _notifications = items.cast<Map<String, dynamic>>();
          _notifLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _notifLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadConversations(), _loadNotifications()]);
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  String _notifMessage(Map<String, dynamic> n) {
    final actor = n['actor'] is Map<String, dynamic> ? n['actor'] : <String, dynamic>{};
    final name = (actor['nickname'] ?? actor['username'] ?? '用户').toString();
    switch (n['type']) {
      case 'like': return '$name 赞了你的视频';
      case 'comment': return '$name 评论了你的视频';
      case 'follow': return '$name 关注了你';
      default: return '$name 与你互动';
    }
  }

  void _openNewChat() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewChatSheet(onUserSelected: (user) {
        Navigator.of(context).pop();
        _startChat(user);
      }),
    );
  }

  void _startChat(Map<String, dynamic> user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: '',
          otherParticipant: user,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  void _openChat(Map<String, dynamic> conv) {
    HapticFeedback.lightImpact();
    final other = conv['otherParticipant'] is Map<String, dynamic>
        ? conv['otherParticipant'] as Map<String, dynamic>
        : <String, dynamic>{};
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv['id']?.toString() ?? '',
          otherParticipant: other,
        ),
      ),
    ).then((_) => _loadConversations());
  }

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
                    onPressed: _openNewChat,
                  ),
                ],
              ),
            ),
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
            const SizedBox(height: 4),
            Expanded(
              child: _pageIndex == 0
                  ? _buildConversations(border, muted)
                  : _buildNotifications(border, muted, secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversations(Color border, Color muted) {
    if (_convLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const ShimmerBox(width: 48, height: 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100 + (i * 20).toDouble(), height: 12, radius: 6),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: double.infinity, height: 12, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(child: Text('暂无消息', style: TextStyle(color: muted, fontSize: 13))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: border),
        itemBuilder: (context, index) {
          final c = _conversations[index];
          final other = c['otherParticipant'] is Map<String, dynamic>
              ? c['otherParticipant'] as Map<String, dynamic>
              : <String, dynamic>{};
          final name = (other['nickname'] ?? other['username'] ?? '用户').toString();
          final lastMsg = c['lastMessage'] is Map<String, dynamic> ? c['lastMessage'] as Map<String, dynamic> : null;
          final preview = lastMsg?['content']?.toString() ?? '开始聊天';
          final grad = avatarGradients[index % avatarGradients.length];

          return ListTile(
            onTap: () => _openChat(c),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: grad),
              ),
              child: Center(
                child: Text(name.characters.first, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(preview, style: TextStyle(color: muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(_formatTime(c['lastMessageAt']?.toString()), style: TextStyle(color: muted, fontSize: 11)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          );
        },
      ),
    );
  }

  Widget _buildNotifications(Color border, Color muted, Color secondary) {
    if (_notifLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const ShimmerBox(width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120 + (i * 20).toDouble(), height: 12, radius: 6),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: double.infinity, height: 10, radius: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return Center(child: Text('暂无互动消息', style: TextStyle(color: muted, fontSize: 13)));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => Divider(height: 1, indent: 64, color: border),
      itemBuilder: (context, index) {
        final n = _notifications[index];
        final actor = n['actor'] is Map<String, dynamic> ? n['actor'] : <String, dynamic>{};
        final name = (actor['nickname'] ?? actor['username'] ?? '用户').toString();
        final grad = avatarGradients[index % avatarGradients.length];
        final isRead = n['isRead'] == true;

        IconData icon;
        switch (n['type']) {
          case 'like': icon = Icons.favorite; break;
          case 'comment': icon = Icons.chat_bubble; break;
          case 'follow': icon = Icons.person_add; break;
          default: icon = Icons.campaign;
        }

        return ListTile(
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: grad),
            ),
            child: Center(
              child: Text(name.characters.first, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          title: Row(
            children: [
              Flexible(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isRead ? muted : Colors.white))),
              if (!isRead) ...[
                const SizedBox(width: 6),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Icon(icon, size: 12, color: secondary),
              const SizedBox(width: 4),
              Flexible(child: Text(_notifMessage(n), style: TextStyle(color: secondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          trailing: Text(_formatTime(n['createdAt']?.toString()), style: TextStyle(color: muted, fontSize: 11)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        );
      },
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

// ── New chat user search sheet ──

class _NewChatSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onUserSelected;

  const _NewChatSheet({required this.onUserSelected});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final res = await _api.dio.get('/search/users', queryParameters: {'keyword': keyword});
      if (mounted) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(res.data['items'] ?? []);
          _searching = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65 + bottomInset,
      decoration: const BoxDecoration(
        color: _dkS1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _dkBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: '搜索用户...',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: _textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _results = []; _hasSearched = false; });
                        },
                      )
                    : null,
                filled: true,
                fillColor: _dkS2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searching) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const ShimmerBox(width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100 + (i * 20).toDouble(), height: 12, radius: 6),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: 160, height: 10, radius: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_hasSearched) {
      return const Center(child: Text('搜索用户开始聊天', style: TextStyle(color: _textMuted, fontSize: 13)));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('未找到用户', style: TextStyle(color: _textMuted, fontSize: 13)));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 68, color: _dkBorder),
      itemBuilder: (context, index) {
        final user = _results[index];
        final name = (user['nickname'] ?? user['username'] ?? '用户').toString();
        final username = user['username']?.toString() ?? '';
        final bio = user['bio']?.toString() ?? '';
        final grad = avatarGradients[index % avatarGradients.length];

        return ListTile(
          onTap: () => widget.onUserSelected(user),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
            child: Center(
              child: Text(name.characters.first, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('@$username${bio.isNotEmpty ? ' · $bio' : ''}',
              style: const TextStyle(color: _textMuted, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        );
      },
    );
  }
}
