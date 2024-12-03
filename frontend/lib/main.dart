import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/bindings/initial_binding.dart';
import 'core/services/api/api_client.dart';
import 'core/services/auth/token_manager.dart';
import 'core/services/storage/secure_storage.dart';
import 'routes/app_pages.dart';
import 'modules/auth/controllers/auth_controller.dart';

const String baseUrl = 'http://127.0.0.1:8000/api/v1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('app_storage');
  await Hive.openBox('blacklist_storage');
  await Hive.openBox<String>('offline_requests');
  await Hive.openBox('budgets'); // Open the budgets box

  // Initialize GetX bindings first
  Get.put(InitialBinding());
  InitialBinding().dependencies();

  // Initialize SecureStorage
  final secureStorage = await SecureStorage.initialize();
  Get.put(secureStorage);

  // Initialize TokenManager
  final tokenManager = await TokenManager.initialize(secureStorage);

  // Initialize ApiClient
  final apiClient = await ApiClient.initialize(
    baseUrl: baseUrl,  
    tokenManager: tokenManager,
  );
  Get.put(apiClient);

  // Initialize AuthController
  Get.put(AuthController(
    apiClient: apiClient,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return GetMaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: InitialBinding(),
      initialRoute: authController.isAuthenticated ? Routes.home : Routes.login,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
