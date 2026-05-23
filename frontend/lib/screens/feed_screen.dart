import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/douyin_top_bar.dart';
import '../widgets/douyin_action_bar.dart';
import '../widgets/heart_burst.dart';
import 'search_screen.dart';
import 'chat_screen.dart';

const _red = Color(0xFFFE2C55);
const _dkS1 = Color(0xFF111111);
const _dkS2 = Color(0xFF161616);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);
const _textSecondary = Color(0xFFB0B0B0);

class VideoItem {
  final String id;
  final String title;
  final String? coverUrl;
  final Map<String, dynamic> author;
  final int likeCount;
  final int commentCount;

  VideoItem({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.author,
    required this.likeCount,
    required this.commentCount,
  });
}

class FeedScreen extends StatefulWidget {
  final List<VideoItem>? initialVideos;
  final int initialIndex;

  const FeedScreen({super.key, this.initialVideos, this.initialIndex = 0});

  @override
  State<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  late final PageController _pageController;
  final _api = ApiService();
  List<VideoItem> _videos = [];
  int _currentPage = 0;
  bool _isLoading = true;
  String? _loadError;
  bool _isPlaying = true;
  final Map<String, GlobalKey<_VideoPlayerWidgetState>> _videoKeys = {};
  final Map<String, Map<String, dynamic>> _batchStatus = {};

  // Top bar state
  int _feedTabIndex = 1; // 0=关注, 1=推荐

