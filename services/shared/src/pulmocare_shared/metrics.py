"""
Metrics service for Prometheus metrics collection.
"""

from typing import TYPE_CHECKING

from prometheus_client import Counter, Gauge, Histogram, Info, generate_latest
from fastapi import APIRouter, Response

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class MetricsService:
    """Service for collecting and exposing Prometheus metrics."""

    _instance: "MetricsService | None" = None
    _initialized: bool = False

    # Common metrics
    http_requests_total: Counter
    http_request_duration_seconds: Histogram
    http_requests_in_progress: Gauge
    service_info: Info

    # Cache metrics
    cache_hits_total: Counter
    cache_misses_total: Counter

    # Message queue metrics
    messages_published_total: Counter
    messages_consumed_total: Counter
    message_processing_duration_seconds: Histogram

    # Database metrics
    db_operations_total: Counter
    db_operation_duration_seconds: Histogram

    def __new__(cls, config: "BaseConfig | None" = None) -> "MetricsService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, config: "BaseConfig | None" = None) -> None:
        if MetricsService._initialized:
            return

        if config is None:
            from pulmocare_shared.config import get_config
            config = get_config()

        self.config = config
        self._setup_metrics()
        MetricsService._initialized = True

    def _setup_metrics(self) -> None:
        """Initialize Prometheus metrics."""
        service_name = self.config.service_name

        # HTTP metrics
        self.http_requests_total = Counter(
            "http_requests_total",
            "Total HTTP requests",
            ["service", "method", "endpoint", "status_code"],
        )

        self.http_request_duration_seconds = Histogram(
            "http_request_duration_seconds",
            "HTTP request duration in seconds",
            ["service", "method", "endpoint"],
            buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
        )

        self.http_requests_in_progress = Gauge(
            "http_requests_in_progress",
            "HTTP requests currently in progress",
            ["service", "method", "endpoint"],
        )

        # Service info
        self.service_info = Info(
            "service_info",
            "Service information",
        )
        self.service_info.info({
            "service_name": service_name,
            "version": self.config.version,
            "environment": self.config.env,
        })

        # Cache metrics
        self.cache_hits_total = Counter(
            "cache_hits_total",
            "Total cache hits",
            ["service", "cache_name"],
        )

        self.cache_misses_total = Counter(
            "cache_misses_total",
            "Total cache misses",
            ["service", "cache_name"],
        )

        # Message queue metrics
        self.messages_published_total = Counter(
            "messages_published_total",
            "Total messages published",
            ["service", "exchange", "routing_key"],
        )

        self.messages_consumed_total = Counter(
            "messages_consumed_total",
            "Total messages consumed",
            ["service", "queue", "status"],
        )

        self.message_processing_duration_seconds = Histogram(
            "message_processing_duration_seconds",
            "Message processing duration in seconds",
            ["service", "queue"],
            buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
        )

        # Database metrics
        self.db_operations_total = Counter(
            "db_operations_total",
            "Total database operations",
            ["service", "operation", "collection"],
        )

        self.db_operation_duration_seconds = Histogram(
            "db_operation_duration_seconds",
            "Database operation duration in seconds",
            ["service", "operation", "collection"],
            buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0),
        )

    def track_request(
        self,
        method: str,
        endpoint: str,
        status_code: int,
        duration: float,
    ) -> None:
        """Track an HTTP request."""
        service = self.config.service_name
        self.http_requests_total.labels(
            service=service,
            method=method,
            endpoint=endpoint,
            status_code=str(status_code),
        ).inc()

        self.http_request_duration_seconds.labels(
            service=service,
            method=method,
            endpoint=endpoint,
        ).observe(duration)

    def track_cache(self, cache_name: str, hit: bool) -> None:
        """Track a cache access."""
        service = self.config.service_name
        if hit:
            self.cache_hits_total.labels(service=service, cache_name=cache_name).inc()
        else:
            self.cache_misses_total.labels(service=service, cache_name=cache_name).inc()

    def track_message_published(self, exchange: str, routing_key: str) -> None:
        """Track a published message."""
        self.messages_published_total.labels(
            service=self.config.service_name,
            exchange=exchange,
            routing_key=routing_key,
        ).inc()

    def track_message_consumed(self, queue: str, success: bool) -> None:
        """Track a consumed message."""
        self.messages_consumed_total.labels(
            service=self.config.service_name,
            queue=queue,
            status="success" if success else "failure",
        ).inc()

    def track_db_operation(self, operation: str, collection: str, duration: float) -> None:
        """Track a database operation."""
        service = self.config.service_name
        self.db_operations_total.labels(
            service=service,
            operation=operation,
            collection=collection,
        ).inc()

        self.db_operation_duration_seconds.labels(
            service=service,
            operation=operation,
            collection=collection,
        ).observe(duration)


def setup_metrics(config: "BaseConfig | None" = None) -> MetricsService:
    """Set up metrics service."""
    return MetricsService(config)


def get_metrics() -> MetricsService | None:
    """Get the current metrics service instance."""
    return MetricsService._instance


def create_metrics_router(prefix: str = "/metrics", tags: list[str] | None = None) -> APIRouter:
    """Create a router that exposes Prometheus metrics."""
    router = APIRouter(prefix=prefix, tags=tags or ["metrics"])

    @router.get("")
    async def metrics() -> Response:
        """Prometheus metrics endpoint."""
        return Response(
            content=generate_latest(),
            media_type="text/plain; version=0.0.4; charset=utf-8",
        )

    return router
