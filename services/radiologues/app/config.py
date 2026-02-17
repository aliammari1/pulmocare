"""
Configuration module for Radiologues Service.

Extends the shared BaseConfig with service-specific settings.
"""

from functools import lru_cache

from pydantic import Field
from pulmocare_shared import BaseConfig


class RadiologuesConfig(BaseConfig):
    """Configuration for the Radiologues microservice."""

    service_name: str = Field(default="radiologues-service", description="Service name")
    port: int = Field(default=8084, description="Service port")

    # Auth service integration
    auth_service_client_id: str = Field(default="radiologues-service", description="Auth service client ID")
    auth_service_client_secret: str = Field(default="secret", description="Auth service client secret")
    auth_service_realm: str = Field(default="pulmocare", description="Auth service realm")

    # Service communication settings
    reports_service_url: str = Field(default="http://reports-service:8085", description="Reports service URL")
    patients_service_url: str = Field(default="http://patients-service:8083", description="Patients service URL")
    medecins_service_url: str = Field(default="http://medecins-service:8081", description="Medecins service URL")

    # Application specific configuration
    pdf_export_path: str = Field(default="/tmp/exports", description="PDF export path")
    max_content_length: int = Field(default=16 * 1024 * 1024, description="Max content length (16MB)")
    request_timeout: int = Field(default=30, description="Request timeout in seconds")

    # Rate limiting
    rate_limit_default: str = Field(default="100/minute", description="Default rate limit")


@lru_cache
def get_config() -> RadiologuesConfig:
    """Get cached configuration instance."""
    return RadiologuesConfig()


# Backwards compatibility - create Config as alias
Config = get_config()
