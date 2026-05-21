import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

const _surface1 = Color(0xFF0C0C0C);
const _surface2 = Color(0xFF1A1A1A);
const _surface3 = Color(0xFF262626);
const _violet500 = Color(0xFF8B5CF6);
const _violet400 = Color(0xFFA78BFA);
const _violet300 = Color(0xFFC4B5FD);
const _textMuted = Color(0xFF71717A);
const _textSecondary = Color(0xFFA1A1AA);

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _videoFile;
  double _uploadProgress = 0;
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    HapticFeedback.lightImpact();
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _videoFile = video);
    }
  }

  Future<void> _upload() async {
    if (_videoFile == null) return;
    HapticFeedback.mediumImpact();

    setState(() => _isUploading = true);

    try {
      final api = ApiService();
      final bytes = await _videoFile!.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: _videoFile!.name),
        'title': _titleController.text.isNotEmpty ? _titleController.text : _videoFile!.name,
      });

      await api.dio.post('/video/upload', data: formData, onSendProgress: (sent, total) {
        if (total > 0) {
          setState(() => _uploadProgress = sent / total);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功！'), behavior: SnackBarBehavior.floating),
        );
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${e.message}'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: '关闭',
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Text('发布视频', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  Semantics(
                    button: true,
                    label: '发布',
                    child: TextButton(
                      onPressed: (_videoFile != null && !_isUploading) ? _upload : null,
                      child: const Text('发布', style: TextStyle(color: _violet300, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Upload zone
                    Semantics(
                      button: true,
                      label: _videoFile != null ? '已选择视频文件，点击重新选择' : '选择视频文件',
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickVideo,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: _surface1,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _videoFile != null ? _violet500 : _surface3,
                              width: _videoFile != null ? 1.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _videoFile != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Container(color: _surface2),
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 56, height: 56,
                                              decoration: BoxDecoration(
                                                color: _violet500.withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check_circle, size: 30, color: _violet400),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(_videoFile!.name,
                                                style: const TextStyle(color: _textSecondary, fontSize: 13),
                                                textAlign: TextAlign.center),
                                            const SizedBox(height: 6),
                                            const Text('点击更换视频',
                                                style: TextStyle(color: _violet300, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(
                                          color: _violet500.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.cloud_upload_outlined, size: 28, color: _violet400),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('选择视频文件',
                                          style: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      const Text('支持 MP4, MOV · 最长 60 秒',
                                          style: TextStyle(color: _textMuted, fontSize: 11)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Caption
                    Semantics(
                      label: '视频描述',
                      hint: '添加描述和标签',
                      child: TextField(
                        controller: _titleController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '添加描述... #标签',
                          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                          filled: true,
                          fillColor: _surface1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _violet500, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Options
                    _OptionCard(icon: Icons.visibility_outlined, label: '谁可以看', value: '公开', onTap: () {}),
                    const SizedBox(height: 8),
                    _OptionCard(icon: Icons.location_on_outlined, label: '添加位置', value: '', onTap: () {}),
                    // Upload progress
                    if (_isUploading) ...[
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: _surface3,
                          color: _violet500,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('上传中 ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: _textMuted, fontSize: 12)),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _OptionCard({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label${value.isNotEmpty ? '，当前：$value' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _surface1,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _textMuted),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 13)),
              const Spacer(),
              if (value.isNotEmpty) ...[
                Text(value, style: const TextStyle(color: _textMuted, fontSize: 13)),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right, size: 18, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
