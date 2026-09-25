import 'package:flutter/foundation.dart';

class Config {
  Config._();

  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    final configured = _apiOverride.trim();
    if (configured.isNotEmpty) {
      if (kReleaseMode && !configured.startsWith('https://')) {
        throw StateError('Release API_BASE_URL must use HTTPS.');
      }
      return _withTrailingSlash(configured);
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is required for release builds. '
        'Pass --dart-define=API_BASE_URL=https://your-gateway.example/api/',
      );
    }

    if (kIsWeb) {
      return 'http://localhost:9080/api/';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:9080/api/';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:9080/api/';
    }
  }

  static String _withTrailingSlash(String value) =>
      value.endsWith('/') ? value : '$value/';
}
