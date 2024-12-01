import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/services/api/api_client.dart';
import 'core/services/auth/token_manager.dart';
import 'modules/auth/bindings/auth_binding.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiClient
  final tokenManager = TokenManager();
  await ApiClient.initialize(
    baseUrl: 'YOUR_API_BASE_URL', // Replace with your actual API base URL
    tokenManager: tokenManager,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialBinding: AuthBinding(),
      getPages: AppPages.routes,
      initialRoute: AppPages.INITIAL,
    );
  }
}
