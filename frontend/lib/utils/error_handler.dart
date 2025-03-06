import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class ErrorHandler {
  static final Logger _logger = Logger('ErrorHandler');
  static final List<Function(String, dynamic)> _errorListeners = [];
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        debugPrint('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('Stack trace: ${record.stackTrace}');
      }
    });

    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.severe(
          'Uncaught Flutter error', details.exception, details.stack);
      // Still send to console in debug mode
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Handle errors from the Zone
    runZonedGuarded(
      () {},
      (error, stack) => _handleError('Uncaught Error', error),
    );
  }

  static void _handleError(String type, dynamic error) {
    for (var listener in _errorListeners) {
      listener(type, error);
    }
  }

  static void addListener(Function(String, dynamic) listener) {
    _errorListeners.add(listener);
  }

  static void removeListener(Function(String, dynamic) listener) {
    _errorListeners.remove(listener);
  }

  static String getServiceErrorMessage(dynamic error, String serviceName) {
    if (error is SocketException) {
      return 'Cannot connect to $serviceName service. Please check your network connection.';
    } else if (error is TimeoutException) {
      return '$serviceName service timed out. Please try again later.';
    } else if (error is FormatException) {
      return 'Invalid response from $serviceName service. Please try again.';
    } else {
      return 'An error occurred while communicating with $serviceName service: $error';
    }
  }

  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Network error. Please check your internet connection.';
    } else if (error is TimeoutException) {
      return 'The operation timed out. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    } else if (error is HttpException) {
      return 'HTTP error. Server may be unavailable.';
    } else {
      return error.toString();
    }
  }

  static void logError(String message,
      [dynamic error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  static void logWarning(String message) {
    _logger.warning(message);
  }

  static void logInfo(String message) {
    _logger.info(message);
  }

  static bool isServiceUnavailableError(dynamic error) {
    return error.toString().contains('503') ||
        error.toString().contains('Service Unavailable') ||
        error.toString().contains('SocketException');
  }

  static bool shouldRetry(dynamic error, int currentAttempt, int maxAttempts) {
    if (currentAttempt >= maxAttempts) return false;

    return isServiceUnavailableError(error) ||
        error.toString().contains('TimeoutException');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
