import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user/user_model.dart';
import '../providers/auth_provider.dart';

class AuthRepository {
  final AuthProvider _authProvider;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthRepository(this._authProvider) : _storage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String password) async {
    try {
      final user = await _authProvider.login(email, password);
      await _saveUserData(user);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> register(
      String email, String password, String fullName) async {
    try {
      final user = await _authProvider.register(email, password, fullName);
      await _saveUserData(user);
      return user;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _authProvider.logout();
      await _clearUserData();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData == null) return null;

      return await _authProvider.getCurrentUser();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  Future<void> _saveUserData(UserModel user) async {
    await _storage.write(key: _userKey, value: user.toJson().toString());
  }

  Future<void> _clearUserData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('An unexpected error occurred: $error');
  }
}
