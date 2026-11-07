import '../core/api_client.dart';
import '../models/report_model.dart';
import 'transaction_service.dart';

class ReportService {
  Future<List<ExpenseTrendItem>> getExpenseTrend(String month) async {
    final start = DateTime.parse('$month-01');
    final end = DateTime(start.year, start.month + 1);
    final totals = <int, double>{};
    final transactions = await TransactionService().getTransactions();
    for (final transaction in transactions) {
      if (transaction.kind.trim().toUpperCase() != 'EXPENSE') continue;
      final date = DateTime.tryParse(transaction.transactionDate)?.toLocal();
      if (date == null || date.isBefore(start) || !date.isBefore(end)) continue;
      totals.update(date.day, (amount) => amount + transaction.amount,
          ifAbsent: () => transaction.amount);
    }
    return List.generate(end.subtract(const Duration(days: 1)).day, (index) {
      final day = index + 1;
      return ExpenseTrendItem(date: DateTime(start.year, start.month, day), amount: totals[day] ?? 0);
    });
  }
  // ============================================================
  // SUMMARY
  // ============================================================

  Future<ReportSummary> getSummary(
    String month,
  ) async {
    final response = await ApiClient.dio.get(
      '/reports/summary',
      queryParameters: {
        'month': month,
      },
    );

    return ReportSummary.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  // ============================================================
  // EXPENSE BY CATEGORY
  // ============================================================

  Future<List<CategoryExpenseItem>> getExpenseByCategory(
    String month,
  ) async {
    final response = await ApiClient.dio.get(
      '/reports/expense-by-category',
      queryParameters: {
        'month': month,
      },
    );

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .map(
          (item) => CategoryExpenseItem.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }
}
