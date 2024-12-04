import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../../core/services/hive_service.dart';

class TransactionRepository {
  final TransactionProvider _transactionProvider;
  late Box<TransactionModel> _localCache;

  TransactionRepository(this._transactionProvider) {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    final hiveService = HiveService();
    _localCache = await hiveService.getTransactionsBox();
  }

  Future<List<TransactionModel>> getTransactions({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedTransactions = _localCache.values.toList();
        if (cachedTransactions.isNotEmpty) {
          return cachedTransactions;
        }
      }

      final transactions = await _transactionProvider.getTransactions();
      
      // Cache the fetched transactions
      await _localCache.clear();
      await _localCache.addAll(transactions);

      return transactions;
    } catch (e) {
      // Handle or rethrow the error as needed
      rethrow;
    }
  }

  // Add more methods as needed for transaction-related operations
}
