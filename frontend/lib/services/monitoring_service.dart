import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

enum ServiceHealth {
  healthy,
  degraded,
  unhealthy,
  unknown,
}

class ServiceStatus {
  final ServiceHealth health;
  final Map<String, bool> serviceStatuses;
  final DateTime timestamp;

  ServiceStatus({
    required this.health,
    required this.serviceStatuses,
    required this.timestamp,
  });

  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    final serviceStatuses = Map<String, bool>.from(json['services'] as Map);

    ServiceHealth health = ServiceHealth.unknown;
    if (serviceStatuses.values.every((status) => status)) {
      health = ServiceHealth.healthy;
    } else if (serviceStatuses.values.where((status) => status).length >
        serviceStatuses.length / 2) {
      health = ServiceHealth.degraded;
    } else {
      health = ServiceHealth.unhealthy;
    }

    return ServiceStatus(
      health: health,
      serviceStatuses: serviceStatuses,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class MonitoringService extends ChangeNotifier {
  Timer? _timer;
  ServiceStatus? _currentStatus;
  final List<Function(ServiceStatus)> _statusListeners = [];
  bool _isMonitoring = false;
  final Duration _refreshInterval;
  final List<String> _unhealthyServices = [];

  MonitoringService({
    Duration refreshInterval = const Duration(seconds: 30),
  }) : _refreshInterval = refreshInterval;

  ServiceStatus? get currentStatus => _currentStatus;
  bool get isMonitoring => _isMonitoring;
  List<String> get unhealthyServices => _unhealthyServices;

  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _updateStatus();
    _timer = Timer.periodic(_refreshInterval, (_) => _updateStatus());
    notifyListeners();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;

    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;
    notifyListeners();
  }

  Future<void> _updateStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.apiGatewayUrl}/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = ServiceStatus.fromJson(data);

        _currentStatus = status;
        _unhealthyServices.clear();

        status.serviceStatuses.forEach((service, isHealthy) {
          if (!isHealthy) {
            _unhealthyServices.add(service);
          }
        });

        // Notify all listeners about the updated status
        for (var listener in _statusListeners) {
          listener(status);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching service status: $e');
    }
  }

  void addStatusListener(Function(ServiceStatus) listener) {
    _statusListeners.add(listener);
  }

  void removeStatusListener(Function(ServiceStatus) listener) {
    _statusListeners.remove(listener);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
