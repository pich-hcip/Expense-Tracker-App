import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../models/auth_response_model.dart';

class AuthService {
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await ApiClient.dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      });

      final auth = AuthResponse.fromJson(response.data);
      await SecureStorage.saveToken(auth.token);
      return auth;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final auth = AuthResponse.fromJson(response.data);
      await SecureStorage.saveToken(auth.token);
      return auth;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearToken();
  }

  Future<String> resetPassword(String email, String newPassword) async {
    try {
      final response = await ApiClient.dio.post('/auth/reset-password', data: {
        'email': email,
        'newPassword': newPassword,
      });
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response!.data['message'];
    }
    return 'Something went wrong. Please try again.';
  }
}