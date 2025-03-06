import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  double _textScaleFactor = 1.0;
  bool _useMobileLayout = true;
  double _screenWidth = 0;

  bool get isDarkMode => _isDarkMode;
  double get textScaleFactor => _textScaleFactor;
  bool get useMobileLayout => _useMobileLayout;

  ThemeProvider() {
    _loadTheme();
  }

  void updateScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (_screenWidth != width) {
      _screenWidth = width;
      _useMobileLayout = width < 600;
      notifyListeners();
    }
  }

  void updateTextScale(double scale) {
    _textScaleFactor = scale;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _textScaleFactor = prefs.getDouble('textScale') ?? 1.0;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    await prefs.setDouble('textScale', _textScaleFactor);
  }

  ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.white,
          indicatorColor:
              Colors.blue.withAlpha(30), // Replace withOpacity(0.12)
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.grey[900],
          indicatorColor:
              Colors.blue.withAlpha(30), // Replace withOpacity(0.12)
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      );
}
