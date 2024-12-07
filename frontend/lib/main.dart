import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/config/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';
import 'core/network/dio_client.dart';
import 'core/network/dio_api_adapter.dart';
import 'core/services/auth/auth_service.dart';
import 'core/services/storage/secure_storage.dart';
import 'core/services/hive_service.dart';
import 'data/repositories/budget_repository.dart';
import 'data/providers/budget_provider.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'core/services/auth/token_manager.dart';
import 'core/services/api/api_client.dart'; 
import 'core/services/dialog/dialog_service.dart'; // Added import statement

const String baseUrl = 'http://127.0.0.1:8000/api/v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive using the centralized HiveService
  final hiveService = HiveService();
  await hiveService.initializeHive();

  // Open necessary boxes
  await hiveService.getTokenBlacklistBox();
  await hiveService.getAppStorageBox();
  await hiveService.getBlacklistStorageBox();
  await hiveService.getOfflineRequestsBox();
  await hiveService.getBudgetsBox();
  await hiveService.getExpensesBox();

  // Initialize SharedPreferences
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPreferences, permanent: true);

  // Initialize SecureStorage first
  final secureStorage = await SecureStorage.initialize();
  Get.put(secureStorage);

  // Initialize TokenManager before other boxes
  final tokenManager = await TokenManager.initialize(secureStorage);
  Get.put(tokenManager);

  // Initialize GetX bindings
  Get.put(InitialBinding());
  InitialBinding().dependencies();

  // Global Navigator Key
  final navigatorKey = GlobalKey<NavigatorState>();
  Get.put(navigatorKey, permanent: true);

  // Initialize DialogService
  Get.put(DialogService(
    navigatorKey: navigatorKey
  ));

  // Initialize Dio
  final dio = Dio();

  // Initialize AuthService BEFORE DioClient
  final authService = AuthService(
    dio: dio,
    storage: secureStorage,
  );
  Get.put<AuthService>(authService);

  // Initialize ApiClient
  final apiClient = await ApiClient.initialize(
    baseUrl: baseUrl,
    tokenManager: tokenManager,
  );
  Get.put<ApiClient>(apiClient);

  // Initialize DioClient
  await Get.putAsync<DioClient>(() async => await DioClient.initialize(
        baseUrl: baseUrl,
        tokenManager: tokenManager,
      ));

  // Initialize BudgetProvider with DioApiAdapter
  final dioApiAdapter = DioApiAdapter(Get.find<DioClient>());
  final budgetProvider = BudgetProvider(dioApiAdapter);
  final budgetRepository = BudgetRepository(budgetProvider);
  await budgetRepository.init(); // Initialize the repository
  Get.put(budgetRepository);

  // Initialize AuthController
  Get.put(AuthController(
    dioClient: Get.find<DioClient>(),
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Tracker',
      initialRoute: AppPages.initial,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
