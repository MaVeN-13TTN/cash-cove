import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/auth/token_manager.dart';
import '../../core/services/dialog/dialog_service.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../core/services/hive_service.dart';
import '../../data/providers/api_provider.dart';
import '../../core/services/error/error_service.dart';
import '../../data/repositories/expense_repository.dart'; // Ensure ExpenseRepository is imported
import '../../data/providers/expense_provider.dart'; // Ensure ExpenseProvider is imported

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    // Global Navigator Key
    final navigatorKey = GlobalKey<NavigatorState>();
    Get.put(navigatorKey, permanent: true);

    // Initialize Hive
    final hiveService = HiveService();
    await hiveService.initializeHive();

    // Open necessary Hive boxes
    await hiveService.getTokenBlacklistBox();
    await hiveService.getAppStorageBox();
    await hiveService.getBlacklistStorageBox();
    await hiveService.getOfflineRequestsBox();
    await hiveService.getBudgetsBox();
    await hiveService.getExpensesBox();

    // SharedPreferences Initialization
    try {
      if (!Get.isRegistered<SharedPreferences>()) {
        final prefs = await SharedPreferences.getInstance();
        Get.put<SharedPreferences>(prefs, permanent: true);
        debugPrint('SharedPreferences initialized successfully');
      } else {
        debugPrint('SharedPreferences already registered');
      }
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }

    // Dio Instance
    final dio = Dio();
    Get.put(dio, permanent: true);

    // Core Services Initialization

    // Secure Storage
    final secureStorage = await SecureStorage.initialize();
    Get.put<SecureStorage>(secureStorage, permanent: true);

    // Token Manager
    final tokenManager = await TokenManager.initialize(secureStorage);
    Get.put<TokenManager>(tokenManager, permanent: true);

    // Initialize DialogService with navigator key
    final dialogService = DialogService(navigatorKey: Get.find<GlobalKey<NavigatorState>>());
    Get.put<DialogService>(dialogService, permanent: true);

    // Error Service
    Get.put(ErrorService(), permanent: true);

    // Auth Service
    final authService = AuthService(
      dio: dio, 
      storage: secureStorage,
    );
    Get.put<AuthService>(authService, permanent: true);

    // DioClient
    final dioClient = await DioClient.initialize(
      baseUrl: 'http://127.0.0.1:8000/api/v1',
      tokenManager: Get.find<TokenManager>(),
      dialogService: Get.find<DialogService>(),
      authService: Get.find<AuthService>(),
    );
    Get.put<DioClient>(dioClient, permanent: true);

    // Auth Controller
    Get.put<AuthController>(
      AuthController(
        dioClient: dioClient,
        dialogService: Get.find<DialogService>(),
      ),
      permanent: true,
    );

    // API Provider
    final apiProvider = ApiProvider(
      dio: dioClient.dio,
      storage: Get.find<SecureStorage>(),
    );
    Get.put<ApiProvider>(apiProvider, permanent: true);

    // Expense Provider
    final expenseProvider = ExpenseProvider(apiProvider);
    Get.put<ExpenseProvider>(expenseProvider, permanent: true);

    // Expense Repository
    final expenseRepository = ExpenseRepository(expenseProvider);
    Get.put<ExpenseRepository>(expenseRepository, permanent: true);
  }
}
