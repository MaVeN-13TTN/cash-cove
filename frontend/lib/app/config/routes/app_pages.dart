import 'package:get/get.dart';
import '../../../modules/splash/screens/splash_screen.dart';
import '../../../modules/splash/bindings/splash_binding.dart';
import '../../../modules/onboarding/screens/onboarding_screen.dart';
import '../../../modules/onboarding/bindings/onboarding_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = [
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
    // Temporarily commented out other routes
    // TODO: Implement remaining routes and their corresponding screens/bindings
    // Auth Pages
    // GetPage(
    //   name: AppRoutes.login,
    //   page: () => const LoginScreen(),
    //   binding: AuthBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.register,
    //   page: () => const RegisterScreen(),
    //   binding: AuthBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.forgotPassword,
    //   page: () => const ForgotPasswordScreen(),
    //   binding: AuthBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.resetPassword,
    //   page: () => const ResetPasswordScreen(),
    //   binding: AuthBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.verifyEmail,
    //   page: () => const VerifyEmailScreen(),
    //   binding: AuthBinding(),
    // ),
    // 
    // // Main Pages
    // GetPage(
    //   name: AppRoutes.home,
    //   page: () => const HomeScreen(),
    //   binding: HomeBinding(),
    //   children: [
    //     GetPage(
    //       name: AppRoutes.dashboard,
    //       page: () => const DashboardScreen(),
    //       binding: DashboardBinding(),
    //     ),
    //     GetPage(
    //       name: AppRoutes.profile,
    //       page: () => const ProfileScreen(),
    //       binding: ProfileBinding(),
    //     ),
    //     GetPage(
    //       name: AppRoutes.settings,
    //       page: () => const SettingsScreen(),
    //       binding: SettingsBinding(),
    //     ),
    //   ],
    // ),
    // 
    // // Budget Pages
    // GetPage(
    //   name: AppRoutes.budgets,
    //   page: () => const BudgetsScreen(),
    //   binding: BudgetBinding(),
    //   children: [
    //     GetPage(
    //       name: '/add',
    //       page: () => const AddBudgetScreen(),
    //     ),
    //     GetPage(
    //       name: '/edit',
    //       page: () => const EditBudgetScreen(),
    //     ),
    //     GetPage(
    //       name: '/details',
    //       page: () => const BudgetDetailsScreen(),
    //     ),
    //     GetPage(
    //       name: '/categories',
    //       page: () => const BudgetCategoriesScreen(),
    //     ),
    //   ],
    // ),
    // 
    // // Transaction Pages
    // GetPage(
    //   name: AppRoutes.transactions,
    //   page: () => const TransactionsScreen(),
    //   binding: TransactionBinding(),
    //   children: [
    //     GetPage(
    //       name: '/add',
    //       page: () => const AddTransactionScreen(),
    //     ),
    //     GetPage(
    //       name: '/edit',
    //       page: () => const EditTransactionScreen(),
    //     ),
    //     GetPage(
    //       name: '/details',
    //       page: () => const TransactionDetailsScreen(),
    //     ),
    //     GetPage(
    //       name: '/categories',
    //       page: () => const TransactionCategoriesScreen(),
    //     ),
    //   ],
    // ),
    // 
    // // Report Pages
    // GetPage(
    //   name: AppRoutes.reports,
    //   page: () => const ReportsScreen(),
    //   binding: ReportBinding(),
    //   children: [
    //     GetPage(
    //       name: '/details',
    //       page: () => const ReportDetailsScreen(),
    //     ),
    //     GetPage(
    //       name: '/export',
    //       page: () => const ExportReportScreen(),
    //     ),
    //   ],
    // ),
    // 
    // // Settings Pages
    // GetPage(
    //   name: AppRoutes.accountSettings,
    //   page: () => const AccountSettingsScreen(),
    //   binding: SettingsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.securitySettings,
    //   page: () => const SecuritySettingsScreen(),
    //   binding: SettingsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.notificationSettings,
    //   page: () => const NotificationSettingsScreen(),
    //   binding: SettingsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.appearanceSettings,
    //   page: () => const AppearanceSettingsScreen(),
    //   binding: SettingsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.currencySettings,
    //   page: () => const CurrencySettingsScreen(),
    //   binding: SettingsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.languageSettings,
    //   page: () => const LanguageSettingsScreen(),
    //   binding: SettingsBinding(),
    // ),
    // 
    // // Help & Support Pages
    // GetPage(
    //   name: AppRoutes.help,
    //   page: () => const HelpScreen(),
    //   binding: SupportBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.support,
    //   page: () => const SupportScreen(),
    //   binding: SupportBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.faq,
    //   page: () => const FAQScreen(),
    //   binding: SupportBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.about,
    //   page: () => const AboutScreen(),
    //   binding: SupportBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.privacyPolicy,
    //   page: () => const PrivacyPolicyScreen(),
    //   binding: SupportBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.termsOfService,
    //   page: () => const TermsOfServiceScreen(),
    //   binding: SupportBinding(),
    // ),
  ];
}