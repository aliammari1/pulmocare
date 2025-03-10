import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.gatewayUrl;
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    return _executeWithRetry(
      () => http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
      ),
    );
  }

  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    return _executeWithRetry(
      () => http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: json.encode(data),
      ),
    );
  }

  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    return _executeWithRetry(
      () => http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: json.encode(data),
      ),
    );
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    return _executeWithRetry(
      () => http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
      ),
    );
  }

  Future<dynamic> _executeWithRetry(Future<http.Response> Function() request) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        final response = await request();
        return _handleResponse(response);
      } catch (e) {
        if (attempts >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(_retryDelay * attempts);
      }
    }
  }

  dynamic _handleResponse(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    switch (response.statusCode) {
      case 400:
        throw Exception('Bad request: ${data['message']}');
      case 401:
        throw Exception('Unauthorized: ${data['message']}');
      case 403:
        throw Exception('Forbidden: ${data['message']}');
      case 404:
        throw Exception('Not found: ${data['message']}');
      case 429:
        throw Exception('Too many requests. Please try again later.');
      case 503:
        throw Exception('Service unavailable. Please try again later.');
      case 504:
        throw Exception('Gateway timeout. Please try again later.');
      default:
        throw Exception(data['message'] ?? 'An unexpected error occurred');
    }
  }
}
