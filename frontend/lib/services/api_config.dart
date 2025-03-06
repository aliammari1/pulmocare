class ApiConfig {
  // Base URL will be configured through environment
  static String baseUrl = const String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000'); // Default for Android emulator

  // X-Ray Service endpoints
  static String get xrayAnalyzeUrl => '$baseUrl/xray/analyze';
  static String xrayHistoryUrl(String patientId) =>
      '$baseUrl/xray/history/$patientId';

  // Knowledge Service endpoints
  static String get knowledgeServiceUrl => '$baseUrl/knowledge';
  static String get knowledgeSearchUrl => '$baseUrl/knowledge/search';
  static String get knowledgeChatUrl => '$baseUrl/knowledge/chat';
  static String get knowledgeEntitiesUrl => '$baseUrl/knowledge/entities';

  // Health check endpoint
  static String get healthCheckUrl => '$baseUrl/health';

  // Configure base URL at runtime (useful for development/testing)
  static void setBaseUrl(String url) {
    baseUrl = url;
  }
}
