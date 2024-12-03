import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dashboard/views/dashboard_view.dart';
import '../../budget/views/budget_list_view.dart';
import '../../expense/views/expense_list_view.dart';
import '../../analytics/views/analytics_view.dart';
import '../controllers/home_controller.dart';
import 'widgets/custom_bottom_nav_bar.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: [
          const DashboardView(),
          const BudgetListView(),
          const ExpenseListView(),
          const AnalyticsView(),
        ],
      )),
      bottomNavigationBar: Obx(() => CustomBottomNavBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changeTab,
      )),
    );
  }
}
