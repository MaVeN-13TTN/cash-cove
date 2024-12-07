import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../data/repositories/budget_repository.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../data/providers/budget_provider.dart';
import '../../../../data/providers/expense_provider.dart';
import '../../../../data/providers/api_provider.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register API Provider with base URL
    Get.lazyPut<ApiProvider>(() => ApiProvider(
      baseUrl: 'http://127.0.0.1:8000', // Django development server default port
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