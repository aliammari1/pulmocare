"""
PulmoCare Authentication Service.

Provides authentication and authorization via Keycloak.
"""

import uvicorn
from fastapi import FastAPI

from pulmocare_shared import setup_cors, setup_telemetry
from pulmocare_shared.middleware import create_health_router

from config import Config
from models.auth import HealthCheckResponse
from routes.auth_routes import router as auth_router
from routes.integration_routes import router as integration_router
from services.keycloak_service import KeycloakService

# Initialize FastAPI app
app = FastAPI(
    title="PulmoCare Auth Service",
    description="Authentication and authorization service",
    version=Config.version,
)

# Setup CORS
setup_cors(app, Config)

# Setup OpenTelemetry
setup_telemetry(Config, app)

# Initialize Keycloak service
keycloak_service = KeycloakService()


# Health check endpoint (keeping original for backward compatibility)
@app.get("/health", response_model=HealthCheckResponse)
def health_check():
    return {"status": "healthy", "service": Config.service_name}


# Include the routers
app.include_router(auth_router)
app.include_router(integration_router)

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host=Config.host,
        port=Config.port,
        reload=Config.is_development,
        log_level=Config.log_level.lower(),
    )
