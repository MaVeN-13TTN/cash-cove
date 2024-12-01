abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  
  // Main Routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // Budget Routes
  static const String budgets = '/budgets';
  static const String addBudget = '/budgets/add';
  static const String editBudget = '/budgets/edit';
  static const String budgetDetails = '/budgets/details';
  static const String budgetCategories = '/budgets/categories';
  
  // Transaction Routes
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/edit';
  static const String transactionDetails = '/transactions/details';
  static const String transactionCategories = '/transactions/categories';
  
  // Report Routes
  static const String reports = '/reports';
  static const String reportDetails = '/reports/details';
  static const String exportReport = '/reports/export';
  
  // Settings Routes
  static const String accountSettings = '/settings/account';
  static const String securitySettings = '/settings/security';
  static const String notificationSettings = '/settings/notifications';
  static const String appearanceSettings = '/settings/appearance';
  static const String currencySettings = '/settings/currency';
  static const String languageSettings = '/settings/language';
  
  // Help & Support Routes
  static const String help = '/help';
  static const String support = '/support';
  static const String faq = '/faq';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
}