  @override
  void initState() {
    super.initState();
    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
      _videos = widget.initialVideos!;
      _currentPage = widget.initialIndex.clamp(0, _videos.length - 1);
      _pageController = PageController(initialPage: _currentPage);
      _isLoading = false;
      _fetchBatchStatus();
    } else {
      _pageController = PageController();
      _fetchVideos();
    }
  }

  Future<void> _fetchBatchStatus() async {
    if (_videos.isEmpty) return;
    try {
      final videoIds = _videos.map((v) => v.id).toList();
      final res = await _api.dio.post('/batch-status', data: {'videoIds': videoIds});
      final data = res.data as Map<String, dynamic>;
      final likesSrc = data['likes'];
      final likes = likesSrc is Map ? Map<String, bool>.from(likesSrc.map((k, v) => MapEntry(k.toString(), v == true))) : <String, bool>{};
      final bookmarksSrc = data['bookmarks'];
      final bookmarks = bookmarksSrc is Map ? Map<String, bool>.from(bookmarksSrc.map((k, v) => MapEntry(k.toString(), v == true))) : <String, bool>{};
      final countsSrc = data['bookmarkCounts'];
      final counts = countsSrc is Map ? Map<String, int>.from(countsSrc.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))) : <String, int>{};
      final followsSrc = data['follows'];
      final follows = followsSrc is Map ? Map<String, bool>.from(followsSrc.map((k, v) => MapEntry(k.toString(), v == true))) : <String, bool>{};
      final authorsSrc = data['videoAuthorMap'];
      final videoAuthors = authorsSrc is Map ? Map<String, String>.from(authorsSrc.map((k, v) => MapEntry(k.toString(), v.toString()))) : <String, String>{};
      final likeCountsSrc = data['likeCounts'];
      final likeCounts = likeCountsSrc is Map ? Map<String, int>.from(likeCountsSrc.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))) : <String, int>{};
      final commentCountsSrc = data['commentCounts'];
      final commentCounts = commentCountsSrc is Map ? Map<String, int>.from(commentCountsSrc.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))) : <String, int>{};

      if (mounted) {
        setState(() {
          _batchStatus.clear();
          for (final v in _videos) {
            final authorId = videoAuthors[v.id] ?? v.author['id']?.toString() ?? '';
            _batchStatus[v.id] = {
              'isLiked': likes[v.id] ?? false,
              'isBookmarked': bookmarks[v.id] ?? false,
              'bookmarkCount': counts[v.id] ?? 0,
              'isFollowing': follows[authorId] ?? false,
              'likeCount': likeCounts[v.id] ?? v.likeCount,
              'commentCount': commentCounts[v.id] ?? v.commentCount,
            };
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideos() async {
    try {
      final endpoint = _feedTabIndex == 0 ? '/feed/following' : '/feed/hot';
      final res = await _api.dio.get(endpoint, queryParameters: {'page': 1, 'limit': 20});
      final items = (res.data['items'] as List).map((v) {
        final videoData = _feedTabIndex == 0 ? (v as Map<String, dynamic>) : v;
        return VideoItem(
          id: videoData['id'].toString(),
          title: videoData['title'] ?? '',
          author: videoData['author'] is Map<String, dynamic> ? videoData['author'] : <String, dynamic>{},
          likeCount: videoData['likeCount'] ?? 0,
          commentCount: videoData['commentCount'] ?? 0,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _videos = items;
          _isLoading = false;
        });
        _fetchBatchStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void refreshBatchStatus() {
    _fetchBatchStatus();
  }

  void _onTabChanged(int index) {
    if (_feedTabIndex == index) return;
    setState(() {
      _feedTabIndex = index;
      _isLoading = true;
      _videos = [];
      _currentPage = 0;
    });
    _pageController.jumpToPage(0);
    _fetchVideos();
  }

  void _onPlayPauseChanged(bool isPlaying) {
    if (_isPlaying != isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
    if (_videos.isEmpty) return;
    final key = _videoKeys[_videos[_currentPage].id];
    key?.currentState?.togglePlayPause();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerBox(width: 48, height: 48, radius: 24),
              SizedBox(height: 16),
              ShimmerBox(width: 160, height: 14, radius: 7),
              SizedBox(height: 8),
              ShimmerBox(width: 100, height: 12, radius: 6),
            ],
          ),
        ),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _textMuted, size: 48),
              const SizedBox(height: 12),
              const Text('加载失败', style: TextStyle(color: _textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() { _isLoading = true; _loadError = null; });
                  _fetchVideos();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_videos.isEmpty) {
      return const Scaffold(body: Center(child: Text('暂无视频', style: TextStyle(color: _textMuted))));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Video pages
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final video = _videos[index];
              final key = _videoKeys.putIfAbsent(video.id, () => GlobalKey<_VideoPlayerWidgetState>());
              final vId = video.id;
              return _VideoPlayerWidget(
                key: key,
                video: video,
                isCurrent: index == _currentPage,
                isGloballyPlaying: _isPlaying,
                onPlayPauseChanged: _onPlayPauseChanged,
                statusInfo: _batchStatus[vId],
              );
            },
          ),
          // Top bar overlay
          Positioned(
            top: 0, left: 0, right: 0,
            child: DouyinTopBar(
              activeIndex: _feedTabIndex,
              onTabChanged: _onTabChanged,
              onSearch: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              onLive: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('暂无直播'), behavior: SnackBarBehavior.floating),
                );
              },
              onBack: widget.initialVideos != null
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ),
          // Bottom control bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildControlBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(top: 8, bottom: bottomPadding > 0 ? bottomPadding : 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CapsuleButton(icon: Icons.skip_previous, label: '上一条', onTap: () {
            if (_currentPage > 0) {
              HapticFeedback.lightImpact();
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          }),
          const SizedBox(width: 28),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(_isPlaying),
                  color: Colors.white, size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          _CapsuleButton(icon: Icons.skip_next, label: '下一条', onTap: () {
            if (_currentPage < _videos.length - 1) {
              HapticFeedback.lightImpact();
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          }),
        ],
      ),
    );
  }
}

// ── Video player widget ──

class _VideoPlayerWidget extends StatefulWidget {
  final VideoItem video;
  final bool isCurrent;
  final bool isGloballyPlaying;
  final ValueChanged<bool> onPlayPauseChanged;
  final Map<String, dynamic>? statusInfo;

