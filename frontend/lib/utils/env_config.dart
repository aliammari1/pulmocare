import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API URLs
  static String get apiGatewayUrl =>
      dotenv.get('API_GATEWAY_URL', fallback: 'http://localhost:8000/api');
  static String get xrayServiceUrl =>
      dotenv.get('XRAY_SERVICE_URL', fallback: 'http://localhost:5001');
  static String get knowledgeServiceUrl =>
      dotenv.get('KNOWLEDGE_SERVICE_URL', fallback: 'http://localhost:5002');
  static String get monitoringUrl =>
      dotenv.get('MONITORING_URL', fallback: 'http://localhost:9090');

  // Feature flags
  static bool get enableCaching => _parseBool('ENABLE_CACHING', true);
  static bool get enableServiceDiscovery =>
      _parseBool('ENABLE_SERVICE_DISCOVERY', false);
  static bool get enableDebugMode => _parseBool('ENABLE_DEBUG_MODE', false);
  static bool get enableMonitoring => _parseBool('ENABLE_MONITORING', true);
  static bool get enableOfflineMode => _parseBool('ENABLE_OFFLINE_MODE', false);

  // Performance settings
  static int get maxCacheAgeMinutes => _parseInt('MAX_CACHE_AGE_MINUTES', 60);
  static int get networkTimeoutSeconds =>
      _parseInt('NETWORK_TIMEOUT_SECONDS', 10);
  static int get maxRetryAttempts => _parseInt('MAX_RETRY_ATTEMPTS', 3);

  // Styling configuration
  static String get primaryColorHex =>
      dotenv.get('PRIMARY_COLOR_HEX', fallback: '#2196F3');
  static double get defaultFontSize => _parseDouble('DEFAULT_FONT_SIZE', 14.0);

  // Helper methods for parsing environment variables
  static bool _parseBool(String key, bool defaultValue) {
    final value = dotenv.get(key, fallback: defaultValue.toString());
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    return defaultValue;
  }

  static int _parseInt(String key, int defaultValue) {
    final value = dotenv.get(key, fallback: defaultValue.toString());
    return int.tryParse(value) ?? defaultValue;
  }

  static double _parseDouble(String key, double defaultValue) {
    final value = dotenv.get(key, fallback: defaultValue.toString());
    return double.tryParse(value) ?? defaultValue;
  }

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
