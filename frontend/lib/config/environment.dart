import 'package:flutter/material.dart';

enum Environment { dev, staging, prod }

class EnvironmentConfig {
  // Base URLs - these are fallbacks for when environment-specific values are not set
  static const String baseUrl = 'http://localhost:8000';
  static const String apiGatewayUrl = '$baseUrl/api';

  // Default timeouts and limits
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const int maxUploadSizeMB = 100;

  // Theme-related values
  static const MaterialColor primarySwatch = Colors.blue;

  // Storage-related paths
  static const String cacheDir = 'medapp_cache';
  static const String tempDir = 'medapp_temp';

  // API keys and credentials (should be loaded from secure storage in production)
  static const String sentryDsn = '';
  static const String mapApiKey = '';
  static const String openAiKey = '';
  static const String hfApiKey = '';

  // Network configuration
  static const Duration networkCacheMaxAge = Duration(hours: 1);
  static const int networkRetryCount = 3;
  static const Duration networkRetryDelay = Duration(seconds: 2);
  static const int concurrentNetworkRequests = 5;

  // Analytics configuration
  static const bool enableAnalytics = false;
  static const String analyticsEndpoint = '';

  static const String _currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static Environment get environment {
    switch (_currentEnvironment) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static final Map<String, dynamic> _config = {
    'dev': {
      'apiBaseUrl': 'http://localhost:5000',
      'rabbitmqHost': 'localhost',
      'rabbitmqPort': 5672,
      'otelCollectorUrl': 'http://localhost:4318',
      'enableTracing': true,
      'enableLogging': true,
      'enableServiceDiscovery': false,
    },
    'staging': {
      'apiBaseUrl': const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'http://mobile-gateway'),
      'rabbitmqHost':
          const String.fromEnvironment('RABBITMQ_HOST', defaultValue: 'rabbitmq'),
      'rabbitmqPort': int.parse(
          const String.fromEnvironment('RABBITMQ_PORT', defaultValue: '5672')),
      'otelCollectorUrl': const String.fromEnvironment('OTEL_COLLECTOR_URL',
          defaultValue: 'http://localhost:4318'),
      'enableTracing': true,
      'enableLogging': true,
      'enableServiceDiscovery': true,
    },
    'prod': {
      'apiBaseUrl': const String.fromEnvironment('API_BASE_URL'),
      'rabbitmqHost': const String.fromEnvironment('RABBITMQ_HOST'),
      'rabbitmqPort': int.parse(
          const String.fromEnvironment('RABBITMQ_PORT', defaultValue: '5672')),
      'otelCollectorUrl': const String.fromEnvironment('OTEL_COLLECTOR_URL'),
      'enableTracing': true,
      'enableLogging': false,
      'enableServiceDiscovery': true,
    },
  };

  static Map<String, dynamic> get config => _config[_currentEnvironment];

  // Use these instead of the constants at the top
  static String get apiBaseUrl => config['apiBaseUrl'] as String;
  static String get rabbitmqHost => config['rabbitmqHost'] as String;
  static int get rabbitmqPort => config['rabbitmqPort'] as int;
  static String get otelCollectorUrl => config['otelCollectorUrl'] as String;
  static bool get enableTracing => config['enableTracing'] as bool;
  static bool get enableLogging => config['enableLogging'] as bool;
  static bool get enableServiceDiscovery =>
      config['enableServiceDiscovery'] as bool;
}
