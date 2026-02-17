"""
Ordonnances Service - FastAPI Application.

Handles medical prescriptions (ordonnances) management.
"""

import uvicorn
from fastapi import FastAPI
from pulmocare_shared import setup_cors, setup_telemetry
from pulmocare_shared.middleware import health_router

from config import get_config
from routes.ordonnance_routes import ordonnance_router

# Get configuration
config = get_config()

app = FastAPI(
    title="Ordonnances API",
    description="API pour la gestion des ordonnances médicales",
    version=config.version,
    docs_url="/docs" if config.is_development else None,
    redoc_url="/redoc" if config.is_development else None,
)

# Setup CORS using shared module
setup_cors(app, config.cors_origins)

# Setup OpenTelemetry using shared module
setup_telemetry(app, config)

# Include health check router
app.include_router(health_router)

# Include service routers
app.include_router(ordonnance_router, prefix="/ordonnances")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=config.host,
        port=config.port,
        reload=config.is_development,
        log_level="debug" if config.debug else "info",
    )
