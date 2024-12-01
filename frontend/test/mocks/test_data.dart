class TestData {
  static Map<String, dynamic> get sampleBudget => {
        'name': 'Monthly Budget',
        'amount': 1000,
        'currency': 'USD',
        'period': 'monthly'
      };

  static Map<String, dynamic> get sampleRecurringExpense => {
        'name': 'Rent',
        'amount': 800,
        'frequency': 'monthly',
        'category_id': '1'
      };

  static Map<String, dynamic> get testAnalytics => {
        'total_spending': 1500,
        'categories': [
          {'name': 'Groceries', 'spent': 450},
          {'name': 'Entertainment', 'spent': 250}
        ]
      };

  static Map<String, dynamic> get testBudget => {
        'id': '1',
        'name': 'Test Budget',
        'amount': 1000,
        'currency': 'USD',
        'period': 'monthly',
        'categories': [
          {'id': '1', 'name': 'Groceries', 'limit': 300},
          {'id': '2', 'name': 'Entertainment', 'limit': 200}
        ],
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z'
      };

  static Map<String, dynamic> get testAuthResponse => {
        'access_token': 'test_access_token',
        'refresh_token': 'test_refresh_token',
        'expires_in': 3600
      };

  static Map<String, dynamic> get testErrorResponse => {
        'error': 'invalid_request',
        'error_description': 'Test error message'
      };

  static Map<String, dynamic> get testUser => {
        'id': '1',
        'email': 'test@example.com',
        'name': 'Test User',
        'created_at': '2024-01-01T00:00:00Z'
      };
}
