import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _isDarkModeKey = 'is_dark_mode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadSavedTheme();
  }

  bool get isDarkMode => _isDarkMode;

  // Add these missing getters that reference the themes from AppTheme
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, _isDarkMode);

    notifyListeners();
  }
}
