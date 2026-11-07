import 'package:dio/dio.dart';

import '../core/api_client.dart';

class ChangePasswordService {
  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String getErrorMessage(
    DioException e,
  ) {
    final data = e.response?.data;

    if (data is Map) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Current password is incorrect or request is invalid.';

      case 401:
        return 'Your session has expired. Please login again.';

      case 403:
        return 'Access denied.';

      case 500:
        return 'Server error. Please try again.';

      default:
        return e.message ??
            'Something went wrong.';
    }
  }

  // =========================================================
  // SEND OTP
  // =========================================================

  Future<void> sendOtp({
    required String currentPassword,
  }) async {
    await ApiClient.dio.post(
      '/users/me/change-password/send-otp',
      data: {
        'currentPassword':
            currentPassword,
      },
    );
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  Future<void> changePassword({
    required String otp,
    required String newPassword,
  }) async {
    await ApiClient.dio.post(
      '/users/me/change-password',
      data: {
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
    );
  }
}