import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API Gateway configuration
  static String get apiGatewayUrl => 
      dotenv.get('API_GATEWAY_URL', fallback: 'http://localhost:5000/api');

  // Service Registry
  static String get consulUrl =>
      dotenv.get('SERVICE_REGISTRY_URL', fallback: 'http://localhost:8500');

  // Service URLs (through gateway)
  static String get reportsServiceUrl => '$apiGatewayUrl/reports';
  static String get medecinsServiceUrl => '$apiGatewayUrl/medecins';
  static String get patientsServiceUrl => '$apiGatewayUrl/patients';
  static String get radiologueServiceUrl => '$apiGatewayUrl/radiologue';
  static String get xrayServiceUrl => '$apiGatewayUrl/xray';

  // RabbitMQ Configuration
  static String get rabbitmqHost =>
      dotenv.get('RABBITMQ_HOST', fallback: 'localhost');
  static int get rabbitmqPort =>
      int.parse(dotenv.get('RABBITMQ_PORT', fallback: '5672'));
  static String get rabbitmqVhost =>
      dotenv.get('RABBITMQ_VHOST', fallback: '/');

  // Monitoring
  static String get monitoringUrl =>
      dotenv.get('MONITORING_URL', fallback: 'http://localhost:9090');
  static String get otelCollectorUrl =>
      dotenv.get('OTEL_COLLECTOR_URL', fallback: 'http://localhost:4318');

  // Network settings
  static Duration get apiTimeout =>
      Duration(seconds: int.parse(dotenv.get('API_TIMEOUT_SECONDS', fallback: '30')));
  static int get maxRetries =>
      int.parse(dotenv.get('MAX_RETRIES', fallback: '3'));
  static Duration get retryDelay =>
      Duration(seconds: int.parse(dotenv.get('RETRY_DELAY_SECONDS', fallback: '2')));

  // Feature flags
  static bool get enableServiceDiscovery =>
      dotenv.get('ENABLE_SERVICE_DISCOVERY', fallback: 'true') == 'true';
  static bool get enableTracing =>
      dotenv.get('ENABLE_TRACING', fallback: 'true') == 'true';
  static bool get enableCaching =>
      dotenv.get('ENABLE_CACHING', fallback: 'true') == 'true';

  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
