import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_box.dart';

const _surface2 = Color(0xFF1A1A1A);
const _surface3 = Color(0xFF262626);
const _violet500 = Color(0xFF8B5CF6);
const _textMuted = Color(0xFF71717A);
const _textSecondary = Color(0xFFA1A1AA);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      final userId = user['id'];
      final res = await _api.dio.get('/user/$userId/profile');
      setState(() {
        _profile = res.data;
        _isLoading = false;
      });
      _loadVideos();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      final userId = user['id'];
      final res = await _api.dio.get('/user/$userId/videos');
      setState(() {
        _videos = List<Map<String, dynamic>>.from(res.data['items'] ?? []);
      });
    } catch (_) {}
  }

  void _handleLogout() {
    HapticFeedback.mediumImpact();
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const ShimmerBox(width: 72, height: 72, radius: 36),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerBox(width: 140, height: 18, radius: 9),
                          const SizedBox(height: 8),
                          const ShimmerBox(width: 200, height: 14, radius: 7),
                          const SizedBox(height: 6),
                          const ShimmerBox(width: 120, height: 14, radius: 7),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (_) => const ShimmerBox(width: 48, height: 40, radius: 8)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _textMuted, size: 48),
              const SizedBox(height: 12),
              const Text('加载失败', style: TextStyle(color: _textMuted, fontSize: 14)),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: '重试',
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadProfile();
                  },
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final username = (profile['username'] ?? '').toString();
    final nickname = (profile['nickname'] ?? username).toString();
    final initial = nickname.isNotEmpty ? nickname.characters.first.toUpperCase() : '?';
    final videoCount = '${profile['videoCount'] ?? 0}';
    final followerCount = _fmt(profile['followerCount'] ?? 0);
    final followingCount = _fmt(profile['followingCount'] ?? 0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('个人主页', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  Semantics(
                    button: true,
                    label: '退出登录',
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: _textMuted, size: 20),
                      onPressed: _handleLogout,
                    ),
                  ),
                ],
              ),
            ),
            // Profile card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_violet500, Color(0xFFA855F7)]),
                      border: Border.all(color: _violet500.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _violet500.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(nickname,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: Color(0xFF38BDF8)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('@$username · ${profile['bio'] ?? '这个人很懒，什么都没写...'}',
                            style: const TextStyle(fontSize: 13, color: _textSecondary),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatItem(value: videoCount, label: '视频'),
                  const Spacer(),
                  _StatItem(value: followerCount, label: '粉丝'),
                  const Spacer(),
                  _StatItem(value: followingCount, label: '关注'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: '编辑资料',
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _surface3,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('编辑资料'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: '分享主页',
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _surface3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _surface3),
                      ),
                      child: const Icon(Icons.share, size: 18, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tabs
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _surface3)),
              ),
              child: Row(
                children: [
                  _TabItem(label: '视频', active: _tabIndex == 0, onTap: () { HapticFeedback.selectionClick(); setState(() => _tabIndex = 0); }),
                  _TabItem(label: '喜欢', active: _tabIndex == 1, onTap: () { HapticFeedback.selectionClick(); setState(() => _tabIndex = 1); }),
                  _TabItem(label: '收藏', active: _tabIndex == 2, onTap: () { HapticFeedback.selectionClick(); setState(() => _tabIndex = 2); }),
                ],
              ),
            ),
            // Video grid
            Expanded(
              child: _videos.isEmpty
                  ? Center(child: Text('暂无作品', style: TextStyle(color: Colors.grey[600], fontSize: 13)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(3),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                        childAspectRatio: 0.56,
                      ),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final v = _videos[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: _surface2,
                              child: const Center(
                                child: Icon(Icons.play_circle_outline, size: 28, color: _textMuted),
                              ),
                            ),
                            Positioned(
                              bottom: 6, left: 6, right: 6,
                              child: Text(v['title'] ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic n) {
    final i = (n is int) ? n : int.tryParse(n.toString()) ?? 0;
    if (i >= 10000) return '${(i / 10000).toStringAsFixed(1)}万';
    if (i >= 1000) return '${(i / 1000).toStringAsFixed(1)}k';
    return i.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: _textMuted)),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: active ? Colors.white : Colors.transparent, width: 2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : _textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
