"""
Health check router for FastAPI applications.
"""

from typing import TYPE_CHECKING, Any

from fastapi import APIRouter
from pydantic import BaseModel

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class HealthCheckResponse(BaseModel):
    """Health check response model."""

    status: str
    service: str
    version: str
    environment: str
    dependencies: dict[str, str] | None = None


class HealthCheckRouter:
    """Health check router factory."""

    def __init__(self, config: "BaseConfig | None" = None):
        if config is None:
            from pulmocare_shared.config import get_config
            config = get_config()

        self.config = config
        self.dependency_checks: dict[str, callable] = {}

    def add_dependency_check(self, name: str, check_func: callable) -> "HealthCheckRouter":
        """Add a dependency health check."""
        self.dependency_checks[name] = check_func
        return self

    def _check_dependencies(self) -> dict[str, str]:
        """Run all dependency health checks."""
        results = {}
        for name, check_func in self.dependency_checks.items():
            try:
                results[name] = check_func()
            except Exception as e:
                results[name] = f"DOWN: {e}"
        return results

    def create_router(self, prefix: str = "", tags: list[str] | None = None) -> APIRouter:
        """Create the health check router."""
        router = APIRouter(prefix=prefix, tags=tags or ["health"])

        @router.get("/health", response_model=HealthCheckResponse)
        async def health_check() -> HealthCheckResponse:
            """Basic health check endpoint."""
            dependencies = self._check_dependencies() if self.dependency_checks else None

            # Determine overall status based on dependencies
            status = "healthy"
            if dependencies:
                for dep_status in dependencies.values():
                    if dep_status != "UP":
                        status = "degraded"
                        break

            return HealthCheckResponse(
                status=status,
                service=self.config.service_name,
                version=self.config.version,
                environment=self.config.env,
                dependencies=dependencies,
            )

        @router.get("/health/live")
        async def liveness_check() -> dict[str, str]:
            """Kubernetes liveness probe endpoint."""
            return {"status": "alive"}

        @router.get("/health/ready")
        async def readiness_check() -> dict[str, Any]:
            """Kubernetes readiness probe endpoint."""
            dependencies = self._check_dependencies() if self.dependency_checks else {}
            
            all_up = all(status == "UP" for status in dependencies.values()) if dependencies else True
            
            return {
                "status": "ready" if all_up else "not_ready",
                "checks": dependencies,
            }

        return router


def create_health_router(
    config: "BaseConfig | None" = None,
    redis_client: Any | None = None,
    mongodb_client: Any | None = None,
    rabbitmq_client: Any | None = None,
    consul_client: Any | None = None,
) -> APIRouter:
    """
    Create a health check router with common dependency checks.

    Args:
        config: Service configuration
        redis_client: Optional Redis client for health check
        mongodb_client: Optional MongoDB client for health check
        rabbitmq_client: Optional RabbitMQ client for health check
        consul_client: Optional Consul client for health check

    Returns:
        Configured APIRouter with health check endpoints
    """
    health_router = HealthCheckRouter(config)

    if redis_client is not None:
        health_router.add_dependency_check("redis", redis_client.check_health)

    if mongodb_client is not None:
        health_router.add_dependency_check("mongodb", mongodb_client.check_health)

    if rabbitmq_client is not None:
        health_router.add_dependency_check("rabbitmq", rabbitmq_client.check_health)

    if consul_client is not None:
        health_router.add_dependency_check("consul", consul_client.check_health)

    return health_router.create_router()
