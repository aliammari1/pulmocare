import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _darkModeKey = 'darkMode';
  static const String _textScaleKey = 'textScale';
  static const String _autoAnalyzeKey = 'autoAnalyze';
  static const String _languageKey = 'language';
  static const String _voiceEnabledKey = 'voiceEnabled';
  static const String _biometricsEnabledKey = 'biometricsEnabled';
  static const String _lastSyncKey = 'lastSync';
  static const String _analyticsEnabledKey = 'analyticsEnabled';

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
  }

  static Future<double> getTextScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textScaleKey) ?? 1.0;
  }

  static Future<void> setAutoAnalyze(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoAnalyzeKey, value);
  }

  static Future<bool> getAutoAnalyze() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoAnalyzeKey) ?? true;
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }

  static Future<void> setVoiceEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceEnabledKey, value);
  }

  static Future<bool> getVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceEnabledKey) ?? true;
  }

  static Future<void> setBiometricsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, value);
  }

  static Future<bool> getBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? false;
  }

  static Future<void> setLastSync(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, value.toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastSyncKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  static Future<void> setAnalyticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsEnabledKey, value);
  }

  static Future<bool> getAnalyticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsEnabledKey) ?? true;
  }

  static Future<Map<String, dynamic>> getAllPreferences() async {
    return {
      'darkMode': await getDarkMode(),
      'textScale': await getTextScale(),
      'autoAnalyze': await getAutoAnalyze(),
      'language': await getLanguage(),
      'voiceEnabled': await getVoiceEnabled(),
      'biometricsEnabled': await getBiometricsEnabled(),
      'lastSync': await getLastSync(),
      'analyticsEnabled': await getAnalyticsEnabled(),
    };
  }

  static Future<void> resetAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static ThemeData getThemeBasedOnPreferences(bool isDarkMode, double textScale) {
    final baseTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontSizeFactor: textScale,
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontSizeFactor: textScale,
      ),
    );
  }
}