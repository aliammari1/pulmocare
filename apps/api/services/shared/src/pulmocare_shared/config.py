"""
Base configuration module for PulmoCare microservices.

Provides a centralized configuration class that all services can extend.
"""

import os
from functools import lru_cache
from typing import Any

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class BaseConfig(BaseSettings):
    """Base configuration class for all PulmoCare microservices."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # Service info
    service_name: str = Field(default="unknown-service", description="Name of the service")
    version: str = Field(default="1.0.0", description="Service version")
    env: str = Field(default="development", description="Environment (development, staging, production)")
    debug: bool = Field(default=False, description="Debug mode")
    
    # Server settings
    host: str = Field(default="0.0.0.0", description="Server host")
    port: int = Field(default=8080, description="Server port")

    # Service Discovery - Consul
    consul_host: str = Field(default="localhost", description="Consul host")
    consul_port: int = Field(default=8500, description="Consul port")
    consul_token: str = Field(default="", alias="consul_http_token", description="Consul token")

    # MongoDB settings
    mongodb_host: str = Field(default="localhost", description="MongoDB host")
    mongodb_port: int = Field(default=27017, description="MongoDB port")
    mongodb_username: str = Field(default="admin", description="MongoDB username")
    mongodb_password: str = Field(default="admin", description="MongoDB password")
    mongodb_database: str = Field(default="pulmocare", description="MongoDB database")
    mongodb_pool_size: int = Field(default=50, description="MongoDB connection pool size")
    mongodb_min_pool_size: int = Field(default=10, description="MongoDB minimum pool size")
    mongodb_max_idle_time_ms: int = Field(default=60000, description="MongoDB max idle time")
    mongodb_connect_timeout_ms: int = Field(default=5000, description="MongoDB connect timeout")
    mongodb_server_selection_timeout_ms: int = Field(default=5000, description="MongoDB server selection timeout")

    # Redis settings
    redis_host: str = Field(default="localhost", description="Redis host")
    redis_port: int = Field(default=6379, description="Redis port")
    redis_db: int = Field(default=0, description="Redis database")
    redis_password: str = Field(default="redispass", description="Redis password")

    # RabbitMQ settings
    rabbitmq_host: str = Field(default="localhost", description="RabbitMQ host")
    rabbitmq_port: int = Field(default=5672, description="RabbitMQ port")
    rabbitmq_user: str = Field(default="guest", description="RabbitMQ user")
    rabbitmq_pass: str = Field(default="guest", description="RabbitMQ password")
    rabbitmq_vhost: str = Field(default="/", description="RabbitMQ virtual host")

    # Logging settings
    log_level: str = Field(default="INFO", description="Logging level")
    log_format: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        description="Log format"
    )
    log_dir: str = Field(default="logs", description="Log directory")
    log_max_size: int = Field(default=10485760, description="Max log file size (10MB)")
    log_backup_count: int = Field(default=5, description="Number of log backups to keep")

    # Monitoring settings
    metrics_port: int = Field(default=9090, description="Metrics port")
    enable_metrics: bool = Field(default=True, description="Enable metrics collection")

    # OpenTelemetry settings
    otel_exporter_otlp_endpoint: str = Field(
        default="http://localhost:4317",
        description="OTLP exporter endpoint"
    )
    otel_service_name: str = Field(default="", description="OpenTelemetry service name")
    otel_disable_on_error: bool = Field(default=True, description="Disable OTEL on connection error")
    otel_python_log_correlation: bool = Field(default=True, description="Enable log correlation")

    # Sentry settings (error tracking; PHI-scrubbed, PII off by default)
    sentry_dsn: str = Field(default="", description="Sentry DSN (empty disables Sentry)")
    sentry_traces_sample_rate: float = Field(
        default=0.0, description="Sentry tracing sample rate (0 = errors only)"
    )

    # Auth service settings
    auth_service_url: str = Field(default="http://auth-service:8086", description="Auth service URL")
    
    # JWT settings
    jwt_secret_key: str = Field(default="dev-jwt-secret-key-change-in-production", description="JWT secret key")
    jwt_access_token_expires: int = Field(default=3600, description="JWT access token expiry (seconds)")
    jwt_refresh_token_expires: int = Field(default=2592000, description="JWT refresh token expiry (seconds)")

    # Cache settings
    cache_ttl: int = Field(default=300, description="Cache TTL in seconds")
    cache_max_size: int = Field(default=1000, description="Maximum cache size")

    # Health Check settings
    health_check_interval: str = Field(default="10s", description="Health check interval")
    health_check_timeout: str = Field(default="5s", description="Health check timeout")
    health_check_deregister_timeout: str = Field(default="30s", description="Deregister after critical timeout")

    # Circuit Breaker settings
    circuit_breaker_failure_threshold: int = Field(default=5, description="Circuit breaker failure threshold")
    circuit_breaker_recovery_timeout: int = Field(default=30, description="Circuit breaker recovery timeout")

    # CORS settings
    cors_origins: list[str] = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        description="CORS allowed origins"
    )

    @property
    def is_development(self) -> bool:
        """Check if running in development mode."""
        return self.env.lower() == "development"

    @property
    def is_production(self) -> bool:
        """Check if running in production mode."""
        return self.env.lower() == "production"

    @property
    def mongodb_uri(self) -> str:
        """Get MongoDB connection URI."""
        return (
            f"mongodb://{self.mongodb_username}:{self.mongodb_password}@"
            f"{self.mongodb_host}:{self.mongodb_port}/{self.mongodb_database}"
            f"?authSource=admin"
        )

    @property
    def redis_url(self) -> str:
        """Get Redis connection URL."""
        return f"redis://:{self.redis_password}@{self.redis_host}:{self.redis_port}/{self.redis_db}"

    @property
    def rabbitmq_url(self) -> str:
        """Get RabbitMQ connection URL."""
        return (
            f"amqp://{self.rabbitmq_user}:{self.rabbitmq_pass}@"
            f"{self.rabbitmq_host}:{self.rabbitmq_port}/{self.rabbitmq_vhost}"
        )

    @property
    def log_file(self) -> str:
        """Get log file path."""
        return os.path.join(self.log_dir, f"{self.service_name}.log")

    @property
    def effective_otel_service_name(self) -> str:
        """Get effective OpenTelemetry service name."""
        return self.otel_service_name or self.service_name

    def model_post_init(self, __context: Any) -> None:
        """Post-initialization hook."""
        # Set debug based on environment
        if self.env.lower() == "development":
            object.__setattr__(self, "debug", True)


@lru_cache
def get_config() -> BaseConfig:
    """Get cached configuration instance."""
    return BaseConfig()


def load_env_file(env: str | None = None) -> None:
    """Load environment-specific .env file."""
    from dotenv import load_dotenv

    env = env or os.getenv("ENV", "development")
    env_file = f".env.{env}"
    
    if os.path.exists(env_file):
        load_dotenv(env_file, override=True)
    elif os.path.exists(".env"):
        load_dotenv(".env", override=True)
