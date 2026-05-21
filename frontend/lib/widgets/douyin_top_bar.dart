import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _cyan = Color(0xFF00FAF0);

class DouyinTopBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onSearch;
  final VoidCallback onLive;

  const DouyinTopBar({
    super.key,
    required this.activeIndex,
    required this.onTabChanged,
    required this.onSearch,
    required this.onLive,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Tabs
            _TopTab(label: '推荐', active: activeIndex == 1, onTap: () {
              HapticFeedback.selectionClick();
              onTabChanged(1);
            }),
            const SizedBox(width: 20),
            _TopTab(label: '关注', active: activeIndex == 0, onTap: () {
              HapticFeedback.selectionClick();
              onTabChanged(0);
            }),
            // Search
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onSearch,
              child: const Icon(Icons.search, color: Colors.white70, size: 24),
            ),
            const Spacer(),
            // LIVE button
            GestureDetector(
              onTap: onLive,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: _cyan.withValues(alpha: 0.6), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, color: _cyan, size: 14),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TopTab({required this.label, required this.active, required this.onTap});

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
              fontSize: active ? 17 : 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 20,
            height: 2.5,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
