import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/budget/budget_model.dart';
import '../../data/models/expense/expense_model.dart';
import '../../core/utils/logger_utils.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Box<dynamic>? _appStorageBox;
  Box<dynamic>? _blacklistStorageBox;
  Box<String>? _offlineRequestsBox;
  Box<BudgetModel>? _budgetsBox;
  Box<int>? _tokenBlacklistBox;
  Box<ExpenseModel>? _expensesBox;

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    
    // Register adapters if not already registered
    _safeRegisterAdapter<BudgetModel>(BudgetModelAdapter());
    _safeRegisterAdapter<ExpenseModel>(ExpenseModelAdapter());
  }

  void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
    try {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter<T>(adapter);
        if (kDebugMode) {
          LoggerUtils.info('Registered Hive adapter for type ${T.toString()} with typeId ${adapter.typeId}');
        }
      }
    } catch (e) {
      LoggerUtils.error('Error registering Hive adapter for type ${T.toString()}: $e');
    }
  }

  Future<Box<dynamic>> getAppStorageBox() async {
    _appStorageBox ??= await Hive.openBox('app_storage');
    return _appStorageBox!;
  }

  Future<Box<dynamic>> getBlacklistStorageBox() async {
    _blacklistStorageBox ??= await Hive.openBox('blacklist_storage');
    return _blacklistStorageBox!;
  }

  Future<Box<String>> getOfflineRequestsBox() async {
    _offlineRequestsBox ??= await Hive.openBox<String>('offline_requests');
    return _offlineRequestsBox!;
  }

  Future<Box<BudgetModel>> getBudgetsBox() async {
    _budgetsBox ??= await Hive.openBox<BudgetModel>('budgets');
    return _budgetsBox!;
  }

  Future<Box<int>> getTokenBlacklistBox() async {
    _tokenBlacklistBox ??= await Hive.openBox<int>('token_blacklist');
    return _tokenBlacklistBox!;
  }

  Future<Box<ExpenseModel>> getExpensesBox() async {
    const boxName = 'expenses';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<ExpenseModel>(boxName);
    }
    return Hive.box<ExpenseModel>(boxName);
  }

  // Close all boxes when they're no longer needed
  Future<void> closeBoxes() async {
    await _appStorageBox?.close();
    await _blacklistStorageBox?.close();
    await _offlineRequestsBox?.close();
    await _budgetsBox?.close();
    await _tokenBlacklistBox?.close();
    await _expensesBox?.close();
  }
}
