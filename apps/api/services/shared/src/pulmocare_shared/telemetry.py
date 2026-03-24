"""
OpenTelemetry telemetry service for PulmoCare microservices.

Provides centralized tracing, metrics, and logging instrumentation.
"""

from typing import TYPE_CHECKING

from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor
from opentelemetry.instrumentation.pymongo import PymongoInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
from opentelemetry.trace import NoOpTracer, Tracer

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class TelemetryService:
    """
    Centralized OpenTelemetry service for distributed tracing and observability.
    
    Provides automatic instrumentation for:
    - FastAPI applications
    - HTTP clients (requests, httpx)
    - Redis
    - MongoDB
    - Python logging
    """

    _instance: "TelemetryService | None" = None
    _initialized: bool = False

    def __new__(cls, config: "BaseConfig | None" = None, app: FastAPI | None = None) -> "TelemetryService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, config: "BaseConfig | None" = None, app: FastAPI | None = None) -> None:
        if TelemetryService._initialized:
            return

        if config is None:
            from pulmocare_shared.config import get_config
            config = get_config()

        self.config = config
        self.app = app
        self.enabled = True
        self.tracer: Tracer = NoOpTracer()
        
        self._setup_tracing()
        TelemetryService._initialized = True

    def _setup_tracing(self) -> None:
        """Set up OpenTelemetry tracing infrastructure."""
        try:
            # Create resource identifying this service
            resource = Resource.create({
                "service.name": self.config.effective_otel_service_name,
                "service.version": self.config.version,
                "deployment.environment": self.config.env,
            })

            # Create tracer provider
            tracer_provider = TracerProvider(resource=resource)
            trace.set_tracer_provider(tracer_provider)

            # Configure OTLP exporter
            endpoint = self.config.otel_exporter_otlp_endpoint
            timeout = 3 if self.config.is_development else 10

            try:
                otlp_exporter = OTLPSpanExporter(
                    endpoint=endpoint,
                    insecure=True,
                    timeout=timeout,
                )
                tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
                
            except Exception as export_error:
                print(f"Warning: Failed to configure OTLP exporter: {export_error}")

                if self.config.is_development:
                    print("Using console exporter as fallback in development mode")
                    tracer_provider.add_span_processor(BatchSpanProcessor(ConsoleSpanExporter()))

                if self.config.otel_disable_on_error:
                    self.enabled = False
                    print("Tracing disabled due to connection error (OTEL_DISABLE_ON_ERROR=True)")

            # Instrument libraries if tracing is enabled
            if self.enabled:
                self._instrument_libraries()
                self.tracer = trace.get_tracer(__name__)
                print(f"OpenTelemetry tracing initialized for {self.config.effective_otel_service_name}")
            else:
                self.tracer = NoOpTracer()

        except Exception as e:
            print(f"Failed to initialize OpenTelemetry tracing: {e}")
            self.tracer = NoOpTracer()
            self.enabled = False

    def _instrument_libraries(self) -> None:
        """Instrument common libraries for tracing."""
        try:
            # Instrument Redis
            RedisInstrumentor().instrument()
        except Exception:
            pass

        try:
            # Instrument requests library
            RequestsInstrumentor().instrument()
        except Exception:
            pass

        try:
            # Instrument httpx
            HTTPXClientInstrumentor().instrument()
        except Exception:
            pass

        try:
            # Instrument MongoDB
            PymongoInstrumentor().instrument()
        except Exception:
            pass

        try:
            # Instrument logging
            LoggingInstrumentor().instrument(set_logging_format=True)
        except Exception:
            pass

    def instrument_app(self, app: FastAPI) -> None:
        """Instrument a FastAPI application."""
        if self.enabled:
            try:
                FastAPIInstrumentor().instrument_app(app)
                print(f"FastAPI instrumentation enabled for {self.config.effective_otel_service_name}")
            except Exception as e:
                print(f"Failed to instrument FastAPI app: {e}")

    def is_enabled(self) -> bool:
        """Check if tracing is enabled."""
        return self.enabled

    def get_tracer(self, name: str | None = None) -> Tracer:
        """Get a tracer instance."""
        if self.enabled:
            return trace.get_tracer(name or __name__)
        return NoOpTracer()

    def create_span(self, name: str, **kwargs):
        """Create a new span context manager."""
        return self.tracer.start_as_current_span(name, **kwargs)


def setup_telemetry(
    config: "BaseConfig",
    app: FastAPI | None = None,
) -> TelemetryService:
    """
    Set up telemetry for a microservice.
    
    Args:
        config: Service configuration
        app: Optional FastAPI application to instrument
        
    Returns:
        TelemetryService instance
    """
    telemetry = TelemetryService(config, app)
    
    if app is not None:
        telemetry.instrument_app(app)
    
    return telemetry


def get_telemetry() -> TelemetryService | None:
    """Get the current telemetry service instance."""
    return TelemetryService._instance
