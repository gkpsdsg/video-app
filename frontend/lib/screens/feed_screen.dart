import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';

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
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _pageController = PageController();
  final _api = ApiService();
  List<VideoItem> _videos = [];
  int _currentPage = 0;
  bool _isLoading = true;
  String? _loadError;
  bool _isPlaying = true;
  final Map<String, GlobalKey<_VideoPlayerWidgetState>> _videoKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideos() async {
    try {
      final res = await _api.dio.get('/video/list', queryParameters: {'page': 1, 'limit': 20});
      final items = (res.data['items'] as List).map((v) => VideoItem(
        id: v['id'].toString(),
        title: v['title'] ?? '',
        author: v['author'] is Map<String, dynamic> ? v['author'] : <String, dynamic>{},
        likeCount: v['likeCount'] ?? 0,
        commentCount: v['commentCount'] ?? 0,
      )).toList();
      if (mounted) {
        setState(() {
          _videos = items;
          _isLoading = false;
        });
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

  void _goToPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentPage < _videos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_videos.isEmpty) return;
    final key = _videoKeys[_videos[_currentPage].id];
    key?.currentState?.togglePlayPause();
  }

  void _onPlayPauseChanged(bool isPlaying) {
    if (_isPlaying != isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () {
                setState(() { _isLoading = true; _loadError = null; });
                _fetchVideos();
              }, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_videos.isEmpty) {
      return const Scaffold(body: Center(child: Text('暂无视频')));
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final video = _videos[index];
              final key = _videoKeys.putIfAbsent(video.id, () => GlobalKey<_VideoPlayerWidgetState>());
              return _VideoPlayerWidget(
                key: key,
                video: video,
                isCurrent: index == _currentPage,
                isGloballyPlaying: _isPlaying,
                onPlayPauseChanged: _onPlayPauseChanged,
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 16, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ControlButton(
            icon: Icons.skip_previous,
            label: '上一条',
            onTap: _goToPrevious,
          ),
          const SizedBox(width: 40),
          _ControlButton(
            icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            label: _isPlaying ? '暂停' : '播放',
            onTap: _togglePlayPause,
          ),
          const SizedBox(width: 40),
          _ControlButton(
            icon: Icons.skip_next,
            label: '下一条',
            onTap: _goToNext,
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final VideoItem video;
  final bool isCurrent;
  final bool isGloballyPlaying;
  final ValueChanged<bool> onPlayPauseChanged;

  const _VideoPlayerWidget({
    required this.video,
    required this.isCurrent,
    required this.isGloballyPlaying,
    required this.onPlayPauseChanged,
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

  @override
  void initState() {
    super.initState();
    _likeCount = widget.video.likeCount;
    _commentCount = widget.video.commentCount;
    _checkLikeStatus();
    if (widget.isCurrent) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(_VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      if (_controller != null && _controller!.value.isInitialized) {
        if (widget.isGloballyPlaying) {
          _controller!.play();
        }
      } else if (!_fetching && !_loadFailed) {
        _initVideo();
      }
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _controller?.pause();
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
    _fetching = false;
    if (mounted) {
      setState(() {});
      if (widget.isCurrent && widget.isGloballyPlaying) {
        controller.play();
      }
    }
  }

  Future<String?> _fetchStreamUrl(String videoId) async {
    try {
      final res = await ApiService().dio.get('/video/$videoId/stream');
      final url = res.data['url'] as String?;
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<void> _retry() async {
    _loadFailed = false;
    if (mounted) setState(() {});
    await _initVideo();
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    _likeLoading = true;

    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      final res = await ApiService().dio.post('/like/${widget.video.id}');
      if (mounted) {
        setState(() {
          _isLiked = res.data['liked'] == true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    } finally {
      _likeLoading = false;
    }
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
    final textController = TextEditingController();
    final api = ApiService();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentSheet(
        videoId: widget.video.id,
        textController: textController,
        api: api,
        fetchComments: _fetchComments,
        onCommentCountChanged: (delta) {
          if (mounted) setState(() => _commentCount += delta);
        },
      ),
    );

    textController.dispose();
  }

  void _share() {
    Clipboard.setData(ClipboardData(text: 'video://${widget.video.id}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('视频链接已复制')),
    );
  }

  void togglePlayPause() {
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

    return GestureDetector(
      onTap: () {
        final c = _controller;
        if (c == null || !c.value.isInitialized) return;
        if (c.value.isPlaying) {
          c.pause();
          widget.onPlayPauseChanged(false);
        } else {
          c.play();
          widget.onPlayPauseChanged(true);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo)
            VideoPlayer(_controller!)
          else
            Container(color: Colors.black),

          if (!hasVideo)
            Center(
              child: _loadFailed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                        const SizedBox(height: 8),
                        const Text('视频加载失败', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _retry,
                          child: const Text('重试'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

          if (hasVideo && !_controller!.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 64),
            ),

          // Author + title
          Positioned(
            bottom: 20,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  video.author['nickname'] ?? video.author['username'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // Action buttons
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: _ActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '$_likeCount',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showCommentSheet,
                  child: _ActionButton(
                    icon: Icons.comment,
                    label: '$_commentCount',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _share,
                  child: const _ActionButton(
                    icon: Icons.share,
                    label: '分享',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final String videoId;
  final TextEditingController textController;
  final ApiService api;
  final Future<List<Map<String, dynamic>>> Function() fetchComments;
  final ValueChanged<int> onCommentCountChanged;

  const _CommentSheet({
    required this.videoId,
    required this.textController,
    required this.api,
    required this.fetchComments,
    required this.onCommentCountChanged,
  });

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
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
    final content = widget.textController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.api.dio.post('/comment/${widget.videoId}', data: {
        'content': content,
      });
      widget.textController.clear();
      widget.onCommentCountChanged(1);
      await _loadComments();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 16, top: 12),
            child: Row(
              children: [
                const Text('评论', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${_comments.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(child: _buildCommentList()),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, bottomInset > 0 ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.textController,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: '说点什么...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.deepPurple),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return Center(
        child: Text('暂无评论，快来抢沙发吧~',
            style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = _comments[index];
        final user = (c['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final nickname = (user['nickname'] ?? user['username'] ?? '匿名用户').toString();
        final content = (c['content'] ?? '').toString();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.deepPurple[50],
                child: Text(
                  nickname.characters.first.toUpperCase(),
                  style: TextStyle(
                    color: Colors.deepPurple[700],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Text(content, style: const TextStyle(fontSize: 15)),
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
