import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

class CacheService {
  static const String _prefix = 'cache_';
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  Future<void> set(String key, dynamic value, {Duration? expiry}) async {
    if (!EnvConfig.enableCaching) return;

    final expiryTime = DateTime.now().add(
      expiry ?? Duration(minutes: EnvConfig.cacheMaxAge.inMinutes),
    );

    final cacheEntry = {
      'value': value,
      'expiry': expiryTime.toIso8601String(),
    };

    await _prefs.setString(_prefix + key, json.encode(cacheEntry));
  }

  Future<T?> get<T>(String key) async {
    if (!EnvConfig.enableCaching) return null;

    final data = _prefs.getString(_prefix + key);
    if (data == null) return null;

    final cacheEntry = json.decode(data);
    final expiryTime = DateTime.parse(cacheEntry['expiry']);

    if (DateTime.now().isAfter(expiryTime)) {
      await _prefs.remove(_prefix + key);
      return null;
    }

    return cacheEntry['value'] as T;
  }

  Future<void> invalidate(String key) async {
    await _prefs.remove(_prefix + key);
  }

  Future<void> invalidateAll() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  bool hasValidCache(String key) {
    if (!EnvConfig.enableCaching) return false;

    final data = _prefs.getString(_prefix + key);
    if (data == null) return false;

    final cacheEntry = json.decode(data);
    final expiryTime = DateTime.parse(cacheEntry['expiry']);

    return DateTime.now().isBefore(expiryTime);
  }

  Future<bool> isExpired(String key) async {
    final expiresAt = _prefs.getInt('${_prefix + key}_expires');
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }
}
