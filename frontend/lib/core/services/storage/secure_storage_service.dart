import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../utils/logger_utils.dart';
import 'storage_service.dart';

/// Implementation of StorageService using FlutterSecureStorage
class SecureStorageService extends GetxService implements StorageService {
  late final FlutterSecureStorage _storage;
  
  // Android specific options
  final AndroidOptions _androidOptions = const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // iOS specific options
  final IOSOptions _iosOptions = const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  SecureStorageService() {
    _storage = const FlutterSecureStorage();
  }

  @override
  Future<void> init() async {
    try {
      // Verify storage is working
      await write('test_key', 'test_value');
      await delete('test_key');
      LoggerUtils.info('Secure storage initialized successfully');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to initialize secure storage', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(
        key: key,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to read from secure storage: $key', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(
        key: key,
        value: value,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to write to secure storage: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(
        key: key,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to delete from secure storage: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.deleteAll(
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to clear secure storage', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(
        key: key,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to check key in secure storage: $key', e, stackTrace);
      return false;
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    try {
      final Map<String, String> allValues = await _storage.readAll(
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      return allValues.keys.toList();
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to get all keys from secure storage', e, stackTrace);
      return [];
    }
  }

  /// Initialize and register the secure storage service
  static Future<SecureStorageService> initialize() async {
    final service = SecureStorageService();
    await service.init();
    return Get.put(service);
  }
}