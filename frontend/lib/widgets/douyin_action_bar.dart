import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _red = Color(0xFFFE2C55);
const _redLight = Color(0xFFFF4D6A);

class DouyinActionBar extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final int shareCount;
  final bool isBookmarked;
  final String authorAvatar;
  final String authorInitial;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback? onFollow;

  const DouyinActionBar({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.bookmarkCount,
    required this.shareCount,
    this.isBookmarked = false,
    required this.authorAvatar,
    required this.authorInitial,
    required this.onLike,
    required this.onComment,
    required this.onBookmark,
    required this.onShare,
    this.onFollow,
  });

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + follow
        _ActionCircle(
          onTap: onFollow ?? () {},
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  gradient: const LinearGradient(colors: [_red, _redLight]),
                ),
                child: Center(
                  child: Text(authorInitial, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                bottom: -4, left: 0, right: 0,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Like
        _ActionItem(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: _fmt(likeCount),
          active: isLiked,
          onTap: () {
            HapticFeedback.lightImpact();
            onLike();
          },
        ),
        const SizedBox(height: 16),
        // Comment
        _ActionItem(
          icon: Icons.chat_bubble_rounded,
          label: _fmt(commentCount),
          onTap: () {
            HapticFeedback.lightImpact();
            onComment();
          },
        ),
        const SizedBox(height: 16),
        // Bookmark
        _ActionItem(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          label: _fmt(bookmarkCount),
          active: isBookmarked,
          activeColor: const Color(0xFFFFD700),
          onTap: () {
            HapticFeedback.lightImpact();
            onBookmark();
          },
        ),
        const SizedBox(height: 16),
        // Share
        _ActionItem(
          icon: Icons.share,
          label: _fmt(shareCount),
          onTap: () {
            HapticFeedback.lightImpact();
            onShare();
          },
        ),
      ],
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ActionCircle({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}

class _ActionItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  const _ActionItem({required this.icon, required this.label, required this.onTap, this.active = false, this.activeColor});

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          children: [
            Icon(widget.icon, color: widget.active ? (widget.activeColor ?? _red) : Colors.white, size: 32),
            const SizedBox(height: 2),
            Text(widget.label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
