import os

class Config:
    """Configuration settings for the radiologue service"""
    
    # Service settings
    SERVICE_NAME = "radiologue"
    SERVER_PORT = int(os.getenv('SERVER_PORT', 8084))
    
    # Consul settings
    CONSUL_HOST = os.getenv('CONSUL_HOST', 'localhost')
    CONSUL_PORT = int(os.getenv('CONSUL_PORT', 8500))
    CONSUL_TOKEN = os.getenv('CONSUL_HTTP_TOKEN')
    
    # MongoDB settings
    MONGODB_USERNAME = os.getenv('MONGODB_USERNAME', 'medapp')
    MONGODB_PASSWORD = os.getenv('MONGODB_PASSWORD', 'medapppass')
    MONGODB_HOST = os.getenv('MONGODB_HOST', 'mongodb')
    MONGODB_PORT = int(os.getenv('MONGODB_PORT', 27017))
    MONGODB_DATABASE = os.getenv('MONGODB_DATABASE', 'medapp')
    
    @classmethod
    def get_mongodb_uri(cls):
        """Get MongoDB connection URI"""
        return (f"mongodb://{cls.MONGODB_USERNAME}:{cls.MONGODB_PASSWORD}"
                f"@{cls.MONGODB_HOST}:{cls.MONGODB_PORT}/{cls.MONGODB_DATABASE}")