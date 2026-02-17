"""
PulmoCare Shared Module

Common utilities and shared services for PulmoCare microservices.
"""

from pulmocare_shared.config import BaseConfig, get_config
from pulmocare_shared.logging import LoggerService, get_logger
from pulmocare_shared.telemetry import TelemetryService, setup_telemetry
from pulmocare_shared.clients.redis_client import RedisClient
from pulmocare_shared.clients.rabbitmq_client import RabbitMQClient
from pulmocare_shared.clients.mongodb_client import MongoDBClient
from pulmocare_shared.clients.consul_client import ConsulClient
from pulmocare_shared.middleware.cors import setup_cors
from pulmocare_shared.middleware.health import HealthCheckRouter, create_health_router
from pulmocare_shared.middleware import health_router
from pulmocare_shared.metrics import MetricsService, setup_metrics

__version__ = "0.1.0"

__all__ = [
    # Config
    "BaseConfig",
    "get_config",
    # Logging
    "LoggerService",
    "get_logger",
    # Telemetry
    "TelemetryService",
    "setup_telemetry",
    # Clients
    "RedisClient",
    "RabbitMQClient",
    "MongoDBClient",
    "ConsulClient",
    # Middleware
    "setup_cors",
    "HealthCheckRouter",
    "create_health_router",
    "health_router",
    # Metrics
    "MetricsService",
    "setup_metrics",
]
