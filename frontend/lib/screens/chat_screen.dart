import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_box.dart';
import '../constants/app_colors.dart';

const _red = appRed;
const _dkS1 = dkSurface1;
const _dkS2 = dkSurface2;
const _textMuted = textMuted;

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherParticipant;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherParticipant,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _sending = false;
  String _conversationId = '';

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId.isNotEmpty) _loadMessages();
    if (mounted) setState(() => _isLoading = _conversationId.isNotEmpty);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_conversationId.isEmpty) return;
    try {
      final res = await _api.dio.get('/message/$_conversationId');
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res.data['items'] ?? []);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final recipientId = widget.otherParticipant['id']?.toString() ?? '';
      final res = await _api.dio.post('/message/send', data: {
        'recipientId': recipientId,
        'content': content,
      });
      _textController.clear();
      // Capture conversationId from first message
      if (_conversationId.isEmpty && res.data['conversationId'] != null) {
        _conversationId = res.data['conversationId'].toString();
      }
      await _loadMessages();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送失败，请重试'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.otherParticipant['nickname'] ?? widget.otherParticipant['username'] ?? '用户').toString();
    final initial = name.characters.first.toUpperCase();
    final grad = avatarGradients[name.hashCode.abs() % avatarGradients.length];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
        backgroundColor: _dkS1,
        appBar: AppBar(
          backgroundColor: _dkS1,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                child: Center(
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            Container(
              padding: EdgeInsets.fromLTRB(12, 8, 8, bottomInset > 0 ? bottomInset : 12),
              decoration: const BoxDecoration(
                color: _dkS1,
                border: Border(top: BorderSide(color: Color(0x15FFFFFF))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _dkS2,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: '发送消息...',
                            hintStyle: TextStyle(color: _textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _red),
                      child: IconButton(
                        onPressed: _sending ? null : _sendMessage,
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

  Widget _buildMessageList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: 8,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: i % 2 == 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (i % 2 == 0) ...[
                const ShimmerBox(width: 32, height: 32, radius: 16),
                const SizedBox(width: 8),
              ],
              ShimmerBox(width: 80 + (i * 30).toDouble(), height: 36, radius: 18),
              if (i % 2 != 0) ...[
                const SizedBox(width: 8),
                const ShimmerBox(width: 32, height: 32, radius: 16),
              ],
            ],
          ),
        ),
      );
    }

    if (_conversationId.isEmpty) {
      return const Center(
        child: Text('发送第一条消息开始聊天', style: TextStyle(color: _textMuted, fontSize: 13)),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text('暂无消息，发送一条消息吧~', style: TextStyle(color: _textMuted, fontSize: 13)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final sender = msg['sender'] as Map<String, dynamic>? ?? {};
        final content = (msg['content'] ?? '').toString();
        final currentUserId = context.read<AuthProvider>().user?['id']?.toString() ?? '';
        final isSent = sender['id']?.toString() == currentUserId;
        final senderName = (sender['nickname'] ?? sender['username'] ?? '').toString();
        final initial = senderName.isNotEmpty ? senderName.characters.first.toUpperCase() : '?';
        final grad = avatarGradients[senderName.hashCode.abs() % avatarGradients.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSent) ...[
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                  child: Center(
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSent ? _red : _dkS2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isSent ? 18 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 18),
                    ),
                  ),
                  child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: grad)),
                  child: Center(
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
