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
  static const String _baseUrl = '/auth';

  // Observable state
  final _isAuthenticated = false.obs;
  bool get isAuthenticated => _isAuthenticated.value;

  // User model or identifier
  final Rx<Map<String, dynamic>?> _currentUser = Rx<Map<String, dynamic>?>(null);

  // Getter for current user
  String? get currentUser => _currentUser.value?['id'];

  // Getters for user details
  String get email => _currentUser.value?['email'] ?? '';
  String get displayName => _currentUser.value?['display_name'] ?? _currentUser.value?['username'] ?? '';

  // Method to set current user
  void setCurrentUser(Map<String, dynamic>? user) {
    _currentUser.value = user;
  }

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
        data: {'refresh': refreshToken},
      );

      final newToken = response.data['access'];
      final newRefreshToken = response.data['refresh'];

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
        '$_baseUrl/token/',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Backend returns tokens directly in response data
      final token = response.data['access'];
      final refreshToken = response.data['refresh'];

      await _storage.setToken(token);
      await _storage.setRefreshToken(refreshToken);
      
      // Try to get user profile after successful login
      try {
        final userResponse = await _dio.get(
          '$_baseUrl/profile/',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );
        setCurrentUser(userResponse.data);
      } catch (e) {
        LoggerUtils.error('Failed to fetch user profile', e);
      }
      
      _isAuthenticated.value = true;
    } on DioException catch (e) {
      LoggerUtils.error('Login failed', e);
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid email or password');
      }
      throw AuthException('Login failed', e);
    }
  }

  void handleAuthError() {
    // Logout the user
    logout().then((_) {
      // Navigate to login screen
      Get.offAllNamed('/login');
    }).catchError((error) {
      LoggerUtils.error('Error during auth error handling', error);
    });
  }

  Future<void> logout() async {
    try {
      // Clear local storage
      await _storage.clearTokens();
      
      // Update authentication state
      _isAuthenticated.value = false;
    } catch (e) {
      LoggerUtils.error('Logout failed', e);
      rethrow;
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
          'confirm_password': password,
          'terms_accepted': true,
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

  Future<void> deleteAccount() async {
    try {
      // Perform account deletion API call
      await _dio.delete('$_baseUrl/account/');

      // Clear local storage and reset authentication state
      await _storage.clearTokens();
      _isAuthenticated.value = false;
      _currentUser.value = null;

      // Log the account deletion
      LoggerUtils.info('User account deleted successfully');
    } catch (e) {
      // Handle potential errors during account deletion
      LoggerUtils.error('Failed to delete account', e);
      throw AuthException('Failed to delete account', e);
    }
  }

  Future<void> signOut() async {
    try {
      // Perform sign out API call if needed
      await _dio.post('$_baseUrl/logout/');

      // Clear local storage and reset authentication state
      await _storage.clearTokens();
      _isAuthenticated.value = false;
      _currentUser.value = null;

      // Log the sign out
      LoggerUtils.info('User signed out successfully');
    } catch (e) {
      // Handle potential errors during sign out
      LoggerUtils.error('Failed to sign out', e);
      throw AuthException('Failed to sign out', e);
    }
  }
}