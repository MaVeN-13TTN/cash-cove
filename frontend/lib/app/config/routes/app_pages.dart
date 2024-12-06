import 'package:get/get.dart';
import '../../../modules/splash/screens/splash_screen.dart';
import '../../../modules/splash/bindings/splash_binding.dart';
import '../../../modules/onboarding/screens/onboarding_screen.dart';
import '../../../modules/onboarding/bindings/onboarding_binding.dart';
import '../../../modules/auth/views/login_view.dart';
import '../../../modules/auth/views/signup_view.dart';
import '../../../modules/auth/views/forgot_password_view.dart';
import '../../../modules/auth/bindings/auth_binding.dart';
import '../../../modules/home/views/home_view.dart';
import '../../../modules/home/bindings/home_binding.dart';
import '../../../modules/dashboard/views/dashboard_view.dart';
import '../../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../../modules/settings/views/settings_view.dart';
import '../../../modules/settings/bindings/settings_binding.dart';
import '../../../modules/expense/views/expense_view.dart';
import '../../../modules/expense/bindings/expense_binding.dart';
import '../../../modules/budget/views/budget_view.dart';
import '../../../modules/budget/bindings/budget_binding.dart';
import '../../../modules/analytics/views/analytics_view.dart';
import '../../../modules/analytics/bindings/analytics_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    // Auth Pages
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => ForgotPasswordView(),
      binding: AuthBinding(),
    ),
    // Main Pages
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    // Expenses
    GetPage(
      name: '/expenses',
      page: () => const ExpenseView(),
      binding: ExpenseBinding(),
    ),
    // Budgets
    GetPage(
      name: '/budgets',
      page: () => const BudgetView(),
      binding: BudgetBinding(),
    ),
    // Analytics
    GetPage(
      name: '/analytics',
      page: () => const AnalyticsView(),
      binding: AnalyticsBinding(),
    ),
    // Remaining routes will be implemented as their screens are developed:
    // - Profile
    // - Transaction related screens
  ];
}
