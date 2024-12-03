import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionRepository {
  final TransactionProvider _transactionProvider;
  final Box<TransactionModel> _localCache;
  static const String _cacheBoxName = 'transactions';

  TransactionRepository(this._transactionProvider) 
    : _localCache = Hive.box<TransactionModel>(_cacheBoxName);

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
