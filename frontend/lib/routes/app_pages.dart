import 'package:get/get.dart';

import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/signup_view.dart';
import '../modules/auth/views/two_factor_view.dart';
import '../modules/auth/views/forgot_password_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/expense/views/add_expense_view.dart';
import '../modules/expense/views/expense_list_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/notifications/views/notification_list_view.dart';
import '../modules/settings/views/settings_view.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/expense/bindings/expense_binding.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../core/middleware/auth_middleware.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  // Initial route will be determined in main.dart based on auth state
  static const initial = Routes.login;

  static final routes = [
    // Auth Routes
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      middlewares: [
        NoAuthMiddleware(), // Redirect to home if already authenticated
      ],
    ),
    GetPage(
      name: Routes.signup,
      page: () => const SignupView(),
      binding: AuthBinding(),
      middlewares: [
        NoAuthMiddleware(),
      ],
    ),
    GetPage(
      name: Routes.twoFactor,
      page: () => const TwoFactorView(),
      binding: AuthBinding(),
      middlewares: [
        NoAuthMiddleware(),
      ],
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => ForgotPasswordView(),
      binding: AuthBinding(),
      middlewares: [
        NoAuthMiddleware(),
      ],
    ),

    // Protected Routes
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [
        AuthMiddleware(),
      ],
      children: [
        GetPage(
          name: Routes.dashboard,
          page: () => const DashboardView(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: Routes.addExpense,
          page: () => const AddExpenseView(),
          binding: ExpenseBinding(),
        ),
        GetPage(
          name: Routes.expenseList,
          page: () => const ExpenseListView(),
          binding: ExpenseBinding(),
        ),
        GetPage(
          name: Routes.notifications,
          page: () => const NotificationListView(),
          binding: NotificationsBinding(),
        ),
        GetPage(
          name: Routes.settings,
          page: () => const SettingsView(),
          binding: SettingsBinding(),
        ),
      ],
    ),
  ];
}
