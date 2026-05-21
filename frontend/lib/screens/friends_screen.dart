import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

const _suggestedUsers = [
  {'name': '舞蹈达人小美', 'fans': '128万', 'reason': '你可能认识'},
  {'name': '旅行博主阿杰', 'fans': '56万', 'reason': '热门推荐'},
  {'name': '美食探店王姐', 'fans': '89万', 'reason': '共同好友: 3人'},
  {'name': '音乐人老张', 'fans': '34万', 'reason': '热门推荐'},
];

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

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
        child: SingleChildScrollView(
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
                    IconButton(
                      icon: const Icon(Icons.person_add_outlined, color: Colors.white70, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              // Live section
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: grad),
                            ),
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
              // Suggested users
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Text('你可能认识的人', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestedUsers.length,
                separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: border),
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  final grad = _gradients[index % _gradients.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: grad),
                          ),
                          child: Center(
                            child: Text((user['name'] as String).characters.first,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['name']!, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text('${user['fans']}粉丝 · ${user['reason']}', style: TextStyle(color: muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _red, width: 1),
                            ),
                            child: const Text('关注', style: TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }
}
