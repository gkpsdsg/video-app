import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_box.dart';

const _red = Color(0xFFFE2C55);
const _dkS2 = Color(0xFF161616);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);
const _textSecondary = Color(0xFFB0B0B0);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : Colors.white;
    final s2 = isDark ? _dkS2 : const Color(0xFFF0F0F0);
    final border = isDark ? _dkBorder : const Color(0xFFE0E0E0);
    final muted = isDark ? _textMuted : const Color(0xFF999999);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
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
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: muted, size: 48),
              const SizedBox(height: 12),
              Text('加载失败', style: TextStyle(color: muted, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () { setState(() => _isLoading = true); _loadProfile(); },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final username = (profile['username'] ?? '').toString();
    final nickname = (profile['nickname'] ?? username).toString();
    final initial = nickname.isNotEmpty ? nickname.characters.first.toUpperCase() : '?';
    final followerCount = _fmt(profile['followerCount'] ?? 0);
    final followingCount = _fmt(profile['followingCount'] ?? 0);
    final likeTotal = _fmt(profile['likeTotal'] ?? 0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with settings + message + QR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 14, color: _textMuted),
                      const SizedBox(width: 4),
                      Text(username, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white70, size: 22),
                        onPressed: () {},
                        visualDensity: VisualDensity.compact,
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.mail_outline, color: Colors.white70, size: 22),
                            onPressed: () {},
                            visualDensity: VisualDensity.compact,
                          ),
                          const Positioned(
                            right: 6, top: 4,
                            child: Icon(Icons.circle, size: 8, color: _red),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
                        onPressed: () {},
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                        onPressed: _handleLogout,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_red, Color(0xFFFF4D6A)]),
                      border: Border.all(color: _red.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
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
            const SizedBox(height: 20),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatItem(value: followingCount, label: '关注'),
                  const Spacer(),
                  _StatItem(value: followerCount, label: '粉丝'),
                  const Spacer(),
                  _StatItem(value: likeTotal, label: '获赞'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? _dkS2 : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('编辑资料', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? _dkS2 : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share, size: 18, color: _textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tabs
            Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
              child: Row(
                children: [
                  _TabItem(label: '作品', active: _tabIndex == 0, onTap: () { HapticFeedback.selectionClick(); setState(() => _tabIndex = 0); }),
                  _TabItem(label: '喜欢', active: _tabIndex == 1, onTap: () { HapticFeedback.selectionClick(); setState(() => _tabIndex = 1); }),
                  _TabItem(label: '收藏', active: _tabIndex == 2, onTap: () { HapticFeedback.selectionClick(); setState(() => _tabIndex = 2); }),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: _videos.isEmpty
                  ? Center(child: Text('暂无作品', style: TextStyle(color: muted, fontSize: 13)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 0.56,
                      ),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final v = _videos[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: s2, child: const Center(child: Icon(Icons.play_circle_outline, size: 28, color: _textMuted))),
                            Positioned(
                              bottom: 4, left: 4, right: 4,
                              child: Text(v['title'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: _textMuted)),
        ],
      ),
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
            border: Border(bottom: BorderSide(color: active ? Colors.white : Colors.transparent, width: 2)),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : _textMuted,
          )),
        ),
      ),
    );
  }
}