  const _VideoPlayerWidget({
    required this.video,
    required this.isCurrent,
    required this.isGloballyPlaying,
    required this.onPlayPauseChanged,
    this.statusInfo,
    super.key,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _fetching = false;
  bool _loadFailed = false;

  bool _isLiked = false;
  late int _likeCount;
  late int _commentCount;
  bool _likeLoading = false;
  bool _isMuted = true;
  bool _isBookmarked = false;
  int _bookmarkCount = 0;
  bool _isFollowing = false;
  bool _bookmarkLoading = false;
  Widget? _heartBurst;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.video.likeCount;
    _commentCount = widget.video.commentCount;

    // Use batch-loaded status if available, otherwise fall back to individual queries
    final s = widget.statusInfo;
    if (s != null) {
      _isLiked = s['isLiked'] as bool? ?? false;
      _isBookmarked = s['isBookmarked'] as bool? ?? false;
      _bookmarkCount = s['bookmarkCount'] as int? ?? 0;
      _isFollowing = s['isFollowing'] as bool? ?? false;
      _likeCount = s['likeCount'] as int? ?? _likeCount;
      _commentCount = s['commentCount'] as int? ?? _commentCount;
    } else {
      _checkLikeStatus();
      _checkBookmarkStatus();
      _fetchBookmarkCount();
      _checkFollowStatus();
    }
    if (widget.isCurrent) _initVideo();
  }

  @override
  void didUpdateWidget(_VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      if (_controller != null && _controller!.value.isInitialized) {
        if (widget.isGloballyPlaying) _controller!.play();
      } else if (!_fetching && !_loadFailed) {
        _initVideo();
      }
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _controller?.pause();
    }

    // When batch status refreshes, sync the counts from it
    final s = widget.statusInfo;
    if (s != null) {
      if (mounted) {
        setState(() {
          _isLiked = s['isLiked'] as bool? ?? _isLiked;
          _isBookmarked = s['isBookmarked'] as bool? ?? _isBookmarked;
          _bookmarkCount = s['bookmarkCount'] as int? ?? _bookmarkCount;
          _isFollowing = s['isFollowing'] as bool? ?? _isFollowing;
          _likeCount = s['likeCount'] as int? ?? _likeCount;
          _commentCount = s['commentCount'] as int? ?? _commentCount;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final res = await ApiService().dio.get('/like/${widget.video.id}/status');
      if (mounted) setState(() => _isLiked = res.data['liked'] == true);
    } catch (_) {}
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final res = await ApiService().dio.get('/bookmark/${widget.video.id}/status');
      if (mounted) setState(() => _isBookmarked = res.data['bookmarked'] == true);
    } catch (_) {}
  }

  Future<void> _fetchBookmarkCount() async {
    try {
      final res = await ApiService().dio.get('/bookmark/${widget.video.id}/count');
      if (mounted) setState(() => _bookmarkCount = res.data['count'] ?? 0);
    } catch (_) {}
  }

  Future<void> _checkFollowStatus() async {
    try {
      final authorId = widget.video.author['id']?.toString();
      if (authorId == null) return;
      final res = await ApiService().dio.get('/follow/$authorId/status');
      if (mounted) setState(() => _isFollowing = res.data['following'] == true);
    } catch (_) {}
  }

  void _toggleBookmark() {
    if (_bookmarkLoading) return;
    HapticFeedback.lightImpact();
    _bookmarkLoading = true;

    final wasBookmarked = _isBookmarked;
    setState(() {
      _isBookmarked = !_isBookmarked;
      _bookmarkCount += _isBookmarked ? 1 : -1;
    });

    ApiService().dio.post('/bookmark/${widget.video.id}').then((res) {
      if (mounted) {
        setState(() => _isBookmarked = res.data['bookmarked'] == true);
      }
      _bookmarkLoading = false;
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _isBookmarked = wasBookmarked;
          _bookmarkCount += wasBookmarked ? 1 : -1;
        });
      }
      _bookmarkLoading = false;
    });
  }

  void _toggleFollow() {
    HapticFeedback.lightImpact();
    final authorId = widget.video.author['id']?.toString();
    if (authorId == null) return;

    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);

    final messenger = ScaffoldMessenger.of(context);
    ApiService().dio.post('/follow/$authorId').then((res) {
      if (mounted) setState(() => _isFollowing = res.data['following'] == true);
    }).catchError((_) {
      if (mounted) {
        setState(() => _isFollowing = wasFollowing);
        messenger.showSnackBar(
          const SnackBar(content: Text('操作失败，请重试'), behavior: SnackBarBehavior.floating),
        );
      }
    });
  }

  void _messageAuthor() {
    HapticFeedback.lightImpact();
    final author = widget.video.author;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: '',
          otherParticipant: author,
        ),
      ),
    );
  }

  Future<void> _initVideo() async {
    if (_fetching) return;
    _fetching = true;
    if (mounted) setState(() {});

    final url = await _fetchStreamUrl(widget.video.id);
    if (url == null) {
      _fetching = false;
      _loadFailed = true;
      if (mounted) setState(() {});
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();
    } catch (_) {
      _fetching = false;
      _loadFailed = true;
      if (mounted) setState(() {});
      return;
    }

    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0 : 1);
    _fetching = false;
    if (mounted) {
      setState(() {});
      if (widget.isCurrent && widget.isGloballyPlaying) controller.play();
    }
  }

  Future<String?> _fetchStreamUrl(String videoId) async {
    try {
      final res = await ApiService().dio.get('/video/$videoId/stream');
      return res.data['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _retry() async {
    _loadFailed = false;
    if (mounted) setState(() {});
    await _initVideo();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    if (!_isLiked) {
      setState(() {
        _isLiked = true;
        _likeCount += 1;
        _heartBurst = const HeartBurst();
      });
      // Send like to server
      _likeLoading = true;
      ApiService().dio.post('/like/${widget.video.id}').then((res) {
        if (mounted) setState(() => _isLiked = res.data['liked'] == true);
        _likeLoading = false;
      }).catchError((_) {
        _likeLoading = false;
      });
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _heartBurst = null);
    });
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      widget.onPlayPauseChanged(false);
    } else {
      c.play();
      widget.onPlayPauseChanged(true);
    }
  }

  void _toggleLike() {
    if (_likeLoading) return;
    HapticFeedback.lightImpact();
    _likeLoading = true;

    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    ApiService().dio.post('/like/${widget.video.id}').then((res) {
      if (mounted) setState(() => _isLiked = res.data['liked'] == true);
      _likeLoading = false;
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试'), behavior: SnackBarBehavior.floating),
        );
      }
      _likeLoading = false;
    });
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMuted = !_isMuted;
      _controller?.setVolume(_isMuted ? 0 : 1);
    });
  }

  Future<List<Map<String, dynamic>>> _fetchComments() async {
    try {
      final res = await ApiService().dio.get('/comment/${widget.video.id}');
      final items = (res.data['items'] as List?) ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _showCommentSheet() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    final api = ApiService();
    // ignore: use_build_context_synchronously
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentSheet(
        videoId: widget.video.id,
        api: api,
        fetchComments: _fetchComments,
        onCommentCountChanged: (delta) {
          if (mounted) setState(() => _commentCount += delta);
        },
      ),
    );
  }

  void _showShareSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: _dkS1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: _dkBorder, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('分享到', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(icon: Icons.chat_bubble_rounded, label: '私信', color: const Color(0xFF8B5CF6), onTap: () {
                    Navigator.pop(ctx);
                    _messageAuthor();
                  }),
                  _ShareOption(icon: Icons.link, label: '复制链接', color: const Color(0xFF06B6D4), onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: 'video://${widget.video.id}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('视频链接已复制'), behavior: SnackBarBehavior.floating),
                    );
                  }),
                  _ShareOption(icon: Icons.download, label: '保存', color: const Color(0xFF22C55E), onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('功能开发中'), behavior: SnackBarBehavior.floating),
                    );
                  }),
                  _ShareOption(icon: Icons.report, label: '举报', color: const Color(0xFFF59E0B), onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已收到举报'), behavior: SnackBarBehavior.floating),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: _dkS2,
                    foregroundColor: _textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('取消', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void togglePlayPause() {
    HapticFeedback.lightImpact();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      widget.onPlayPauseChanged(false);
    } else {
      c.play();
      widget.onPlayPauseChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _controller != null && _controller!.value.isInitialized;
    final video = widget.video;
    final authorName = (video.author['nickname'] ?? video.author['username'] ?? '').toString();
    final authorInitial = authorName.isNotEmpty ? authorName.characters.first.toUpperCase() : '?';

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video or black bg
            if (hasVideo)
              VideoPlayer(_controller!)
            else
              Container(color: Colors.black),

            // Top gradient
            const Positioned(
              top: 0, left: 0, right: 0, height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Bottom gradient
            const Positioned(
              bottom: 0, left: 0, right: 0, height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Loading / error
            if (!hasVideo)
              Center(
                child: _loadFailed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          const Text('视频加载失败', style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _retry, child: const Text('重试')),
                        ],
                      )
                    : const CircularProgressIndicator(color: Colors.white38),
              ),

            // Play overlay
            AnimatedOpacity(
              opacity: (hasVideo && !_controller!.value.isPlaying) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: (hasVideo && _controller!.value.isPlaying),
                child: Center(
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
                  ),
                ),
              ),
            ),

            // Mute toggle (top-right)
            if (hasVideo)
              Positioned(
                top: 120, right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white70, size: 18,
                    ),
                  ),
                ),
              ),

            // Heart burst
            if (_heartBurst != null)
              const Center(child: HeartBurst()),

            // Bottom-left video info
            Positioned(
              bottom: 90, left: 14, right: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('@${(video.author['username'] ?? '').toString()}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _isFollowing ? _textMuted : _red, width: 1),
                          ),
                          child: Text(
                            _isFollowing ? '已关注' : '关注',
                            style: TextStyle(color: _isFollowing ? _textMuted : _red, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _messageAuthor,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.mail_outline, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(video.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.music_note, size: 13, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text('原声 · $authorName', style: const TextStyle(color: _textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Right action bar
            Positioned(
              bottom: 100, right: 10,
              child: DouyinActionBar(
                isLiked: _isLiked,
                likeCount: _likeCount,
                commentCount: _commentCount,
                bookmarkCount: _bookmarkCount,
                shareCount: 0,
                isBookmarked: _isBookmarked,
                authorAvatar: video.author['avatar']?.toString() ?? '',
                authorInitial: authorInitial,
                onLike: _toggleLike,
                onComment: _showCommentSheet,
                onBookmark: _toggleBookmark,
                onShare: _showShareSheet,
                onFollow: _toggleFollow,
              ),
            ),

            // Progress bar
            if (hasVideo)
              Positioned(
                bottom: 76, left: 8, right: 74,
                child: _VideoProgress(controller: _controller!),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Progress bar ──

class _VideoProgress extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoProgress({required this.controller});

  @override
  State<_VideoProgress> createState() => _VideoProgressState();
}

class _VideoProgressState extends State<_VideoProgress> {
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted && !_isSeeking) setState(() {});
  }

  void _seekTo(double value) {
    final duration = widget.controller.value.duration;
    if (duration.inMilliseconds == 0) return;
    final target = Duration(milliseconds: (value * duration.inMilliseconds).round());
    widget.controller.seekTo(target);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.controller.value;
    final durationMs = v.duration.inMilliseconds;
    final positionMs = v.position.inMilliseconds;
    final pos = durationMs > 0 ? positionMs / durationMs : 0.0;

    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: _red,
        inactiveTrackColor: Color(0x33FFFFFF),
        thumbColor: _red,
        overlayColor: Color(0x1AFE2C55),
      ),
      child: Slider(
        value: pos.clamp(0.0, 1.0),
        onChangeStart: (_) => _isSeeking = true,
        onChanged: _seekTo,
        onChangeEnd: (_) {
          _isSeeking = false;
        },
      ),
    );
  }
}

// ── Capsule button ──

class _CapsuleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CapsuleButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Comment sheet ──

class _CommentSheet extends StatefulWidget {
  final String videoId;
  final ApiService api;
  final Future<List<Map<String, dynamic>>> Function() fetchComments;
  final ValueChanged<int> onCommentCountChanged;

  const _CommentSheet({
    required this.videoId,
    required this.api,
    required this.fetchComments,
    required this.onCommentCountChanged,
  });

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _textController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await widget.fetchComments();
    if (mounted) {
      setState(() {
        _comments = comments;
        _loading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final data = <String, dynamic>{'content': content};
      if (_replyToId != null) data['parentId'] = _replyToId;
      await widget.api.dio.post('/comment/${widget.videoId}', data: data);
      if (!mounted) return;
      _textController.clear();
      widget.onCommentCountChanged(1);
      _replyToId = null;
      _replyToName = null;
      await _loadComments();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论失败'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom.clamp(0.0, 600.0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6 + bottomInset,
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
            padding: const EdgeInsets.only(left: 20, right: 16, top: 14, bottom: 10),
            child: Row(
              children: [
                const Text('评论', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _dkS2, borderRadius: BorderRadius.circular(10)),
                  child: Text('${_comments.length}', style: const TextStyle(fontSize: 12, color: _textMuted)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _dkBorder),
          Expanded(child: _buildCommentList()),
          Container(
            padding: EdgeInsets.fromLTRB(14, 8, 8, bottomInset > 0 ? 8 : 14),
            decoration: const BoxDecoration(
              color: _dkS1,
              border: Border(top: BorderSide(color: _dkBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: _dkS2, borderRadius: BorderRadius.circular(22)),
                      child: TextField(
                        controller: _textController,
                        maxLines: 3, minLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: _replyToName != null ? '回复 @$_replyToName...' : '说点什么...',
                          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          isDense: true,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.emoji_emotions_outlined, size: 18, color: Colors.grey[600]),
                          ),
                          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _red),
                    child: IconButton(
                      onPressed: _sending ? null : _sendComment,
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
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

  Widget _buildCommentList() {
    if (_loading) {
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

    // Build flat list with depth info: top-level depth=0, replies depth=1
    final flatList = <_FlatComment>[];
    for (final c in _comments) {
      flatList.add(_FlatComment(data: c, depth: 0));
      final children = (c['children'] as List?) ?? [];
      for (final child in children) {
        flatList.add(_FlatComment(data: child as Map<String, dynamic>, depth: 1));
      }
    }

    if (flatList.isEmpty) {
      return Center(
        child: Text('暂无评论，快来抢沙发吧~', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      );
    }

    final gradients = const [
      [Color(0xFFFE2C55), Color(0xFFFF4D6A)],
      [Color(0xFFF59E0B), Color(0xFFF97316)],
      [Color(0xFF8B5CF6), Color(0xFFA855F7)],
      [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
      [Color(0xFF22C55E), Color(0xFF4ADE80)],
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: flatList.length,
      itemBuilder: (context, index) {
        final entry = flatList[index];
        final c = entry.data;
        final user = (c['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final nickname = (user['nickname'] ?? user['username'] ?? '匿名用户').toString();
        final content = (c['content'] ?? '').toString();
        final isReply = entry.depth > 0;
        final grad = gradients[index % gradients.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isReply) const SizedBox(width: 46),
              if (!isReply) ...[
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                  child: Center(
                    child: Text(nickname.characters.first.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (isReply)
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                  child: Center(
                    child: Text(nickname.characters.first.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isReply) ...[
                      Row(
                        children: [
                          Text(nickname, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary)),
                          const SizedBox(width: 6),
                          Text('回复', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (!isReply) ...[
                      Text(nickname, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                      const SizedBox(height: 4),
                    ],
                    Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFFD4D4D8), height: 1.45)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          child: const Icon(Icons.favorite_border, size: 14, color: _textMuted),
                          onTap: () {},
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            final replyName = (c['user']?['nickname'] ?? c['user']?['username'] ?? '').toString();
                            setState(() {
                              _replyToId = c['id']?.toString();
                              _replyToName = replyName;
                            });
                          },
                          child: Text('回复', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlatComment {
  final Map<String, dynamic> data;
  final int depth;
  const _FlatComment({required this.data, required this.depth});
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
