import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  bool get isLoggedIn => _user != null;

  Future<void> register(String username, String password, String? nickname) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'nickname': nickname,
      });
      await _api.saveToken(res.data['token']);
      _user = res.data['user'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      await _api.saveToken(res.data['token']);
      _user = res.data['user'];
    } finally {
      _isLoading = false;
      notifyListeners();
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
