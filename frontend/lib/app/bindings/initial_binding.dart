import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/auth/token_manager.dart';
import '../../core/widgets/dialogs/dialog_service.dart';
import '../../modules/auth/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() async {
    // Global Navigator Key
    final navigatorKey = GlobalKey<NavigatorState>();
    Get.put(navigatorKey, permanent: true);

    // Dio Instance
    final dio = Dio();
    Get.put(dio, permanent: true);

    // Core Services Initialization
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs, permanent: true);

    // Secure Storage
    final secureStorage = await SecureStorage.initialize();
    Get.put<SecureStorage>(secureStorage, permanent: true);

    // Token Manager
    final tokenManager = await TokenManager.initialize(secureStorage);
    Get.put<TokenManager>(tokenManager, permanent: true);

    // Dialog Service
    final dialogService = DialogService(navigatorKey: navigatorKey);
    Get.put<DialogService>(dialogService, permanent: true);

    // Auth Service
    final authService = AuthService(
      dio: dio, 
      storage: secureStorage,
    );
    Get.put<AuthService>(authService, permanent: true);

    // DioClient
    final dioClient = await DioClient.initialize(
      baseUrl: 'http://127.0.0.1:8000/api/v1', 
      tokenManager: tokenManager,
    );
    Get.put<DioClient>(dioClient, permanent: true);

    // Auth Controller
    Get.put<AuthController>(
      AuthController(dioClient: dioClient),
      permanent: true,
    );
  }
}
