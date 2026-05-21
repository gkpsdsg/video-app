import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

const _red = Color(0xFFFE2C55);
const _dkS1 = Color(0xFF111111);
const _dkS2 = Color(0xFF161616);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);
const _textSecondary = Color(0xFFB0B0B0);

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
    if (video != null) setState(() => _videoFile = video);
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
        if (total > 0) setState(() => _uploadProgress = sent / total);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('发布视频', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  TextButton(
                    onPressed: (_videoFile != null && !_isUploading) ? _upload : null,
                    child: const Text('发布', style: TextStyle(color: _red, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    GestureDetector(
                      onTap: _isUploading ? null : _pickVideo,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity, height: 250,
                        decoration: BoxDecoration(
                          color: _dkS1,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _videoFile != null ? _red : _dkBorder, width: _videoFile != null ? 1.5 : 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _videoFile != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(color: _dkS2),
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 56, height: 56,
                                            decoration: BoxDecoration(color: _red.withValues(alpha: 0.15), shape: BoxShape.circle),
                                            child: const Icon(Icons.check_circle, size: 30, color: _red),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(_videoFile!.name, style: const TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
                                          const SizedBox(height: 6),
                                          const Text('点击更换视频', style: TextStyle(color: _red, fontSize: 12)),
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
                                      decoration: BoxDecoration(color: _red.withValues(alpha: 0.08), shape: BoxShape.circle),
                                      child: const Icon(Icons.cloud_upload_outlined, size: 28, color: _red),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('选择视频文件', style: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    const Text('支持 MP4, MOV · 最长 60 秒', style: TextStyle(color: _textMuted, fontSize: 11)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _titleController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: '添加描述... #标签',
                        hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                        filled: true, fillColor: _dkS1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: _red, width: 1.5)),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OptionCard(icon: Icons.visibility_outlined, label: '谁可以看', value: '公开', onTap: () {}),
                    const SizedBox(height: 8),
                    _OptionCard(icon: Icons.location_on_outlined, label: '添加位置', value: '', onTap: () {}),
                    if (_isUploading) ...[
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: _uploadProgress, backgroundColor: _dkS2, color: _red, minHeight: 6),
                      ),
                      const SizedBox(height: 8),
                      Text('上传中 ${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: _textMuted, fontSize: 12)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _dkS1, borderRadius: BorderRadius.circular(14)),
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
    );
  }
}
