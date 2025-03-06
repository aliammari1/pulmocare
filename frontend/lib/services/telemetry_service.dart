import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../config/environment.dart';

class TelemetryService {
  static final _logger = Logger('TelemetryService');
  static final TelemetryService _instance = TelemetryService._internal();
  final Map<String, String> _globalAttributes = {};

  factory TelemetryService() => _instance;
  TelemetryService._internal();

  void setGlobalAttribute(String key, String value) {
    _globalAttributes[key] = value;
  }

  Future<void> sendSpan({
    required String name,
    required String traceId,
    required String spanId,
    required String parentSpanId,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, String> attributes = const {},
    String? statusCode,
    String? statusMessage,
  }) async {
    if (!EnvironmentConfig.enableTracing) return;

    try {
      final Map<String, dynamic> span = {
        'name': name,
        'trace_id': traceId,
        'span_id': spanId,
        'parent_span_id': parentSpanId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'attributes': {..._globalAttributes, ...attributes},
        'status': {
          'code': statusCode ?? 'OK',
          'message': statusMessage,
        },
      };

      final response = await http.post(
        Uri.parse('${EnvironmentConfig.otelCollectorUrl}/v1/traces'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'resourceSpans': [span]
        },
      );

      if (response.statusCode != 200) {
        _logger.warning(
            'Failed to send span: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error sending span: $e');
    }
  }

  Future<void> sendMetric({
    required String name,
    required String type,
    required num value,
    Map<String, String> labels = const {},
  }) async {
    try {
      final Map<String, dynamic> metric = {
        'name': name,
        'type': type,
        'value': value,
        'labels': {..._globalAttributes, ...labels},
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${EnvironmentConfig.otelCollectorUrl}/v1/metrics'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'resourceMetrics': [metric]
        },
      );

      if (response.statusCode != 200) {
        _logger.warning(
            'Failed to send metric: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error sending metric: $e');
    }
  }

  Future<void> sendLog({
    required String message,
    required String severity,
    Map<String, String> attributes = const {},
  }) async {
    if (!EnvironmentConfig.enableLogging) return;

    try {
      final Map<String, dynamic> log = {
        'timestamp': DateTime.now().toIso8601String(),
        'severity': severity,
        'message': message,
        'attributes': {..._globalAttributes, ...attributes},
      };

      final response = await http.post(
        Uri.parse('${EnvironmentConfig.otelCollectorUrl}/v1/logs'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'resourceLogs': [log]
        },
      );

      if (response.statusCode != 200) {
        _logger.warning(
            'Failed to send log: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error sending log: $e');
    }
  }

  String generateTraceId() {
    return List.generate(
            32,
            (_) =>
                '0123456789abcdef'[DateTime.now().millisecondsSinceEpoch % 16])
        .join();
  }

  String generateSpanId() {
    return List.generate(
            16,
            (_) =>
                '0123456789abcdef'[DateTime.now().millisecondsSinceEpoch % 16])
        .join();
  }
}
