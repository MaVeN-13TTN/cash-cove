import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/widgets/dialogs/dialog_service.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../core/services/api/api_client.dart';
import '../../core/services/auth/token_manager.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() async {
    // Initialize Dio
    final dio = Dio();

    // Initialize SecureStorage
    final secureStorage = await SecureStorage.initialize();
    Get.put(secureStorage, permanent: true);

    // Create a GlobalKey for Navigator
    final navigatorKey = GlobalKey<NavigatorState>();

    // Initialize AuthService
    Get.put(AuthService(dio: dio, storage: secureStorage), permanent: true);

    // Initialize DialogService
    Get.put(DialogService(navigatorKey: navigatorKey), permanent: true);

    // Initialize TokenManager
    final tokenManager = await TokenManager.initialize(secureStorage);
    Get.put(tokenManager, permanent: true);

    // Initialize ApiClient using its static initialize method
    final apiClient = await ApiClient.initialize(
      baseUrl: 'http://127.0.0.1:8000/api/v1', 
      tokenManager: tokenManager,
    );
    Get.put(apiClient, permanent: true);

    // Initialize AuthController
    Get.put(
      AuthController(
        apiClient: apiClient,
      ),
      permanent: true,
    );
  }
}