"""
Appointments Service - FastAPI Application.

Handles appointment management and scheduling.
"""

import asyncio

import uvicorn
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer
from pulmocare_shared import LoggerService, setup_cors, setup_telemetry
from pulmocare_shared.middleware import health_router

from config import get_config
from consumer import AppointmentConsumer
from routes.appointments import router as appointments_router
from routes.integration import router as integration_router
from routes.scheduling import router as scheduling_router
from services.mongodb_client import MongoDBClient
from services.rabbitmq_client import RabbitMQClient

# Get configuration
config = get_config()

# Initialize logger
logger = LoggerService(config)

# Initialize the FastAPI application
app = FastAPI(
    title="Appointments API",
    description="API for appointment management",
    version=config.version,
    docs_url="/docs" if config.is_development else None,
    redoc_url="/redoc" if config.is_development else None,
    redirect_slashes=False,
)

# Security scheme
security = HTTPBearer()

# Setup CORS using shared module
setup_cors(app, config.cors_origins)

# Setup OpenTelemetry using shared module
setup_telemetry(app, config)

# Include health check router
app.include_router(health_router)

# Initialize RabbitMQ client and consumer
rabbitmq_client = RabbitMQClient(config)
appointment_consumer = AppointmentConsumer(config)

# Initialize MongoDB client
mongodb_client = MongoDBClient(config)


@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup"""
    try:
        # MongoDB connection is established during initialization
        logger.info("Database connection established")

        # RabbitMQ connection is established during RabbitMQClient initialization
        logger.info("RabbitMQ connection established")

        # Start background task to consume appointment messages
        asyncio.create_task(start_appointment_consumers())

        logger.info("Appointments service starting up")

    except Exception as e:
        logger.error(f"Startup error: {e!s}")
        raise


async def start_appointment_consumers():
    """Start RabbitMQ consumers for appointment messages"""
    try:
        # Connect and start the AppointmentConsumer
        await appointment_consumer.connect()
        await appointment_consumer.start_consuming()
        logger.info("Appointment message consumers started")
    except Exception as e:
        logger.error(f"Error starting message consumers: {e!s}")


async def close_database_client():
    """Close the database connection properly"""
    try:
        await mongodb_client.close_async()
        return True
    except Exception as e:
        logger.error(f"Error closing database connection: {e!s}")
        return False


@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on application shutdown"""
    try:
        # Stop the appointment consumer
        await appointment_consumer.stop_consuming()
        logger.info("Appointment consumers stopped")

        # Close database connection
        await close_database_client()
        logger.info("Database connection closed")

        # Close RabbitMQ connection
        rabbitmq_client.close()
        logger.info("RabbitMQ connection closed")

        logger.info("Appointments service shutting down")

    except Exception as e:
        logger.error(f"Shutdown error: {e!s}")


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for the application"""
    logger.error(f"Unhandled exception: {exc!s}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"message": "An unexpected error occurred"},
    )


# Include routers
app.include_router(appointments_router, prefix="/api/appointments", tags=["Appointments"])
app.include_router(scheduling_router, prefix="/api/scheduling", tags=["Scheduling"])
app.include_router(integration_router, prefix="/api/integration/appointments", tags=["Integration"])

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host=config.host,
        port=config.port,
        log_level="debug" if config.debug else "info",
        reload=config.is_development,
    )

