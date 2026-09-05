import '../core/api_client.dart';

class TransactionService {
  Future<void> createTransaction({
    required String walletId,
    String? categoryId,
    required String kind,
    required double amount,
    String? title,
  }) async {
    await ApiClient.dio.post('/transactions', data: {
      'walletId': walletId,
      'categoryId': categoryId,
      'kind': kind,
      'amount': amount,
      'title': title,
    });
  }
}