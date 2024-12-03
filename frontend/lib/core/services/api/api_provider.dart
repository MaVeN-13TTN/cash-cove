import 'package:get/get.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';
import '../auth/token_manager.dart';

/// Provides a singleton instance of ApiClient for the entire app
class ApiProvider extends GetxService {
  late final ApiClient client;

  ApiProvider();

  /// Initialize the API provider
  static Future<ApiProvider> init() async {
    final storage = Get.find<SecureStorage>();
    final apiClient = await ApiClient.initialize(
      baseUrl: 'http://127.0.0.1:8000/api/v1', 
      tokenManager: await TokenManager.initialize(storage),
    );
    return Get.put(ApiProvider()..client = apiClient);
  }

  /// Get the API client instance
  static ApiClient get to => Get.find<ApiProvider>().client;
}