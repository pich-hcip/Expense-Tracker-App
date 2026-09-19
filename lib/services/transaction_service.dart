import '../core/api_client.dart';
import '../models/transaction_model.dart';

class TransactionService {
  Future<void> createTransaction({
    required String walletId,
    String? categoryId,
    required String kind,
    required double amount,
    String? title,
  }) async {
    await ApiClient.dio.post(
      '/transactions',
      data: {
        'walletId': walletId,
        'categoryId': categoryId,
        'kind': kind,
        'amount': amount,
        'title': title,
      },
    );
  }

  Future<List<TransactionItem>> getTransactions() async {
    final response = await ApiClient.dio.get('/transactions');
    return (response.data as List)
        .map((json) => TransactionItem.fromJson(json))
        .toList();
  }

  // in lib/services/transaction_service.dart
  Future<void> deleteTransaction(String id) async {
    await ApiClient.dio.delete('/transactions/$id');
  }
}
