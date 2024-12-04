import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/budget/budget_model.dart';
import '../../data/models/transaction/transaction_model.dart';
import '../../data/models/expense/expense_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Box<dynamic>? _appStorageBox;
  Box<dynamic>? _blacklistStorageBox;
  Box<String>? _offlineRequestsBox;
  Box<BudgetModel>? _budgetsBox;
  Box<int>? _tokenBlacklistBox;
  Box<TransactionModel>? _transactionsBox;
  Box<ExpenseModel>? _expensesBox;

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BudgetModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ExpenseModelAdapter());
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
    return _offlineRequestsBox as Box<String>;
  }

  Future<Box<BudgetModel>> getBudgetsBox() async {
    _budgetsBox ??= await Hive.openBox<BudgetModel>('budgets');
    return _budgetsBox!;
  }

  Future<Box<int>> getTokenBlacklistBox() async {
    _tokenBlacklistBox ??= await Hive.openBox<int>('token_blacklist');
    return _tokenBlacklistBox!;
  }

  Future<Box<TransactionModel>> getTransactionsBox() async {
    const boxName = 'transactions';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<TransactionModel>(boxName);
    }
    return Hive.box<TransactionModel>(boxName);
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
    await _transactionsBox?.close();
    await _expensesBox?.close();
  }
}
