import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio dio;
  final _storage = const FlutterSecureStorage();
  String? _cachedToken;
  bool _tokenLoaded = false;

  void init({required String baseUrl}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_tokenLoaded) {
          _cachedToken = await _storage.read(key: 'jwt_token');
          _tokenLoaded = true;
        }
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        handler.next(options);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: 'jwt_token');
  }
}
