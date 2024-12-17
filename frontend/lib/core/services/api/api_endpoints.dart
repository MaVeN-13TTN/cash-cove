class ApiEndpoints {
  // API Version
  static const String apiVersion = 'v1';

  // Base URLs for different environments
  static const String _devBaseUrl = 'http://localhost:8000';
  static const String _stagingBaseUrl = 'https://staging-api.budgettracker.com';
  static const String _prodBaseUrl = 'https://api.budgettracker.com';

  // Get base URL based on environment
  static String get baseUrl {
    const environment =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    final baseUrl = switch (environment) {
      'prod' => _prodBaseUrl,
      'staging' => _stagingBaseUrl,
      _ => _devBaseUrl,
    };
    return '$baseUrl/api/$apiVersion';
  }

  // Auth endpoints
  static const String login = '/auth/token/';
  static const String register = '/auth/register/';
  static const String refreshToken = '/auth/token/refresh/';
  static const String logout = '/auth/logout/';
  static const String resetPassword = '/auth/reset-password/';
  static const String changePassword = '/auth/change-password/';

  // User endpoints
  static const String userProfile = '/users/profile/';
  static const String userPreferences = '/users/preferences/';

  // Budget endpoints
  static const String budgets = '/budgets/';
  static const String budgetCategories = '/budgets/category/';
  static const String budgetSharing = '/budgets/sharing/';
  static const String activeBudgets = '/budgets/active/';
  static const String copyBudget = '/budgets/{id}/copy/';

  // Expense endpoints
  static const String expenses = '/expenses/';
  static const String recurringExpenses = '/expenses/recurring/';
  static const String expenseCategories = '/expenses/categories/';
  static const String expenseAttachments = '/expenses/attachments/';
  static const String expenseSummary = '/expenses/summary/';

  // Analytics endpoints
  static const String analyticsSpending = '/analytics/spending/by-category/';
  static const String analyticsUtilization =
      '/analytics/budget/monthly-summary/';
  static const String analyticsTrends = '/analytics/trends/';
  static const String analyticsInsights = '/analytics/insights/';
  static const String analyticsEvents = '/analytics/events/';

  // Notifications endpoints
  static const String notifications = '/notifications/';
  static const String notificationSettings = '/notifications/preferences/';
  static const String markAllNotificationsRead =
      '/notifications/mark_all_read/';
  static const String notificationBulkAction = '/notifications/bulk_action/';
  static const String notificationCounts = '/notifications/counts/';

  // Reports endpoints
  static const String reports = '/reports/';
  static const String reportTemplates = '/reports/templates/';
  static const String reportSchedules = '/reports/schedules/';

  // Settings endpoints
  static const String settings = '/settings/';
  static const String currencies = '/settings/currencies/';
  static const String categories = '/settings/categories/';
}
