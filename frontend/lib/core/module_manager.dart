import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import '../services/rabbitmq_service.dart';

final getIt = GetIt.instance;

class AppModuleManager {
  static final _logger = Logger('AppModuleManager');
  static final AppModuleManager _instance = AppModuleManager._internal();

  factory AppModuleManager() => _instance;
  AppModuleManager._internal();

  Future<void> initialize() async {
    try {
      // Register core modules
      await _initializeCoreModule();

      // Register feature modules
      await _initializeXRayModule();
      await _initializeKnowledgeModule();

      _logger.info('All modules initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize modules: $e');
      rethrow;
    }
  }

  Future<void> _initializeCoreModule() async {
    try {
      // Initialize core services
      await RabbitMQService().initialize();

      // Register core dependencies
      getIt.registerSingleton(RabbitMQService());

      _logger.info('Core module initialized');
    } catch (e) {
      _logger.severe('Failed to initialize core module: $e');
      rethrow;
    }
  }

  Future<void> _initializeXRayModule() async {
    try {
      // Register X-Ray analysis dependencies
      await _registerXRayDependencies();
      _logger.info('X-Ray module initialized');
    } catch (e) {
      _logger.severe('Failed to initialize X-Ray module: $e');
      rethrow;
    }
  }

  Future<void> _initializeKnowledgeModule() async {
    try {
      // Register knowledge base dependencies
      await _registerKnowledgeDependencies();
      _logger.info('Knowledge module initialized');
    } catch (e) {
      _logger.severe('Failed to initialize Knowledge module: $e');
      rethrow;
    }
  }

  Future<void> _registerXRayDependencies() async {
    // TODO: Register X-Ray specific services
  }

  Future<void> _registerKnowledgeDependencies() async {
    // TODO: Register Knowledge specific services
  }

  T? resolve<T extends Object>() {
    try {
      return getIt<T>();
    } catch (e) {
      _logger.warning('Failed to resolve type $T: $e');
      return null;
    }
  }

  bool isModuleInitialized(String moduleName) {
    // Check if core services for the module are registered
    switch (moduleName.toLowerCase()) {
      case 'core':
        return getIt.isRegistered<RabbitMQService>();
      case 'xray':
        // TODO: Add checks for X-Ray services
        return false;
      case 'knowledge':
        // TODO: Add checks for Knowledge services
        return false;
      default:
        return false;
    }
  }
}
