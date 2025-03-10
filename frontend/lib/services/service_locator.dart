import 'package:get_it/get_it.dart';
import 'package:medapp/services/api_service.dart';
import 'package:medapp/services/cache_service.dart';
import 'package:medapp/services/monitoring_service.dart';
import 'package:medapp/services/navigation_service.dart';
import 'package:medapp/services/report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Initialize services that require async initialization
  final sharedPreferences = await SharedPreferences.getInstance();

  // Register services
  locator.registerSingleton<CacheService>(CacheService(sharedPreferences));
  locator.registerSingleton<NavigationService>(NavigationService());
  locator.registerSingleton<MonitoringService>(MonitoringService());

  // Register API services
  locator.registerSingleton<ReportService>(ReportService());
  locator.registerSingleton<ApiService>(ApiService());
}

// Service interface for dynamic loading of microfrontends
abstract class MicroFrontendService {
  String get name;
  String get route;
  Future<void> initialize();
  void dispose();
}
