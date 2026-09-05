import '../core/api_client.dart';
import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories(String kind) async {
    final response = await ApiClient.dio.get('/categories', queryParameters: {
      'kind': kind,
    });
    return (response.data as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String kind,
    required String icon,
    required String colorHex,
  }) async {
    final response = await ApiClient.dio.post('/categories', data: {
      'name': name,
      'kind': kind,
      'icon': icon,
      'colorHex': colorHex,
    });
    return CategoryModel.fromJson(response.data);
  }
}