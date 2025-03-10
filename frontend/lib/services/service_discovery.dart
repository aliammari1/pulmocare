import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ServiceInfo {
  final String name;
  final String baseUrl;
  final bool isHealthy;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> healthStatus;

  ServiceInfo({
    required this.name,
    required this.baseUrl,
    required this.isHealthy,
    this.metadata = const {},
    this.healthStatus = const {},
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      isHealthy: json['healthStatus']?['status'] == 'UP',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      healthStatus: json['healthStatus'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ServiceDiscovery extends ChangeNotifier {
  final Map<String, ServiceInfo> _services = {};
  Timer? _refreshTimer;
  bool _isInitialized = false;
  final _retryInterval = const Duration(seconds: 30);
  int _consecutiveFailures = 0;
  static const int _maxFailures = 3;

  bool get isInitialized => _isInitialized;
  Map<String, ServiceInfo> get services => Map.unmodifiable(_services);

  Future<void> initialize() async {
    if (!EnvConfig.enableServiceDiscovery) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    await _discoverServices();

    // Set up periodic refresh with backoff on failures
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _discoverServices(),
    );

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _discoverServices() async {
    try {
      final discoveryUrl = '${EnvConfig.serviceRegistryUrl}/v1/agent/services';

      final response = await http.get(
        Uri.parse(discoveryUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: EnvConfig.networkTimeout.inSeconds));

      if (response.statusCode == 200) {
        final Map<String, dynamic> servicesData = json.decode(response.body);

        // Clear existing services
        _services.clear();

        // Transform Consul service data format
        for (var entry in servicesData.entries) {
          final serviceData = entry.value;
          final service = ServiceInfo(
            name: serviceData['Service'] as String,
            baseUrl: 'http://${serviceData['Address']}:${serviceData['Port']}',
            isHealthy: true, // Will be updated by health check
            metadata: serviceData['Meta'] as Map<String, dynamic>? ?? {},
            healthStatus: {'status': 'UNKNOWN'},
          );
          _services[service.name] = service;
        }

        _consecutiveFailures = 0;
        notifyListeners();
      } else {
        _handleDiscoveryFailure(
            'Service discovery failed: ${response.statusCode}');
      }
    } catch (e) {
      _handleDiscoveryFailure('Error during service discovery: $e');
      // Fall back to direct service URLs if discovery fails
      _fallbackToDirectUrls();
    }
  }

  void _fallbackToDirectUrls() {
    _services.clear();
    // Add known services with direct URLs
    _services['gateway'] = ServiceInfo(
      name: 'gateway',
      baseUrl: EnvConfig.apiGatewayUrl,
      isHealthy: true,
      metadata: {},
    );
    _services['reports'] = ServiceInfo(
      name: 'reports',
      baseUrl: EnvConfig.reportsServiceUrl,
      isHealthy: true,
      metadata: {},
    );
    notifyListeners();
  }

  void _handleDiscoveryFailure(String error) {
    debugPrint(error);
    _consecutiveFailures++;

    if (_consecutiveFailures >= _maxFailures) {
      // After max failures, increase refresh interval with exponential backoff
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        _retryInterval * (_consecutiveFailures - _maxFailures + 1),
        (_) => _discoverServices(),
      );
    }
  }

  ServiceInfo? getServiceByName(String name) {
    return _services[name];
  }

  String? getServiceUrlByName(String name) {
    return _services[name]?.baseUrl;
  }

  List<ServiceInfo> getHealthyServices() {
    return _services.values.where((service) => service.isHealthy).toList();
  }

  Future<bool> checkServiceHealth(String name) async {
    final service = _services[name];
    if (service == null) return false;

    try {
      final response = await http
          .get(Uri.parse('${service.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));

      final isHealthy = response.statusCode == 200;

      if (_services.containsKey(name)) {
        _services[name] = ServiceInfo(
          name: service.name,
          baseUrl: service.baseUrl,
          isHealthy: isHealthy,
          metadata: service.metadata,
          healthStatus:
              isHealthy ? json.decode(response.body) : {'status': 'DOWN'},
        );
        notifyListeners();
      }

      return isHealthy;
    } catch (e) {
      debugPrint('Health check failed for $name: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getServiceMetrics(String name) async {
    final service = _services[name];
    if (service == null) return null;

    try {
      final response = await http
          .get(Uri.parse('${service.baseUrl}/metrics'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Failed to get metrics for $name: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
