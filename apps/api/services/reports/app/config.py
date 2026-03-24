"""
Configuration module for Reports Service.

Extends the shared BaseConfig with service-specific settings.
Includes AI/ML and document processing configuration.
"""

from functools import lru_cache

from pydantic import Field
from pulmocare_shared import BaseConfig


class ReportsConfig(BaseConfig):
    """Configuration for the Reports microservice with AI/ML capabilities."""

    service_name: str = Field(default="reports-service", description="Service name")
    port: int = Field(default=8085, description="Service port")
    mongodb_database: str = Field(default="reports", description="MongoDB database name")

    # Ignore errors in development (graceful degradation)
    registry_ignore_errors: bool = Field(default=True, description="Ignore consul registry errors in dev")
    rabbitmq_ignore_connection_errors: bool = Field(default=True, description="Ignore RabbitMQ errors in dev")

    # AI/ML settings - Ollama
    ollama_host: str = Field(default="http://ollama:11434", description="Ollama API host")
    ollama_model: str = Field(default="llama3", description="Default Ollama model")
    ollama_timeout: int = Field(default=120, description="Ollama request timeout in seconds")
    
    # LangChain settings
    langchain_verbose: bool = Field(default=False, description="Enable LangChain verbose mode")
    langchain_cache: bool = Field(default=True, description="Enable LangChain caching")
    
    # Document processing settings
    pdf_export_path: str = Field(default="/tmp/exports", description="PDF export path")
    ocr_language: str = Field(default="fra+eng", description="Tesseract OCR languages")
    max_document_size: int = Field(default=50 * 1024 * 1024, description="Max document size (50MB)")
    
    # NLTK settings
    nltk_data_path: str = Field(default="/app/nltk_data", description="NLTK data path")
    
    # Service integration
    patients_service_url: str = Field(default="http://patients-service:8083", description="Patients service URL")
    medecins_service_url: str = Field(default="http://medecins-service:8081", description="Medecins service URL")
    
    # Rate limiting
    rate_limit_default: str = Field(default="50/minute", description="Default rate limit")


@lru_cache
def get_config() -> ReportsConfig:
    """Get cached configuration instance."""
    return ReportsConfig()


# Backwards compatibility - create Config as alias
Config = get_config()
