import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../data/repositories/budget_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/providers/budget_provider.dart';
import '../../../../data/providers/transaction_provider.dart';
import '../../../../data/providers/api_provider.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register API Provider with base URL
    Get.lazyPut<ApiProvider>(() => ApiProvider(
      baseUrl: 'https://your-api-base-url.com/api/v1', // Replace with your actual base URL
    ));

    // Ensure providers are registered first
    Get.lazyPut<BudgetProvider>(() => BudgetProvider(Get.find<ApiProvider>()));
    Get.lazyPut<TransactionProvider>(() => TransactionProvider(Get.find<ApiProvider>()));

    // Register repositories
    Get.lazyPut<BudgetRepository>(() => BudgetRepository(Get.find<BudgetProvider>()));
    Get.lazyPut<TransactionRepository>(() => TransactionRepository(Get.find<TransactionProvider>()));

    // Register controller with dependencies
    Get.lazyPut<DashboardController>(() => DashboardController(
      budgetRepository: Get.find<BudgetRepository>(),
      transactionRepository: Get.find<TransactionRepository>(),
    ));
  }
}