"""
Medecins Service - FastAPI Application.

Handles doctor profile management and integration.
"""

import threading

import uvicorn
from fastapi import FastAPI
from pulmocare_shared import setup_cors, setup_telemetry
from pulmocare_shared.middleware import health_router

from config import get_config
from routes.doctor_routes import router as doctor_router
from routes.integration_routes import router as integration_router

# Get configuration
config = get_config()

# Initialize FastAPI app
app = FastAPI(
    title="MedApp Doctors Service",
    description="API for managing doctor profiles and authentication",
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
app.include_router(integration_router)
app.include_router(doctor_router)

# Import the consumer module and threading
from consumer import main as consumer_main

if __name__ == "__main__":
    # Start the consumer in a separate thread
    consumer_thread = threading.Thread(target=consumer_main, daemon=True)
    consumer_thread.start()

    # Run the FastAPI app with uvicorn in the main thread
    uvicorn.run(
        "app:app",
        host=config.host,
        port=config.port,
        reload=config.is_development,
        log_level="debug" if config.debug else "info",
    )

