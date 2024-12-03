import 'package:budget_tracker/data/models/transaction/transaction_model.dart';
import 'package:budget_tracker/data/providers/api_provider.dart';

class TransactionProvider {
  final ApiProvider _apiProvider;

  TransactionProvider(this._apiProvider);

  Future<List<TransactionModel>> getTransactions() async {
    final response = await _apiProvider.get('/transactions');
    return (response['transactions'] as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  Future<TransactionModel> getTransaction(String id) async {
    final response = await _apiProvider.get('/transactions/$id');
    return TransactionModel.fromJson(response['transaction']);
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/transactions', data);
    return TransactionModel.fromJson(response['transaction']);
  }

  Future<TransactionModel> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/transactions/$id', data);
    return TransactionModel.fromJson(response['transaction']);
  }

  Future<void> deleteTransaction(String id) async {
    await _apiProvider.delete('/transactions/$id');
  }
}
