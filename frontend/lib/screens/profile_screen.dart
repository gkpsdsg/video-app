import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

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
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('加载失败')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profile['nickname'] ?? profile['username'] ?? '我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundImage: profile['avatar'] != null
                  ? NetworkImage(profile['avatar'])
                  : null,
              child: profile['avatar'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              '@${profile['username']}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(label: '作品', value: '${profile['videoCount'] ?? 0}'),
                _StatColumn(label: '粉丝', value: '${profile['followerCount'] ?? 0}'),
                _StatColumn(label: '关注', value: '${profile['followingCount'] ?? 0}'),
                _StatColumn(label: '获赞', value: '${profile['totalLikes'] ?? 0}'),
              ],
            ),
            const Divider(height: 32),
            if (_videos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('暂无作品', style: TextStyle(color: Colors.grey)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.6,
                ),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  final v = _videos[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.play_circle_outline, size: 32, color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          v['title'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
