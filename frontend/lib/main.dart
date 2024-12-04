import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/config/routes/app_pages.dart';

import 'app/bindings/initial_binding.dart';
import 'core/network/dio_client.dart';
import 'core/services/auth/token_manager.dart';
import 'core/services/storage/secure_storage.dart';
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
  await Get.putAsync<TokenManager>(
      () async => await TokenManager.initialize(secureStorage));

  // Initialize DioClient
  await Get.putAsync<DioClient>(() async => await DioClient.initialize(
        baseUrl: baseUrl,
        tokenManager: Get.find<TokenManager>(),
      ));

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
