import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error }

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static const int maxLogFiles = 5;
  static const String logFilePrefix = 'app_log_';

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  Future<String> get _logsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${appDir.path}/logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    return logsDir.path;
  }

  Future<void> log(String event, LogLevel level) async {
    final timestamp = DateTime.now();
    final formattedDate = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(timestamp);
    final logMessage = '$formattedDate [${level.name.toUpperCase()}] $event';

    // Write to today's log file
    await _writeToFile(logMessage);
  }

  Future<void> _writeToFile(String message) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logsDir = await _logsDirectory;
    final logFile = File('$logsDir/$logFilePrefix$today.log');

    await logFile.writeAsString('$message\n', mode: FileMode.append);
    await _cleanupOldLogs();
  }

  Future<void> _cleanupOldLogs() async {
    try {
      final logsDir = await _logsDirectory;
      final directory = Directory(logsDir);
      final files = await directory
          .list()
          .where(
            (entity) =>
                entity is File &&
                entity.path.contains(logFilePrefix) &&
                entity.path.endsWith('.log'),
          )
          .toList();

      if (files.length > maxLogFiles) {
        // Sort files by last modified timestamp
        files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );

        // Delete oldest files
        for (var i = maxLogFiles; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (_) {
      if (kDebugMode) debugPrint('Log cleanup failed');
    }
  }
}
