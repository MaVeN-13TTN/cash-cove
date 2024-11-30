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

  // Auth Token
  static Future<void> saveToken(String token) async {
    await saveSecure('auth_token', token);
  }

  static Future<String?> getToken() async {
    return await getSecure('auth_token');
  }

  static Future<void> deleteToken() async {
    await deleteSecure('auth_token');
  }

  // User Data
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await saveMap('user_data', userData);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    return await getMap('user_data');
  }

  static Future<void> deleteUser() async {
    await deleteSecure('user_data');
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
  static Future<void> saveThemeMode(String themeMode) async {
    await saveSecure('app_theme', themeMode);
  }

  static Future<String?> getThemeMode() async {
    return await getSecure('app_theme');
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
}
