import 'package:flutter/widgets.dart';

import 'app_strings.dart';

extension Translate on BuildContext {
  String tr(String key) {
    final code = Localizations.localeOf(this).languageCode;
    return AppStrings.values[code]?[key] ??
        AppStrings.values['en']?[key] ??
        key;
  }

  // 'en' or 'km' — use for DateFormat month names
  String get langCode => Localizations.localeOf(this).languageCode;

  bool get isKhmer => langCode == 'km';
}