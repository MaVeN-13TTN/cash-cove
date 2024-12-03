import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Utility class for secure storage operations
class StorageUtils {
  static const _storage = FlutterSecureStorage();

  /// Saves a value securely
  static Future<void> saveSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Retrieves a securely stored value
  static Future<String?> getSecure(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes a securely stored value
  static Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  /// Saves a map as JSON string
  static Future<void> saveMap(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await saveSecure(key, jsonString);
  }

  /// Retrieves a map from stored JSON string
  static Future<Map<String, dynamic>?> getMap(String key) async {
    final jsonString = await getSecure(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Checks if a key exists in storage
  static Future<bool> containsKey(String key) async {
    final value = await getSecure(key);
    return value != null;
  }

  /// Deletes all stored values
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Gets all stored keys
  static Future<Set<String>> getAllKeys() async {
    final all = await _storage.readAll();
    return all.keys.toSet();
  }

  /// Gets all stored key-value pairs
  static Future<Map<String, String>> getAll() async {
    return await _storage.readAll();
  }

  /// Saves multiple key-value pairs at once
  static Future<void> saveMultiple(Map<String, String> entries) async {
    for (final entry in entries.entries) {
      await saveSecure(entry.key, entry.value);
    }
  }

  // Auth specific methods
  static const _userKey = 'user_data';
  static const _rememberMeKey = 'remember_me';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _savedEmailKey = 'saved_email';

  /// Token-specific storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Saves an authentication token
  static Future<void> saveToken(String type, String token) async {
    await saveSecure(type == 'access_token' ? _accessTokenKey : _refreshTokenKey, token);
  }

  /// Gets the access token
  static Future<String?> getAccessToken() async {
    return await getSecure(_accessTokenKey);
  }

  /// Gets the refresh token
  static Future<String?> getRefreshToken() async {
    return await getSecure(_refreshTokenKey);
  }

  /// Clears authentication tokens
  static Future<void> clearTokens() async {
    await deleteSecure(_accessTokenKey);
    await deleteSecure(_refreshTokenKey);
  }

  /// Saves the user data
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await saveMap(_userKey, userData);
  }

  /// Gets the stored user data
  static Future<Map<String, dynamic>?> getUser() async {
    return await getMap(_userKey);
  }

  /// Deletes the user data
  static Future<void> deleteUser() async {
    await deleteSecure(_userKey);
  }

  /// Saves the remember me preference
  static Future<void> saveRememberMe(bool value) async {
    await saveSecure(_rememberMeKey, value.toString());
  }

  /// Gets the stored remember me preference
  static Future<bool> getRememberMe() async {
    final value = await getSecure(_rememberMeKey);
    return value == 'true';
  }

  /// Saves the biometric authentication preference
  static Future<void> saveBiometricEnabled(bool value) async {
    await saveSecure(_biometricEnabledKey, value.toString());
  }

  /// Gets the stored biometric authentication preference
  static Future<bool> getBiometricEnabled() async {
    final value = await getSecure(_biometricEnabledKey);
    return value == 'true';
  }

  /// Saves the email for remember me feature
  static Future<void> saveEmail(String email) async {
    await saveSecure(_savedEmailKey, email);
  }

  /// Gets the saved email
  static Future<String?> getSavedEmail() async {
    return await getSecure(_savedEmailKey);
  }

  /// Clears all authentication related data
  static Future<void> clearAuthData() async {
    await deleteSecure(_userKey);
    // Don't clear remember me preference and saved email
  }

  // App Settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await saveMap('app_settings', settings);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final settings = await getMap('app_settings');
    return settings ?? {};
  }

  // Theme
  static const _themeKey = 'theme';

  static Future<void> saveTheme(String theme) async {
    await saveSecure(_themeKey, theme);
  }

  static Future<String?> getThemeMode() async {
    return await getSecure(_themeKey);
  }

  // Clear All Data
  static Future<void> clearAll() async {
    await deleteAll();
  }

  // Generic Save/Get methods
  static Future<void> saveData(String key, String value) async {
    await saveSecure(key, value);
  }

  static Future<String?> getData(String key) async {
    return await getSecure(key);
  }

  static Future<void> deleteData(String key) async {
    await deleteSecure(key);
  }

  /// Saves the access token securely
  static Future<void> saveAccessToken(String token) async {
    await saveSecure('access_token', token);
  }

  /// Saves the refresh token securely
  static Future<void> saveRefreshToken(String token) async {
    await saveSecure('refresh_token', token);
  }
}
