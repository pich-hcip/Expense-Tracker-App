import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/transaction_model.dart';

class TransactionService {
  // ============================================================
  // CREATE TRANSACTION
  // ============================================================

  Future<void> createTransaction({
    required String walletId,
    String? categoryId,
    required String kind,
    required double amount,
    String? title,
  }) async {
    try {
      await ApiClient.dio.post(
        '/transactions',
        data: {
          'walletId': walletId,
          'categoryId': categoryId,
          'kind': kind.toUpperCase(),
          'amount': amount,
          'title': title?.trim(),
        },
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // GET ALL TRANSACTIONS
  // ============================================================

  Future<List<TransactionItem>> getTransactions() async {
    try {
      final response = await ApiClient.dio.get(
        '/transactions',
      );

      final data = response.data;

      if (data is! List) {
        return [];
      }

      return data
          .map(
            (json) => TransactionItem.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // DELETE TRANSACTION
  // ============================================================

  Future<void> deleteTransaction(String id) async {
    try {
      await ApiClient.dio.delete(
        '/transactions/$id',
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // GET API ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // ----------------------------------------------------------
    // Read message returned by Spring Boot
    //
    // Example:
    // {
    //   "message":
    //   "Insufficient wallet balance. Available balance: $50.00"
    // }
    // ----------------------------------------------------------

    if (data is Map) {
      final message = data['message'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      final error = data['error'];

      if (error != null &&
          error.toString().trim().isNotEmpty) {
        return error.toString().trim();
      }
    }

    // ----------------------------------------------------------
    // FALLBACK MESSAGES
    // ----------------------------------------------------------

    switch (statusCode) {
      case 400:
        return 'Invalid transaction. Check the amount and wallet balance.';

      case 401:
        return 'Your session has expired. Please login again.';

      case 403:
        return 'You do not have permission to use this wallet.';

      case 404:
        return 'Wallet, category, or transaction was not found.';

      case 409:
        return 'This transaction could not be completed.';

      case 500:
        return 'Server error. Please try again.';

      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          return 'Connection timed out. Please try again.';
        }

        if (e.type == DioExceptionType.connectionError) {
          return 'Could not connect to the server.';
        }

        return 'Something went wrong. Please try again.';
    }
  }
}