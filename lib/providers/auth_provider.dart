import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;
  String? fullName;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final auth = await _authService.login(email: email, password: password);
      fullName = auth.fullName;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final auth = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      this.fullName = auth.fullName;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email, newPassword);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    fullName = null;
    notifyListeners();
  }
}
