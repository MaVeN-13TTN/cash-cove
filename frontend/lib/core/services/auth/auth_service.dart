import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../storage/secure_storage.dart';
import '../../utils/logger_utils.dart';

class AuthException implements Exception {
  final String message;
  final dynamic error;

  AuthException(this.message, [this.error]);

  @override
  String toString() => 'AuthException: $message${error != null ? ' ($error)' : ''}';
}

class AuthService extends GetxService {
  final Dio _dio;
  final SecureStorage _storage;
  static const String _baseUrl = '/api/auth';

  // Observable state
  final _isAuthenticated = false.obs;
  bool get isAuthenticated => _isAuthenticated.value;

  AuthService({
    required Dio dio,
    required SecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken == null) {
        throw AuthException('No refresh token available');
      }

      final response = await _dio.post(
        '$_baseUrl/token/refresh/',
        data: {'refresh_token': refreshToken},
      );

      final newToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      await _storage.setToken(newToken);
      await _storage.setRefreshToken(newRefreshToken);
      
      _isAuthenticated.value = true;
    } on DioException catch (e) {
      LoggerUtils.error('Failed to refresh token', e);
      await _storage.clearTokens();
      _isAuthenticated.value = false;
      throw AuthException('Failed to refresh token', e);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      await _storage.setToken(token);
      await _storage.setRefreshToken(refreshToken);
      
      _isAuthenticated.value = true;
    } on DioException catch (e) {
      LoggerUtils.error('Login failed', e);
      throw AuthException('Login failed', e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('$_baseUrl/logout/');
    } catch (e) {
      LoggerUtils.error('Logout failed', e);
    } finally {
      await _storage.clearTokens();
      _isAuthenticated.value = false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/register/',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );
    } on DioException catch (e) {
      LoggerUtils.error('Registration failed', e);
      throw AuthException('Registration failed', e);
    }
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/reset-password/',
        data: {'email': email},
      );
    } on DioException catch (e) {
      LoggerUtils.error('Password reset request failed', e);
      throw AuthException('Password reset request failed', e);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/change-password/',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      LoggerUtils.error('Password change failed', e);
      throw AuthException('Password change failed', e);
    }
  }
}