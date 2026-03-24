"""
PulmoCare Patients Service.

Provides patient management functionality.
"""

import uvicorn
from fastapi import FastAPI
from fastapi.security import HTTPBearer

from pulmocare_shared import RedisClient, RabbitMQClient, setup_cors, setup_telemetry
from pulmocare_shared.middleware import create_health_router

from config import Config
from routes.integration_routes import router as integration_router
from routes.patients_routes import router as patients_router

# Initialize FastAPI app
app = FastAPI(
    title="PulmoCare Patients API",
    description="API for patient management",
    version=Config.version,
)

# Security scheme
security = HTTPBearer()

# Setup CORS
setup_cors(app, Config)

# Setup OpenTelemetry
setup_telemetry(Config, app)

# Initialize services using shared clients
redis_client = RedisClient(Config)
rabbitmq_client = RabbitMQClient(Config)

# Create health check router with dependencies
health_router = create_health_router(
    config=Config,
    redis_client=redis_client,
    rabbitmq_client=rabbitmq_client,
)

# Include routers
app.include_router(health_router)
app.include_router(integration_router)
app.include_router(patients_router)


# Keep legacy health endpoint for backward compatibility
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "UP", "service": Config.service_name}


if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host=Config.host,
        port=Config.port,
        reload=Config.is_development,
        log_level=Config.log_level.lower(),
    )
