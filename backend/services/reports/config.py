import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    """Configuration for the Medical App backend microservice"""
    
    # Application settings
    APP_NAME = "MedApp Reports Service"
    DEBUG = os.getenv("DEBUG", "False").lower() in ("true", "t", "1", "yes")
    ENV = os.getenv("ENV", "development")
    VERSION = "1.0.0"
    
    # Server settings
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", "5000"))
    
    # Service Discovery settings
    CONSUL_HOST = os.getenv("CONSUL_HOST", "consul")
    CONSUL_PORT = int(os.getenv("CONSUL_PORT", "8500"))
    CONSUL_TOKEN = os.getenv("CONSUL_HTTP_TOKEN")
    SERVICE_NAME = "reports"
    
    # MongoDB settings
    MONGODB_HOST = os.getenv("MONGODB_HOST", "mongodb")
    MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
    MONGODB_USERNAME = os.getenv("MONGODB_USERNAME", "medapp")
    MONGODB_PASSWORD = os.getenv("MONGODB_PASSWORD", "medapppass")
    MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "medapp")
    MONGODB_POOL_SIZE = int(os.getenv("MONGODB_POOL_SIZE", "50"))
    MONGODB_MIN_POOL_SIZE = int(os.getenv("MONGODB_MIN_POOL_SIZE", "10"))
    MONGODB_MAX_IDLE_TIME_MS = int(os.getenv("MONGODB_MAX_IDLE_TIME_MS", "60000"))
    MONGODB_CONNECT_TIMEOUT_MS = int(os.getenv("MONGODB_CONNECT_TIMEOUT_MS", "5000"))
    MONGODB_SERVER_SELECTION_TIMEOUT_MS = int(os.getenv("MONGODB_SERVER_SELECTION_TIMEOUT_MS", "5000"))
    
    # Redis settings
    REDIS_HOST = os.getenv("REDIS_HOST", "redis")
    REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
    REDIS_DB = int(os.getenv("REDIS_DB", "0"))
    
    # RabbitMQ settings
    RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
    RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
    RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
    RABBITMQ_PASS = os.getenv("RABBITMQ_PASS", "guest")
    RABBITMQ_VHOST = os.getenv("RABBITMQ_VHOST", "/")
    
    # Logging settings
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    LOG_DIR = os.getenv("LOG_DIR", "logs")
    LOG_FILE = os.path.join(LOG_DIR, f"{SERVICE_NAME}.log")
    LOG_MAX_SIZE = int(os.getenv("LOG_MAX_SIZE", "10485760"))  # 10MB
    LOG_BACKUP_COUNT = int(os.getenv("LOG_BACKUP_COUNT", "5"))
    
    # Monitoring settings
    METRICS_PORT = int(os.getenv("METRICS_PORT", "9090"))
    ENABLE_METRICS = os.getenv("ENABLE_METRICS", "True").lower() in ("true", "t", "1", "yes")
    
    # Tracing settings
    OTEL_EXPORTER_OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317")
    OTEL_SERVICE_NAME = SERVICE_NAME
    
    # Circuit Breaker settings
    CIRCUIT_BREAKER_FAILURE_THRESHOLD = int(os.getenv("CIRCUIT_BREAKER_FAILURE_THRESHOLD", "5"))
    CIRCUIT_BREAKER_RECOVERY_TIMEOUT = int(os.getenv("CIRCUIT_BREAKER_RECOVERY_TIMEOUT", "60"))
    
    # Health Check settings
    HEALTH_CHECK_INTERVAL = os.getenv("HEALTH_CHECK_INTERVAL", "10s")
    HEALTH_CHECK_TIMEOUT = os.getenv("HEALTH_CHECK_TIMEOUT", "5s")
    HEALTH_CHECK_DEREGISTER_TIMEOUT = os.getenv("HEALTH_CHECK_DEREGISTER_TIMEOUT", "30s")
    
    # Service Dependencies
    REQUIRED_SERVICES = ['xray-service', 'knowledge-service']
    
    # Cache settings
    CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))  # 5 minutes
    CACHE_MAX_SIZE = int(os.getenv("CACHE_MAX_SIZE", "1000"))
    
    @classmethod
    def get_mongodb_uri(cls):
        """Get MongoDB connection URI with proper handling of special characters in password"""
        username = urllib.parse.quote_plus(cls.MONGODB_USERNAME)
        password = urllib.parse.quote_plus(cls.MONGODB_PASSWORD)
        return (f"mongodb://{username}:{password}@"
                f"{cls.MONGODB_HOST}:{cls.MONGODB_PORT}/{cls.MONGODB_DATABASE}")
    
    @classmethod
    def get_rabbitmq_uri(cls):
        """Get RabbitMQ connection URI"""
        return (f"amqp://{cls.RABBITMQ_USER}:{cls.RABBITMQ_PASS}@"
                f"{cls.RABBITMQ_HOST}:{cls.RABBITMQ_PORT}/{cls.RABBITMQ_VHOST}")
    
    @classmethod
    def init_logging(cls):
        """Initialize logging configuration"""
        os.makedirs(cls.LOG_DIR, exist_ok=True)
        return {
            'version': 1,
            'disable_existing_loggers': False,
            'formatters': {
                'standard': {
                    'format': cls.LOG_FORMAT
                },
            },
            'handlers': {
                'file': {
                    'level': cls.LOG_LEVEL,
                    'class': 'logging.handlers.RotatingFileHandler',
                    'filename': cls.LOG_FILE,
                    'maxBytes': cls.LOG_MAX_SIZE,
                    'backupCount': cls.LOG_BACKUP_COUNT,
                    'formatter': 'standard',
                },
                'console': {
                    'level': cls.LOG_LEVEL,
                    'class': 'logging.StreamHandler',
                    'formatter': 'standard',
                },
            },
            'loggers': {
                '': {
                    'handlers': ['console', 'file'],
                    'level': cls.LOG_LEVEL,
                    'propagate': True
                }
            }
        }
    
    @classmethod
    def validate(cls):
        """Validate required configuration settings"""
        required_settings = [
            'MONGODB_USERNAME',
            'MONGODB_PASSWORD',
            'MONGODB_HOST',
            'CONSUL_HOST',
            'RABBITMQ_HOST'
        ]
        
        missing = [setting for setting in required_settings
                  if not getattr(cls, setting, None)]
        
        if missing:
            raise ValueError(f"Missing required configuration: {', '.join(missing)}")