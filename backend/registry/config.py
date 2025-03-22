import os

class Config:
    # Service info
    SERVICE_NAME = os.getenv('SERVICE_NAME', 'unknown-service')
    SERVICE_VERSION = os.getenv('SERVICE_VERSION', '1.0')
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 8761))
    
    # Consul configuration
    CONSUL_HOST = os.getenv('CONSUL_HOST', 'consul')
    CONSUL_PORT = int(os.getenv('CONSUL_PORT', 8500))
    CONSUL_SCHEME = os.getenv('CONSUL_SCHEME', 'http')
    
    # Redis configuration
    REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', 'redispass')
    REDIS_DB = int(os.getenv('REDIS_DB', 0))
    
    # MongoDB configuration
    MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://admin:admin@mongodb:27017/')
    MONGODB_DATABASE = os.getenv('MONGODB_DATABASE', 'medapp')
    
    # RabbitMQ configuration
    RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'rabbitmq')
    RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', 5672))
    RABBITMQ_USER = os.getenv('RABBITMQ_USER', 'guest')
    RABBITMQ_PASS = os.getenv('RABBITMQ_PASS', 'guest')
    
    # Rate limiting
    RATE_LIMIT_STORAGE_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"
    
    # Service discovery
    SERVICE_REGISTRY_URL = f"http://{CONSUL_HOST}:{CONSUL_PORT}"
    SERVICE_CHECK_INTERVAL = "10s"
    SERVICE_CHECK_TIMEOUT = "5s"
    SERVICE_CHECK_DEREGISTER_AFTER = "30s"
    
    # API Gateway (Kong)
    KONG_ADMIN_URL = os.getenv('KONG_ADMIN_URL', 'http://kong:8001')
    
    @classmethod
    def get_consul_config(cls):
        """Get Consul configuration dictionary"""
        return {
            'host': cls.CONSUL_HOST,
            'port': cls.CONSUL_PORT,
            'scheme': cls.CONSUL_SCHEME
        }
    
    @classmethod
    def get_redis_config(cls):
        """Get Redis configuration dictionary"""
        return {
            'host': cls.REDIS_HOST,
            'port': cls.REDIS_PORT,
            'password': cls.REDIS_PASSWORD,
            'db': cls.REDIS_DB
        }
    
    @classmethod
    def get_rabbitmq_config(cls):
        """Get RabbitMQ configuration dictionary"""
        return {
            'host': cls.RABBITMQ_HOST,
            'port': cls.RABBITMQ_PORT,
            'username': cls.RABBITMQ_USER,
            'password': cls.RABBITMQ_PASS
        }