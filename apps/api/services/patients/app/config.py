"""
Configuration for the Patients Service.

Extends the shared BaseConfig with patients-specific settings.
"""

from pydantic import Field

from pulmocare_shared.config import BaseConfig, load_env_file

# Load environment-specific .env file
load_env_file()


class PatientsConfig(BaseConfig):
    """Configuration for the Patients Service."""

    # Service info
    service_name: str = Field(default="patients-service")
    port: int = Field(default=8083)
    metrics_port: int = Field(default=9093)

    # PDF Export settings
    pdf_export_path: str = Field(default="/tmp/exports")

    # Rate limiting
    rate_limit_default: str = Field(default="100/minute")


# Singleton config instance
Config = PatientsConfig()
