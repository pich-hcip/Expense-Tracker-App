import '../core/api_client.dart';
import '../models/budget_model.dart';

class BudgetService {
  // =======================================================
  // GET BUDGETS
  // =======================================================

  Future<List<BudgetModel>> getBudgets({
    DateTime? month,
  }) async {
    final selectedMonth =
        month ?? DateTime.now();

    final period =
        _monthString(selectedMonth);

    final response =
        await ApiClient.dio.get(
      '/budgets',
      queryParameters: {
        'month': period,
      },
    );

    final List<dynamic> data =
        response.data as List<dynamic>;

    return data
        .map(
          (json) =>
              BudgetModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // =======================================================
  // SUMMARY
  // =======================================================

  Future<BudgetSummaryModel> getSummary({
    DateTime? month,
  }) async {
    final selectedMonth =
        month ?? DateTime.now();

    final response =
        await ApiClient.dio.get(
      '/budgets/summary',
      queryParameters: {
        'month':
            _monthString(
          selectedMonth,
        ),
      },
    );

    return BudgetSummaryModel.fromJson(
      response.data
          as Map<String, dynamic>,
    );
  }

  // =======================================================
  // CREATE
  // =======================================================

  Future<BudgetModel> createBudget({
    required String categoryId,
    required double monthlyLimit,
    required DateTime month,
  }) async {
    final response =
        await ApiClient.dio.post(
      '/budgets',
      data: {
        'categoryId':
            categoryId,
        'monthlyLimit':
            monthlyLimit,
        'periodMonth':
            _monthString(month),
      },
    );

    return BudgetModel.fromJson(
      response.data
          as Map<String, dynamic>,
    );
  }

  // =======================================================
  // UPDATE
  // =======================================================

  Future<BudgetModel> updateBudget({
    required String id,
    required String categoryId,
    required double monthlyLimit,
    required DateTime month,
  }) async {
    final response =
        await ApiClient.dio.put(
      '/budgets/$id',
      data: {
        'categoryId':
            categoryId,
        'monthlyLimit':
            monthlyLimit,
        'periodMonth':
            _monthString(month),
      },
    );

    return BudgetModel.fromJson(
      response.data
          as Map<String, dynamic>,
    );
  }

  // =======================================================
  // DELETE
  // =======================================================

  Future<void> deleteBudget(
    String id,
  ) async {
    await ApiClient.dio.delete(
      '/budgets/$id',
    );
  }

  // =======================================================
  // MONTH
  // =======================================================

  String _monthString(
    DateTime date,
  ) {
    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '${date.year}-$month-01';
  }
}