import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  bool get isLoggedIn => _user != null;

  String? _error;
  String? get error => _error;

  Future<void> register(String username, String password, String? nickname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'nickname': nickname,
      });
      await _api.saveToken(res.data['token']);
      _user = res.data['user'];
    } on DioException catch (e) {
      _error = _extractError(e);
    } catch (e) {
      _error = '网络连接失败，请检查网络设置';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      await _api.saveToken(res.data['token']);
      _user = res.data['user'];
    } on DioException catch (e) {
      _error = _extractError(e);
    } catch (e) {
      _error = '网络连接失败，请检查网络设置';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.connectionError:
        return '无法连接服务器，请检查网络设置';
      case DioExceptionType.badResponse:
        final msg = e.response?.data;
        if (msg is Map) return msg['message']?.toString() ?? '请求失败';
        return '请求失败 (${e.response?.statusCode})';
      default:
        return '网络错误，请稍后重试';
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      final res = await _api.dio.get('/auth/profile');
      _user = res.data;
      notifyListeners();
    } catch (_) {
      await _api.clearToken();
    }
  }
}
