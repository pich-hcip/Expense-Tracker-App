import '../core/api_client.dart';
import '../models/budget_model.dart';

class BudgetService {
  Future<List<BudgetModel>> getBudgets() async {
    final response = await ApiClient.dio.get('/budgets');
    return (response.data as List).map((json) => BudgetModel.fromJson(json)).toList();
  }

  Future<void> saveBudget({required String categoryId, required double monthlyLimit}) async {
    await ApiClient.dio.post('/budgets', data: {
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
    });
  }

  Future<void> deleteBudget(String id) async {
    await ApiClient.dio.delete('/budgets/$id');
  }
}