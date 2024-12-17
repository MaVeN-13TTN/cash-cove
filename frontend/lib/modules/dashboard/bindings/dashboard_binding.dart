import 'package:get/get.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/storage/secure_storage.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../data/repositories/budget_repository.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../data/providers/budget_provider.dart';
import '../../../../data/providers/expense_provider.dart';
import '../../../../data/providers/api_provider.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    final dioClient = Get.find<DioClient>();
    final secureStorage = Get.find<SecureStorage>();

    // Register API Provider with DioClient and SecureStorage
    Get.lazyPut<ApiProvider>(() => ApiProvider(
      dio: dioClient.dio,
      storage: secureStorage,
    ));

    // Ensure providers are registered first
    Get.lazyPut<BudgetProvider>(() => BudgetProvider(Get.find<ApiProvider>()));
    Get.lazyPut<ExpenseProvider>(() => ExpenseProvider(Get.find<ApiProvider>()));

    // Register repositories
    Get.lazyPut<BudgetRepository>(() => BudgetRepository(Get.find<BudgetProvider>()));
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(Get.find<ExpenseProvider>()));

    // Register controller with dependencies
    Get.put<DashboardController>(
      DashboardController(
        budgetRepository: Get.find<BudgetRepository>(),
        expenseRepository: Get.find<ExpenseRepository>(),
      ),
      permanent: true,
    );
  }
}