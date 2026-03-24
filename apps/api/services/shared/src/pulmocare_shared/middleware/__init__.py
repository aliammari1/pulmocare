"""
Middleware modules for FastAPI applications.
"""

from pulmocare_shared.middleware.cors import setup_cors
from pulmocare_shared.middleware.health import HealthCheckRouter, create_health_router

# Pre-created health router for simple use cases
# For services that just need basic health endpoints without custom dependency checks
health_router = create_health_router()

__all__ = [
    "setup_cors",
    "HealthCheckRouter",
    "create_health_router",
    "health_router",
]
