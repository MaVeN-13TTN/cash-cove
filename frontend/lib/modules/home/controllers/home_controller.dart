import 'package:get/get.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../expense/controllers/expense_controller.dart';
import '../../settings/controllers/settings_controller.dart';

class HomeController extends GetxController {
  // Current tab index
  final RxInt selectedIndex = 0.obs;

  // Retrieve controllers using Get.find
  DashboardController get dashboardController => Get.find<DashboardController>();
  BudgetController get budgetController => Get.find<BudgetController>();
  ExpenseController get expenseController => Get.find<ExpenseController>();
  SettingsController get settingsController => Get.find<SettingsController>();

  // Change tab
  void changeIndex(int index) {
    selectedIndex.value = index;
    // Refresh data of the selected tab
    switch (index) {
      case 0:
        dashboardController.refreshDashboard();
        break;
      case 1:
        budgetController.fetchBudgets();
        break;
      case 2:
        expenseController.fetchExpenses();
        break;
      case 3:
        // Trigger a reactive update for settings
        settingsController.themeMode.refresh();
        break;
    }
  }
}
