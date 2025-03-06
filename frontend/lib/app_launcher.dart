import 'package:flutter/material.dart';
import 'package:medapp/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/service_locator.dart';
import 'services/cache_service.dart';
import 'services/service_discovery.dart';
import 'services/monitoring_service.dart';
import 'providers/theme_provider.dart';
import 'providers/xray_provider.dart';
import 'providers/report_provider.dart';
import 'utils/env_config.dart';
import 'utils/error_handler.dart';

Future<void> initializeApp() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  await EnvConfig.load();

  // Initialize error handling
  ErrorHandler.initialize();

  // Initialize shared preferences and services
  final prefs = await SharedPreferences.getInstance();
  final cacheService = CacheService(prefs);
  final serviceDiscovery = ServiceDiscovery();
  final monitoringService = MonitoringService();

  // Initialize service discovery and monitoring
  await serviceDiscovery.initialize();
  monitoringService.startMonitoring();

  // Initialize service locator
  setupServiceLocator();

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        Provider<CacheService>.value(value: cacheService),
        Provider<ServiceDiscovery>.value(value: serviceDiscovery),
        Provider<MonitoringService>.value(value: monitoringService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => XRayProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MedApp',
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(themeProvider.textScaleFactor),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
