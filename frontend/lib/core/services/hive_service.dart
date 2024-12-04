import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/budget/budget_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Lazy initialization of boxes
  Box<dynamic>? _appStorageBox;
  Box<dynamic>? _blacklistStorageBox;
  Box<String>? _offlineRequestsBox;
  Box<BudgetModel>? _budgetsBox;
  Box<int>? _tokenBlacklistBox;

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BudgetModelAdapter());
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
    if (Hive.isBoxOpen('token_blacklist')) {
      await Hive.box('token_blacklist').close();
    }
    _tokenBlacklistBox ??= await Hive.openBox<int>('token_blacklist');
    return _tokenBlacklistBox!;
  }

  // Close all boxes when they're no longer needed
  Future<void> closeAllBoxes() async {
    await _appStorageBox?.close();
    await _blacklistStorageBox?.close();
    await _offlineRequestsBox?.close();
    await _budgetsBox?.close();
    await _tokenBlacklistBox?.close();
  }
}
