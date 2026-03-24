"""
Radiologues Service - FastAPI Application.

Handles radiologist management and integration.
"""

import threading

import uvicorn
from fastapi import FastAPI
from pulmocare_shared import setup_cors, setup_telemetry
from pulmocare_shared.middleware import health_router

from config import get_config

# Get configuration
config = get_config()

# Initialize FastAPI app
app = FastAPI(
    title="Radiologues API",
    description="API for radiologist management",
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

# Create routes (import here to avoid circular imports)
from routes.integration_routes import router as integration_router
from routes.radiologist_routes import router as radiologist_router

# Include routers
app.include_router(integration_router)
app.include_router(radiologist_router)


if __name__ == "__main__":
    # Try to import the consumer module for background task
    try:
        from consumer import main as consumer_main

        # Start the consumer in a separate thread
        consumer_thread = threading.Thread(target=consumer_main, daemon=True)
        consumer_thread.start()
    except ImportError:
        pass  # Consumer module not found, skipping background tasks

    # Run the FastAPI app with uvicorn
    uvicorn.run(
        app,
        host=config.host,
        port=config.port,
        log_level="debug" if config.debug else "info",
    )

