import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'language_code';
  AppLanguage _currentLanguage = AppLanguages.english;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;

  Locale get locale => Locale(_currentLanguage.code);

  bool get isRTL => _currentLanguage.isRTL;

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageCodeKey);

    if (savedLanguageCode != null) {
      final savedLanguage = AppLanguages.supportedLanguages.firstWhere(
        (lang) => lang.code == savedLanguageCode,
        orElse: () => AppLanguages.english,
      );
      _currentLanguage = savedLanguage;
      notifyListeners();
    }
  }

  Future<void> changeLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;

    // Save the language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, language.code);

    notifyListeners();
  }
}
