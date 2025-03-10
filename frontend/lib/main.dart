import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'app_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Initialize and run the app using app_launcher.dart
    await initializeApp();
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
    rethrow;
  }
}
