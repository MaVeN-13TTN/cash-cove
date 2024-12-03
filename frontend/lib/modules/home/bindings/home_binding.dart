import 'package:get/get.dart';

// Import API provider
import '../../../data/providers/api_provider.dart';

// Import providers
import '../../../data/providers/budget_provider.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/providers/expense_provider.dart';

// Import repositories
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/expense_repository.dart';

// Import controllers
import '../controllers/home_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../expense/controllers/expense_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ApiProvider is registered first
    Get.lazyPut<ApiProvider>(() => ApiProvider(baseUrl: 'https://api.budgettracker.com'));

    // Providers
    Get.lazyPut<BudgetProvider>(() => BudgetProvider(
          Get.find<ApiProvider>(),
        ));
    Get.lazyPut<TransactionProvider>(() => TransactionProvider(
          Get.find<ApiProvider>(),
        ));
    Get.lazyPut<ExpenseProvider>(() => ExpenseProvider(
          Get.find<ApiProvider>(),
        ));

    // Repositories
    Get.lazyPut<BudgetRepository>(() => BudgetRepository(
          Get.find<BudgetProvider>(),
        ));
    Get.lazyPut<TransactionRepository>(() => TransactionRepository(
          Get.find<TransactionProvider>(),
        ));
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(
          Get.find<ExpenseProvider>(),
        ));

    // Core controllers
    Get.lazyPut<HomeController>(() => HomeController());

    // Feature controllers with repositories
    Get.lazyPut<DashboardController>(() => DashboardController(
          budgetRepository: Get.find<BudgetRepository>(),
          transactionRepository: Get.find<TransactionRepository>(),
        ));

    Get.lazyPut<BudgetController>(() => BudgetController(
          repository: Get.find<BudgetRepository>(),
        ));

    Get.lazyPut<ExpenseController>(() => ExpenseController(
          repository: Get.find<ExpenseRepository>(),
        ));

    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}
