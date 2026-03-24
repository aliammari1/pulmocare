"""
Centralized logging service for PulmoCare microservices.

Provides structured logging with OpenTelemetry integration.
"""

import logging
import os
import socket
from functools import lru_cache
from logging.handlers import RotatingFileHandler
from typing import TYPE_CHECKING

import structlog
from opentelemetry._logs import set_logger_provider
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.resources import Resource

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class LoggerService:
    """Centralized logging service with OpenTelemetry integration."""

    _instance: "LoggerService | None" = None
    _initialized: bool = False

    def __new__(cls, config: "BaseConfig | None" = None) -> "LoggerService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, config: "BaseConfig | None" = None) -> None:
        if LoggerService._initialized:
            return

        if config is None:
            from pulmocare_shared.config import get_config
            config = get_config()

        self.config = config
        self._setup_logging()
        LoggerService._initialized = True

    def _setup_logging(self) -> None:
        """Set up the logging infrastructure."""
        # Create logs directory if it doesn't exist
        os.makedirs(self.config.log_dir, exist_ok=True)

        # Initialize the main logger
        self.logger = logging.getLogger(self.config.service_name)
        self.logger.setLevel(getattr(logging, self.config.log_level.upper(), logging.INFO))

        # Clear existing handlers to prevent duplicates
        self.logger.handlers.clear()

        # Create formatter
        formatter = logging.Formatter(self.config.log_format)

        # Add file handler
        self._add_file_handler(formatter)

        # Add console handler
        self._add_console_handler(formatter)

        # Setup OpenTelemetry logging
        self._setup_otel_logging()

        # Configure uvicorn/fastapi loggers
        self._setup_framework_logging()

        # Setup structlog
        self._setup_structlog()

    def _add_file_handler(self, formatter: logging.Formatter) -> None:
        """Add rotating file handler."""
        try:
            log_file_dir = os.path.dirname(self.config.log_file)
            if log_file_dir:
                os.makedirs(log_file_dir, exist_ok=True)

            file_handler = RotatingFileHandler(
                self.config.log_file,
                maxBytes=self.config.log_max_size,
                backupCount=self.config.log_backup_count,
            )
            file_handler.setFormatter(formatter)
            file_handler.setLevel(getattr(logging, self.config.log_level.upper(), logging.INFO))
            self.logger.addHandler(file_handler)
        except Exception as e:
            print(f"Failed to create file handler: {e}. Using console logging only.")

    def _add_console_handler(self, formatter: logging.Formatter) -> None:
        """Add console handler."""
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        console_handler.setLevel(getattr(logging, self.config.log_level.upper(), logging.INFO))
        self.logger.addHandler(console_handler)

    def _setup_otel_logging(self) -> None:
        """Set up OpenTelemetry logging export."""
        try:
            resource = Resource.create({
                "service.name": self.config.effective_otel_service_name,
                "service.version": self.config.version,
                "service.instance.id": socket.gethostname(),
                "deployment.environment": self.config.env,
            })

            logger_provider = LoggerProvider(resource=resource)
            set_logger_provider(logger_provider)

            # Determine the OTLP endpoint
            endpoint = self.config.otel_exporter_otlp_endpoint
            if self.config.is_development and "localhost" not in endpoint:
                endpoint = "http://localhost:4317"

            exporter = OTLPLogExporter(
                endpoint=endpoint,
                insecure=True,
            )
            logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))

            otel_handler = LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
            self.logger.addHandler(otel_handler)

            self.logger.info(f"OpenTelemetry logging initialized for {self.config.service_name}")
        except Exception as e:
            self.logger.warning(f"Failed to initialize OpenTelemetry logging: {e}")

    def _setup_framework_logging(self) -> None:
        """Configure FastAPI/uvicorn logging to use our handlers."""
        try:
            handlers = self.logger.handlers
            framework_loggers = ["uvicorn", "uvicorn.error", "uvicorn.access", "fastapi"]

            for logger_name in framework_loggers:
                framework_logger = logging.getLogger(logger_name)
                framework_logger.handlers.clear()
                framework_logger.propagate = False
                framework_logger.setLevel(getattr(logging, self.config.log_level.upper(), logging.INFO))

                for handler in handlers:
                    framework_logger.addHandler(handler)

            # Configure root logger
            root_logger = logging.getLogger()
            root_logger.setLevel(getattr(logging, self.config.log_level.upper(), logging.INFO))

            for handler in handlers:
                if handler not in root_logger.handlers:
                    root_logger.addHandler(handler)

        except Exception as e:
            self.logger.error(f"Failed to setup framework logging: {e}")

    def _setup_structlog(self) -> None:
        """Setup structlog for structured logging."""
        structlog.configure(
            processors=[
                structlog.contextvars.merge_contextvars,
                structlog.processors.add_log_level,
                structlog.processors.StackInfoRenderer(),
                structlog.dev.set_exc_info,
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer() if self.config.is_production else structlog.dev.ConsoleRenderer(),
            ],
            wrapper_class=structlog.make_filtering_bound_logger(
                getattr(logging, self.config.log_level.upper(), logging.INFO)
            ),
            context_class=dict,
            logger_factory=structlog.PrintLoggerFactory(),
            cache_logger_on_first_use=True,
        )

    def info(self, message: str, **kwargs) -> None:
        """Log info message."""
        self.logger.info(message, extra=kwargs)

    def warning(self, message: str, **kwargs) -> None:
        """Log warning message."""
        self.logger.warning(message, extra=kwargs)

    def error(self, message: str, **kwargs) -> None:
        """Log error message."""
        self.logger.error(message, extra=kwargs)

    def debug(self, message: str, **kwargs) -> None:
        """Log debug message."""
        self.logger.debug(message, extra=kwargs)

    def exception(self, message: str, **kwargs) -> None:
        """Log exception with traceback."""
        self.logger.exception(message, extra=kwargs)

    def critical(self, message: str, **kwargs) -> None:
        """Log critical message."""
        self.logger.critical(message, extra=kwargs)


@lru_cache
def get_logger(service_name: str | None = None) -> LoggerService:
    """Get cached logger instance."""
    if LoggerService._instance is None:
        from pulmocare_shared.config import BaseConfig
        config = BaseConfig()
        if service_name:
            object.__setattr__(config, "service_name", service_name)
        return LoggerService(config)
    return LoggerService._instance


# Convenience singleton
logger_service = None


def init_logger(config: "BaseConfig") -> LoggerService:
    """Initialize the logger service with config."""
    global logger_service
    logger_service = LoggerService(config)
    return logger_service
