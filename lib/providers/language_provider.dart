import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isKhmer => _locale.languageCode == 'km';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code == _locale.languageCode) return;

    _locale = Locale(code);
    notifyListeners();

    // Remember the choice after the app closes
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}