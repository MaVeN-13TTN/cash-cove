import 'package:get/get.dart';

// Import API provider
import '../../../data/providers/api_provider.dart';

// Import providers
import '../../../data/providers/budget_provider.dart';
import '../../../data/providers/expense_provider.dart';

// Import repositories
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/expense_repository.dart';

// Import controllers
import '../controllers/home_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../expense/controllers/expense_controller.dart';
import '../../settings/controllers/settings_controller.dart';

// Import services
import '../../../core/services/settings/settings_service.dart';

// Import bindings
import '../../dashboard/bindings/dashboard_binding.dart';
import '../../budget/bindings/budget_binding.dart';
import '../../expense/bindings/expense_binding.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ApiProvider is registered first
    Get.lazyPut<ApiProvider>(() => ApiProvider(baseUrl: 'https://api.budgettracker.com'));

    // Providers
    Get.lazyPut<BudgetProvider>(() => BudgetProvider(
          Get.find<ApiProvider>(),
        ));
    Get.lazyPut<ExpenseProvider>(() => ExpenseProvider(
          Get.find<ApiProvider>(),
        ));

    // Repositories
    Get.lazyPut<BudgetRepository>(() => BudgetRepository(
          Get.find<BudgetProvider>(),
        ));
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository(
          Get.find<ExpenseProvider>(),
        ));

    // Initialize settings service if not already initialized
    if (!Get.isRegistered<SettingsService>()) {
      final settingsService = SettingsService();
      settingsService.onInit();
      Get.put<SettingsService>(settingsService, permanent: true);
    }

    // Core controllers
    Get.lazyPut<HomeController>(() => HomeController());

    // Feature controllers with repositories
    Get.lazyPut<DashboardController>(() => DashboardController(
          budgetRepository: Get.find<BudgetRepository>(),
          expenseRepository: Get.find<ExpenseRepository>(),
        ));

    Get.lazyPut<BudgetController>(() => BudgetController(
          repository: Get.find<BudgetRepository>(),
        ));

    Get.lazyPut<ExpenseController>(() => ExpenseController(
          repository: Get.find<ExpenseRepository>(),
        ));

    // Initialize settings controller
    Get.lazyPut<SettingsController>(() => SettingsController());

    // Apply other bindings
    DashboardBinding().dependencies();
    BudgetBinding().dependencies();
    ExpenseBinding().dependencies();
  }
}
