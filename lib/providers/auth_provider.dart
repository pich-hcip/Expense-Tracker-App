import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../models/otp_purpose.dart';
import '../services/push_notification_service.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  bool isAuthenticated = false;

  String? errorMessage;

  String? fullName;
  String? email;
  String? profileImageUrl;

  // =========================================================
  // OTP PURPOSE
  // =========================================================

  String _purposeToString(OtpPurpose purpose) {
    switch (purpose) {
      case OtpPurpose.register:
        return 'REGISTER';

      case OtpPurpose.resetPassword:
        return 'RESET_PASSWORD';
    }
  }

  // =========================================================
  // ERROR HANDLER
  // =========================================================

  String _getErrorMessage(DioException e) {
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
        return 'Invalid request.';

      case 401:
        return 'Invalid email or password.';

      case 403:
        return 'Access denied.';

      case 404:
        return 'API endpoint not found.';

      case 409:
        return 'Account already exists.';

      case 500:
        return 'Server error. Please try again.';

      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<bool> register(
    String fullName,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail =
          email.trim().toLowerCase();

      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {
          'fullName': fullName.trim(),
          'email': normalizedEmail,
          'password': password,
        },
      );

      // IMPORTANT:
      // Do NOT set fullName/email here.
      //
      // Registration does not log the user in.
      // Backend returns token = null during registration.
      //
      // Flow:
      // Register -> OTP -> Login -> JWT -> Dashboard

      isAuthenticated = false;

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } catch (e) {
      errorMessage = e.toString();

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<bool> login(
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail =
          email.trim().toLowerCase();

      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'email': normalizedEmail,
          'password': password,
        },
      );

      final data = response.data;

      if (data is! Map) {
        errorMessage =
            'Invalid response from server.';

        isAuthenticated = false;

        return false;
      }

      // =====================================================
      // GET JWT
      // =====================================================

      final token =
          data['token']?.toString();

      if (token == null ||
          token.trim().isEmpty) {
        errorMessage =
            'Authentication token was not returned.';

        isAuthenticated = false;

        return false;
      }

      // =====================================================
      // SAVE JWT
      // =====================================================

      await SecureStorage.saveToken(
        token.trim(),
      );

      debugPrint(
        'LOGIN: JWT saved successfully',
      );

      // =====================================================
      // SAVE USER INFORMATION
      // =====================================================

      fullName =
          data['fullName']?.toString();

      this.email =
          data['email']?.toString() ??
          normalizedEmail;

      profileImageUrl =
          data['avatarUrl']?.toString();

      // User is now authenticated
      isAuthenticated = true;

      // Send this phone's FCM token so the server can push notifications
      PushNotificationService.registerToken();

      return true;
    } on DioException catch (e) {
      isAuthenticated = false;

      errorMessage = _getErrorMessage(e);

      return false;
    } catch (e) {
      isAuthenticated = false;

      errorMessage = e.toString();

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // SEND OTP
  // =========================================================

  Future<bool> sendOtp(
    String email,
    OtpPurpose purpose,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.dio.post(
        '/auth/send-otp',
        data: {
          'email':
              email.trim().toLowerCase(),
          'purpose':
              _purposeToString(purpose),
        },
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } catch (e) {
      errorMessage = e.toString();

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // VERIFY OTP
  // =========================================================

  Future<bool> verifyOtp(
    String email,
    String otp,
    OtpPurpose purpose,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.dio.post(
        '/auth/verify-otp',
        data: {
          'email':
              email.trim().toLowerCase(),
          'otp': otp.trim(),
          'purpose':
              _purposeToString(purpose),
        },
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } catch (e) {
      errorMessage = e.toString();

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.dio.post(
        '/auth/reset-password',
        data: {
          'email':
              email.trim().toLowerCase(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        },
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } catch (e) {
      errorMessage = e.toString();

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // RESTORE LOGIN FROM SAVED TOKEN
  // =========================================================

  Future<bool> restoreSession() async {
    try {
      final token =
          await SecureStorage.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        isAuthenticated = false;
        notifyListeners();

        return false;
      }

      // Token exists.
      // Validate it by requesting current user.
      final response =
          await ApiClient.dio.get(
        '/users/me',
      );

      final data = response.data;

      if (data is Map) {
        fullName =
            data['fullName']?.toString();

        email =
            data['email']?.toString();

        profileImageUrl =
            data['avatarUrl']?.toString();
      }

      isAuthenticated = true;

      notifyListeners();

      return true;
    } on DioException catch (e) {
      debugPrint(
        'RESTORE SESSION ERROR: ${e.response?.statusCode}',
      );

      // Saved token is probably invalid/expired.
      await SecureStorage.clearToken();

      isAuthenticated = false;
      fullName = null;
      email = null;
      profileImageUrl = null;

      notifyListeners();

      return false;
    } catch (e) {
      debugPrint(
        'RESTORE SESSION ERROR: $e',
      );

      isAuthenticated = false;

      notifyListeners();

      return false;
    }
  }

  // =========================================================
  // TOKEN CHECK
  // =========================================================

  Future<bool> hasToken() async {
    final token =
        await SecureStorage.getToken();

    return token != null &&
        token.trim().isNotEmpty;
  }

  // =========================================================
  // UPDATE PROFILE LOCAL STATE
  // =========================================================

  void updateProfile({
    required String fullName,
    required String email,
    String? profileImageUrl,
  }) {
    this.fullName = fullName;
    this.email = email;

    if (profileImageUrl != null) {
      this.profileImageUrl =
          profileImageUrl;
    }

    notifyListeners();
  }

  // =========================================================
  // UPDATE PROFILE IMAGE
  // =========================================================

  void updateProfileImage(
    String imageUrl,
  ) {
    profileImageUrl = imageUrl;

    notifyListeners();
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    await SecureStorage.clearToken();

    isAuthenticated = false;

    fullName = null;
    email = null;
    profileImageUrl = null;
    errorMessage = null;

    notifyListeners();

    debugPrint(
      'LOGOUT: JWT cleared',
    );
  }
}