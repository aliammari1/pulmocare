import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'xray_service.dart';
import 'knowledge_service.dart';
import 'cache_service.dart';
import 'navigation_service.dart';
import 'monitoring_service.dart';
import '../services/api_config.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Initialize services that require async initialization
  final sharedPreferences = await SharedPreferences.getInstance();

  // Register services
  locator.registerSingleton<CacheService>(CacheService(sharedPreferences));
  locator.registerSingleton<NavigationService>(NavigationService());
  locator.registerSingleton<MonitoringService>(MonitoringService());

  // Register API services
  locator
      .registerSingleton<XRayService>(XRayService(baseUrl: ApiConfig.baseUrl));
  locator.registerSingleton<KnowledgeService>(KnowledgeService());
}

// Service interface for dynamic loading of microfrontends
abstract class MicroFrontendService {
  String get name;
  String get route;
  Future<void> initialize();
  void dispose();
}
