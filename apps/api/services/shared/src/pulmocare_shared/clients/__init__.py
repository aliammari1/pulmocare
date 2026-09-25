"""
Client modules for external services.
"""

from pulmocare_shared.clients.consul_client import ConsulClient
from pulmocare_shared.clients.mongodb_client import MongoDBClient
from pulmocare_shared.clients.rabbitmq_client import RabbitMQClient
from pulmocare_shared.clients.redis_client import RedisClient

__all__ = [
    "ConsulClient",
    "MongoDBClient",
    "RabbitMQClient",
    "RedisClient",
]
