library mocks;

import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:budget_tracker/core/services/storage/secure_storage.dart';
import 'package:budget_tracker/core/services/auth/token_manager.dart';

@GenerateMocks([
  Dio,
  Connectivity,
  DefaultCacheManager,
  SecureStorage,
  TokenManager,
])
void main() {} // Dummy main to satisfy build_runner

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
          {'id': '2', 'name': 'Entertainment', 'limit': 200},
        ],
      };
}
