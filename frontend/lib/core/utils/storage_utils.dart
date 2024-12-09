import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

/// Utility class for secure storage operations
class StorageUtils {
  static const _secureStorage = FlutterSecureStorage();
  static final _storage = GetStorage();

  // Token Management
  static Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  static Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // User Data Management
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    await _storage.write('user_data', json.encode(userData));
  }

  static Map<String, dynamic>? getUserData() {
    final data = _storage.read('user_data');
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  static Future<void> clearUserData() async {
    await _storage.remove('user_data');
  }

  // Temporary Email Storage
  static Future<void> setTemporaryEmail(String email) async {
    await _storage.write('temp_email', email);
  }

  static Future<String?> getTemporaryEmail() async {
    return _storage.read('temp_email');
  }

  static Future<void> clearTemporaryEmail() async {
    await _storage.remove('temp_email');
  }

  // Verification State Management
  static Future<void> setVerificationRequired(bool required) async {
    await _storage.write('requires_verification', required);
  }

  static bool getVerificationRequired() {
    return _storage.read('requires_verification') ?? false;
  }

  // General Storage Methods
  static Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _storage.erase();
  }
}
