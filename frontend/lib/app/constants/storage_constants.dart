class StorageConstants {
  StorageConstants._();

  // Secure Storage Keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userPin = 'user_pin';
  static const String biometricEnabled = 'biometric_enabled';

  // Shared Preferences Keys
  static const String firstLaunch = 'first_launch';
  static const String onboardingComplete = 'onboarding_complete';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String selectedTheme = 'selected_theme';
  static const String selectedLanguage = 'selected_language';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String deviceId = 'device_id';

  // Cache Keys
  static const String userProfile = 'user_profile';
  static const String budgetCategories = 'budget_categories';
  static const String transactionCategories = 'transaction_categories';
  static const String currencies = 'currencies';
  static const String recentTransactions = 'recent_transactions';
  static const String monthlyBudget = 'monthly_budget';
  static const String yearlyStats = 'yearly_stats';

  // Cache Duration
  static const Duration profileCacheDuration = Duration(hours: 24);
  static const Duration categoriesCacheDuration = Duration(days: 7);
  static const Duration transactionsCacheDuration = Duration(hours: 1);
  static const Duration budgetCacheDuration = Duration(hours: 12);
  static const Duration statsCacheDuration = Duration(hours: 6);

  // Local Database
  static const String databaseName = 'budget_tracker.db';
  static const int databaseVersion = 1;
  static const String transactionsTable = 'transactions';
  static const String budgetsTable = 'budgets';
  static const String categoriesTable = 'categories';
  static const String settingsTable = 'settings';

  // File Storage
  static const String documentsDirectory = 'documents';
  static const String reportsDirectory = 'reports';
  static const String receiptsDirectory = 'receipts';
  static const String exportsDirectory = 'exports';
  static const String logsDirectory = 'logs';
}