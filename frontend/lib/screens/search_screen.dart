import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_box.dart';

const _red = Color(0xFFFE2C55);
const _dkS2 = Color(0xFF161616);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);
const _textSecondary = Color(0xFFB0B0B0);

const _trending = [
  {'rank': '1', 'title': '今日热点速递', 'heat': '1287.5万'},
  {'rank': '2', 'title': '周末去哪儿玩', 'heat': '986.3万'},
  {'rank': '3', 'title': '新歌推荐榜单', 'heat': '874.1万'},
  {'rank': '4', 'title': '美食探店合集', 'heat': '762.8万'},
  {'rank': '5', 'title': '科技新品发布', 'heat': '651.2万'},
  {'rank': '6', 'title': '萌宠日常分享', 'heat': '543.7万'},
  {'rank': '7', 'title': '篮球赛事回顾', 'heat': '489.3万'},
  {'rank': '8', 'title': '旅行攻略推荐', 'heat': '432.1万'},
];

const _categories = [
  {'icon': Icons.local_fire_department, 'label': '热榜', 'color': Color(0xFFFF6B35)},
  {'icon': Icons.music_note, 'label': '音乐', 'color': Color(0xFF00C9DB)},
  {'icon': Icons.movie, 'label': '影视', 'color': Color(0xFFA855F7)},
  {'icon': Icons.sports_soccer, 'label': '体育', 'color': Color(0xFF22C55E)},
  {'icon': Icons.restaurant, 'label': '美食', 'color': Color(0xFFF59E0B)},
  {'icon': Icons.brush, 'label': '艺术', 'color': Color(0xFFEC4899)},
  {'icon': Icons.science, 'label': '科技', 'color': Color(0xFF3B82F6)},
  {'icon': Icons.emoji_emotions, 'label': '搞笑', 'color': Color(0xFF8B5CF6)},
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await _api.dio.get('/search', queryParameters: {'keyword': keyword.trim()});
      final items = (res.data['items'] as List?) ?? [];
      setState(() {
        _results = items.cast<Map<String, dynamic>>();
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (_) {
      setState(() { _results = []; _isSearching = false; _hasSearched = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? _dkS2 : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.arrow_back, color: isDark ? Colors.white70 : const Color(0xFF666666), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.search, color: isDark ? _textMuted : const Color(0xFF999999), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A1A), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '搜索视频 / 用户 / 话题',
                          hintStyle: TextStyle(color: isDark ? _textMuted : const Color(0xFF999999), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: _performSearch,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _focusNode.unfocus();
                          setState(() { _results = []; _hasSearched = false; });
                        },
                        child: const Icon(Icons.close, size: 18, color: _textMuted),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? _dkBorder : const Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_scanner, size: 16, color: _textMuted),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _hasSearched ? _buildResults(isDark) : _buildDefault(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefault(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending searches
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Text('热搜榜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 6),
                const Icon(Icons.trending_up, color: _red, size: 18),
                const Spacer(),
                Text('更多', style: TextStyle(fontSize: 12, color: isDark ? _textMuted : const Color(0xFF999999))),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trending.length,
            separatorBuilder: (_, _) => Divider(height: 1, indent: 56, color: isDark ? _dkBorder : const Color(0xFFE0E0E0)),
            itemBuilder: (context, index) {
              final item = _trending[index];
              final rank = int.parse(item['rank']!);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () {
                  _searchController.text = item['title']!;
                  _performSearch(item['title']!);
                },
                leading: Text(item['rank']!,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: rank <= 3 ? _red : Colors.white54)),
                title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: Text(item['heat']!, style: TextStyle(color: isDark ? _textMuted : const Color(0xFF999999), fontSize: 11)),
                dense: true,
              );
            },
          ),
          const SizedBox(height: 20),
          // Category grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('发现更多', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(cat['label'] as String, style: TextStyle(color: isDark ? _textSecondary : const Color(0xFF666666), fontSize: 12)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 36, height: 36, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 80 + (i * 20).toDouble(), height: 12, radius: 6),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: double.infinity, height: 14, radius: 7),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: _textMuted),
            const SizedBox(height: 12),
            Text('未找到相关结果', style: TextStyle(color: isDark ? _textMuted : const Color(0xFF999999), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: isDark ? _dkBorder : const Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final item = _results[index];
        final title = (item['title'] ?? '').toString();
        final author = item['author'] is Map<String, dynamic> ? item['author'] : <String, dynamic>{};
        final authorName = (author['nickname'] ?? author['username'] ?? '').toString();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDark ? _dkS2 : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_outline, color: _textMuted, size: 24),
          ),
          title: Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('@$authorName', style: TextStyle(color: isDark ? _textMuted : const Color(0xFF999999), fontSize: 12)),
          dense: true,
        );
      },
    );
  }
}
