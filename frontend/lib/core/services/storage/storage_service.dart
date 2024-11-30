/// Abstract class defining storage service interface
abstract class StorageService {
  /// Initialize storage service
  Future<void> init();

  /// Read value from storage
  Future<String?> read(String key);

  /// Write value to storage
  Future<void> write(String key, String value);

  /// Delete value from storage
  Future<void> delete(String key);

  /// Clear all values from storage
  Future<void> clear();

  /// Check if key exists in storage
  Future<bool> containsKey(String key);

  /// Get all keys from storage
  Future<List<String>> getAllKeys();
}