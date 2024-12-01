import 'package:get/get.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../expense/controllers/expense_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';

class HomeController extends GetxController {
  // Current tab index
  final RxInt currentIndex = 0.obs;

  // Child controllers
  late final DashboardController dashboardController;
  late final BudgetController budgetController;
  late final ExpenseController expenseController;
  late final AnalyticsController analyticsController;

  @override
  void onInit() {
    super.onInit();
    // Initialize child controllers
    dashboardController = Get.find<DashboardController>();
    budgetController = Get.find<BudgetController>();
    expenseController = Get.find<ExpenseController>();
    analyticsController = Get.find<AnalyticsController>();
  }

  // Change tab
  void changeTab(int index) {
    currentIndex.value = index;
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
        analyticsController.refreshAnalytics();
        break;
    }
  }
}
