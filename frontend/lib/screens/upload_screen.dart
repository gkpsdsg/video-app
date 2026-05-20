import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

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
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _videoFile = video);
    }
  }

  Future<void> _upload() async {
    if (_videoFile == null) return;

    setState(() => _isUploading = true);

    try {
      final api = ApiService();
      final bytes = await _videoFile!.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: _videoFile!.name,
        ),
        'title': _titleController.text.isNotEmpty
            ? _titleController.text
            : _videoFile!.name,
      });

      await api.dio.post('/video/upload', data: formData, onSendProgress: (sent, total) {
        if (total > 0) {
          setState(() => _uploadProgress = sent / total);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功！')),
        );
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${e.message}')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('上传视频')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '视频标题（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: OutlinedButton(
                onPressed: _isUploading ? null : _pickVideo,
                child: _videoFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, size: 48),
                          SizedBox(height: 8),
                          Text('点击选择视频'),
                        ],
                      )
                    : Text('已选择: ${_videoFile!.name}'),
              ),
            ),
            const SizedBox(height: 16),
            if (_isUploading)
              LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_videoFile != null && !_isUploading) ? _upload : null,
                child: const Text('上传'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
