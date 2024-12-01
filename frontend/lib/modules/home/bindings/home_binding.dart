import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../expense/controllers/expense_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers
    Get.lazyPut<HomeController>(() => HomeController());

    // Feature controllers
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<BudgetController>(() => BudgetController());
    Get.lazyPut<ExpenseController>(() => ExpenseController());
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}
