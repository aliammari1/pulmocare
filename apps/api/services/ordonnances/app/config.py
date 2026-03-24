"""
Configuration module for Ordonnances Service.

Extends the shared BaseConfig with service-specific settings.
"""

from functools import lru_cache

from pydantic import Field
from pulmocare_shared import BaseConfig


class OrdonnancesConfig(BaseConfig):
    """Configuration for the Ordonnances microservice."""

    service_name: str = Field(default="ordonnances-service", description="Service name")
    port: int = Field(default=8082, description="Service port")
    mongodb_database: str = Field(default="ordonnances", description="MongoDB database name")

    # PDF generation settings
    pdf_export_path: str = Field(default="/tmp/exports", description="PDF export path")
    pdf_logo_path: str = Field(default="/app/static/logo.png", description="PDF logo path")
    
    # Prescription-specific settings
    prescription_validity_days: int = Field(default=30, description="Prescription validity in days")
    max_medications_per_prescription: int = Field(default=20, description="Max medications per prescription")
    
    # Rate limiting
    rate_limit_default: str = Field(default="100/minute", description="Default rate limit")


@lru_cache
def get_config() -> OrdonnancesConfig:
    """Get cached configuration instance."""
    return OrdonnancesConfig()


# Backwards compatibility - create Config as alias
Config = get_config()
