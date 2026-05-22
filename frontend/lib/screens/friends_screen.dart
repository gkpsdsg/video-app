import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_box.dart';

const _red = Color(0xFFFE2C55);
const _dkS1 = Color(0xFF111111);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);

const _gradients = [
  [Color(0xFFFE2C55), Color(0xFFFF4D6A)],
  [Color(0xFFF59E0B), Color(0xFFF97316)],
  [Color(0xFF8B5CF6), Color(0xFFA855F7)],
  [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
  [Color(0xFF22C55E), Color(0xFF4ADE80)],
];

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    try {
      final res = await _api.dio.get('/following');
      final items = (res.data['items'] as List?) ?? [];
      setState(() {
        _following = items.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFollow(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    final followingUser = item['following'] is Map<String, dynamic> ? item['following'] : item;
    final userId = followingUser['id']?.toString() ?? '';
    if (userId.isEmpty) return;

    setState(() {
      if (item.containsKey('_following')) {
        item['_following'] = !(item['_following'] == true);
      }
    });

    _api.dio.post('/follow/$userId').then((res) {
      if (mounted && res.data['following'] == false) {
        _loadFollowing();
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : Colors.white;
    final s1 = isDark ? _dkS1 : const Color(0xFFF8F8F8);
    final border = isDark ? _dkBorder : const Color(0xFFE0E0E0);
    final muted = isDark ? _textMuted : const Color(0xFF999999);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading ? _buildLoading(bg, textColor) : _buildContent(bg, s1, border, muted, textColor),
      ),
    );
  }

  Widget _buildLoading(Color bg, Color textColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text('朋友', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.person_add_outlined, color: Colors.white70, size: 22), onPressed: () {}),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: 3,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: const ShimmerBox(width: 110, height: 140, radius: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: _dkBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text('我关注的人', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (_, iii) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const ShimmerBox(width: 48, height: 48, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 80 + (iii * 20).toDouble(), height: 12, radius: 6),
                        const SizedBox(height: 8),
                        const ShimmerBox(width: 160, height: 10, radius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color bg, Color s1, Color border, Color muted, Color textColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text('朋友', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.person_add_outlined, color: Colors.white70, size: 22), onPressed: () {}),
              ],
            ),
          ),
          // Live section placeholder
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text('直播中', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                const Spacer(),
                Text('查看全部', style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: muted),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final grad = _gradients[index % _gradients.length];
                return Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: s1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                        child: const Icon(Icons.live_tv, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text('主播${index + 1}', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('直播中', style: TextStyle(color: _red, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: border),
          // Following list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text('我关注的人', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          ),
          if (_following.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: muted),
                    const SizedBox(height: 12),
                    Text('还没有关注任何人', style: TextStyle(color: muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('关注更多用户发现精彩内容', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _following.length,
            separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: border),
            itemBuilder: (context, index) {
              final item = _following[index];
              final user = item['following'] is Map<String, dynamic> ? item['following'] as Map<String, dynamic> : item;
              final name = (user['nickname'] ?? user['username'] ?? '用户').toString();
              final username = user['username']?.toString() ?? '';
              final grad = _gradients[index % _gradients.length];
              final isFollowing = item['_following'] ?? true;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                      child: Center(
                        child: Text(name.characters.first,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('@$username', style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleFollow(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isFollowing ? const Color(0x1AFE2C55) : Colors.transparent,
                          border: Border.all(color: isFollowing ? _red.withValues(alpha: 0.5) : _red, width: 1),
                        ),
                        child: Text(
                          isFollowing ? '已关注' : '关注',
                          style: TextStyle(color: isFollowing ? _red : _red, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
