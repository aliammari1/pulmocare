import '../config/env_config.dart';

class ApiConfig {
  static String get gatewayUrl => EnvConfig.apiGatewayUrl;
  
  // Service endpoints
  static String get reportsUrl => '$gatewayUrl/reports';
  static String get medecinsUrl => '$gatewayUrl/medecins';
  static String get patientsUrl => '$gatewayUrl/patients';
  static String get radiologueUrl => '$gatewayUrl/radiologue';
  static String get xrayUrl => '$gatewayUrl/xray';
  
  // Report specific endpoints
  static String get reportSearchUrl => '$reportsUrl/search';
  static String get reportAnalyzeUrl => '$reportsUrl/analyze';
  
  // Helper methods for specific resources
  static String resourceUrl(String service, String id) => '$gatewayUrl/$service/$id';
  static String reportUrl(String id) => resourceUrl('reports', id);
  static String reportExportUrl(String id) => '$reportsUrl/$id/export';
}
