import logging
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.pymongo import PymongoInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor

class TracingService:
    """Service for OpenTelemetry tracing"""
    
    def __init__(self, app):
        self.app = app
        self.logger = logging.getLogger(__name__)
        
        # Initialize OpenTelemetry
        self._setup_tracing()
    
    def _setup_tracing(self):
        """Set up OpenTelemetry tracing"""
        try:
            # Create a tracer provider
            tracer_provider = TracerProvider()
            trace.set_tracer_provider(tracer_provider)
            
            # Create an OTLP exporter
            otlp_exporter = OTLPSpanExporter(endpoint="http://jaeger:4317")
            
            # Add the exporter to the tracer provider
            tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
            
            # Instrument Flask
            FlaskInstrumentor().instrument_app(self.app)
            
            # Instrument libraries
            PymongoInstrumentor().instrument()
            RedisInstrumentor().instrument()
            
            # Create a tracer
            self.tracer = trace.get_tracer(__name__)
            
            self.logger.info("OpenTelemetry tracing initialized successfully")
        except Exception as e:
            self.logger.error(f"Failed to initialize OpenTelemetry tracing: {str(e)}")
            # Create a no-op tracer as fallback
            self.tracer = trace.get_tracer(__name__)
