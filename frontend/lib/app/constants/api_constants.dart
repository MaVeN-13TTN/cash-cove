class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = 'https://api.budgettracker.com';
  static const String apiVersion = '/v1';
  static const String baseApiUrl = '$baseUrl$apiVersion';

  // Authentication endpoints
  static const String login = '$baseApiUrl/auth/login';
  static const String register = '$baseApiUrl/auth/register';
  static const String logout = '$baseApiUrl/auth/logout';
  static const String refreshToken = '$baseApiUrl/auth/refresh';

  // User endpoints
  static const String userProfile = '$baseApiUrl/user/profile';
  static const String updateProfile = '$baseApiUrl/user/profile/update';
  static const String changePassword = '$baseApiUrl/user/password/change';

  // Budget endpoints
  static const String budgets = '$baseApiUrl/budgets';
  static const String budgetCategories = '$baseApiUrl/budgets/categories';
  static const String budgetSummary = '$baseApiUrl/budgets/summary';

  // Transaction endpoints
  static const String transactions = '$baseApiUrl/transactions';
  static const String transactionCategories = '$baseApiUrl/transactions/categories';
  static const String transactionStats = '$baseApiUrl/transactions/stats';

  // Report endpoints
  static const String reports = '$baseApiUrl/reports';
  static const String reportDownload = '$baseApiUrl/reports/download';

  // Settings endpoints
  static const String settings = '$baseApiUrl/settings';
  static const String currencies = '$baseApiUrl/settings/currencies';
  static const String preferences = '$baseApiUrl/settings/preferences';

  // Error messages
  static const String defaultErrorMessage = 'Something went wrong. Please try again later.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
}