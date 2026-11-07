import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories(String kind) async {
    final response = await ApiClient.dio.get(
      '/categories',
      queryParameters: {'kind': kind},
    );

    return (response.data as List)
        .map(
          (json) => CategoryModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String kind,
    required String icon,
    required String colorHex,
  }) async {
    final response = await ApiClient.dio.post(
      '/categories',
      data: {
        'name': name,
        'kind': kind,
        'icon': icon,
        'colorHex': colorHex,
      },
    );

    return CategoryModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String kind,
    required String icon,
    required String colorHex,
  }) async {
    final response = await ApiClient.dio.put(
      '/categories/${Uri.encodeComponent(id)}',
      data: {
        'name': name,
        'kind': kind,
        'icon': icon,
        'colorHex': colorHex,
      },
    );

    return CategoryModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteCategory(String id) async {
    await ApiClient.dio.delete(
      '/categories/${Uri.encodeComponent(id)}',
    );
  }

  String getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final message = data['message'] ??
            data['error'] ??
            data['detail'];

        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      switch (error.response?.statusCode) {
        case 400:
          return 'Invalid category information.';
        case 401:
          return 'Please log in again.';
        case 403:
          return 'You do not have permission.';
        case 404:
          return 'Category not found.';
        case 409:
          return 'This category cannot be deleted.';
        default:
          return 'Unable to complete the request. Please try again.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}