import logging
import os
import socket
from logging.handlers import RotatingFileHandler

from opentelemetry._logs import set_logger_provider
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.resources import Resource

from config import Config


class LoggerService:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)

            # Create logs directory if it doesn't exist
            os.makedirs(Config.log_dir, exist_ok=True)

            # Ensure the log file path exists
            log_file_dir = os.path.dirname(Config.log_file)
            if log_file_dir:
                os.makedirs(log_file_dir, exist_ok=True)

            # Initialize logger
            cls._instance.logger = logging.getLogger(Config.service_name)
            cls._instance.logger.setLevel(Config.log_level)

            # Create formatters and handlers
            formatter = logging.Formatter(Config.log_format)

            try:
                # File Handler
                file_handler = RotatingFileHandler(
                    Config.log_file,
                    maxBytes=Config.log_max_size,
                    backupCount=Config.log_backup_count,
                )
                file_handler.setFormatter(formatter)
                file_handler.setLevel(Config.log_level)
                cls._instance.logger.addHandler(file_handler)
            except Exception as e:
                print(f"Failed to create file handler: {e!s}. Using console logging only.")

            # Console Handler
            console_handler = logging.StreamHandler()
            console_handler.setFormatter(formatter)
            console_handler.setLevel(Config.log_level)

            # Add handlers to logger
            cls._instance.logger.addHandler(console_handler)

            # Setup OpenTelemetry logging
            cls._instance._setup_otel_logging()

            # Initialize file storage logging
            cls._instance._initialize_file_storage_logging()

        return cls._instance

    def _setup_otel_logging(self):
        """Set up OpenTelemetry logging"""
        try:
            # Create a Resource to identify the service
            resource = Resource.create(
                {
                    "service.name": Config.service_name,
                    "service.instance.id": socket.gethostname(),
                }
            )

            # Create the LoggerProvider with the resource
            logger_provider = LoggerProvider(resource=resource)

            # Set as the global logger provider
            set_logger_provider(logger_provider)

            # Create the exporter and processor
            exporter = OTLPLogExporter(
                endpoint=f"http://{'localhost' if Config.env == 'development' else 'otel-collector'}:4317",
                insecure=True,
            )
            logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))

            # Create and add the OpenTelemetry handler
            otel_handler = LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
            self.logger.addHandler(otel_handler)

            self.logger.info(f"OpenTelemetry logging initialized for {Config.service_name}")
        except Exception as e:
            # Log to standard handlers if OTEL setup fails
            self.logger.error(f"Failed to initialize OpenTelemetry logging: {e!s}")

    def _initialize_file_storage_logging(self):
        """
        Initialize logging for file storage operations
        """
        try:
            # Create a separate logger for file storage operations
            file_storage_logger = logging.getLogger("file_storage")
            file_storage_logger.setLevel(Config.log_level)

            # Ensure handlers aren't duplicated
            if not file_storage_logger.handlers:
                # Add console handler
                handler = logging.StreamHandler()
                handler.setFormatter(self.logger.handlers[0].formatter)
                file_storage_logger.addHandler(handler)

                self.logger.debug("Initialized file storage logging")
        except Exception as e:
            self.logger.warning(f"Failed to initialize file storage logging: {e!s}")

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = LoggerService()
        return cls._instance

    def info(self, message):
        self.logger.info(message)

    def warning(self, message):
        self.logger.warning(message)

    def error(self, message):
        self.logger.error(message)

    def debug(self, message):
        self.logger.debug(message)

    def exception(self, message):
        self.logger.exception(message)


# Singleton instance
logger_service = LoggerService.get_instance()
