// lib/services/dashboard_service.dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/balance_summary_model.dart';
import '../models/transaction_model.dart';

class DashboardService {
  Future<BalanceSummary> getSummary() async {
    final response = await ApiClient.dio.get('/dashboard/summary');
    return BalanceSummary.fromJson(response.data);
  }

  Future<List<TransactionItem>> getRecentTransactions() async {
    final response = await ApiClient.dio.get('/dashboard/recent-transactions');
    return (response.data as List)
        .map((json) => TransactionItem.fromJson(json))
        .toList();
  }
}