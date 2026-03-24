"""
Configuration module for Appointments Service.

Extends the shared BaseConfig with service-specific settings.
"""

from functools import lru_cache

from pydantic import Field
from pulmocare_shared import BaseConfig


class AppointmentsConfig(BaseConfig):
    """Configuration for the Appointments microservice."""

    service_name: str = Field(default="appointments-service", description="Service name")
    port: int = Field(default=8087, description="Service port")
    mongodb_database: str = Field(default="appointments", description="MongoDB database name")

    # Auth service integration
    auth_service_client_id: str = Field(default="pulmocare-api", description="Auth service client ID")
    auth_service_client_secret: str = Field(default="pulmocare-secret", description="Auth service client secret")
    auth_service_realm: str = Field(default="pulmocare", description="Auth service realm")

    # Service integration settings
    medecins_service_host: str = Field(default="medecins-service", description="Medecins service host")
    medecins_service_port: int = Field(default=8081, description="Medecins service port")
    patients_service_host: str = Field(default="patients-service", description="Patients service host")
    patients_service_port: int = Field(default=8083, description="Patients service port")

    # Appointment-specific settings
    appointment_slot_duration: int = Field(default=30, description="Appointment slot duration in minutes")
    max_appointments_per_day: int = Field(default=20, description="Max appointments per doctor per day")
    advance_booking_days: int = Field(default=30, description="How many days in advance appointments can be booked")
    
    # Notification settings
    reminder_hours_before: int = Field(default=24, description="Hours before appointment to send reminder")
    
    # Rate limiting
    rate_limit_default: str = Field(default="100/minute", description="Default rate limit")

    @property
    def medecins_service_url(self) -> str:
        """Get medecins service URL."""
        return f"http://{self.medecins_service_host}:{self.medecins_service_port}"

    @property
    def patients_service_url(self) -> str:
        """Get patients service URL."""
        return f"http://{self.patients_service_host}:{self.patients_service_port}"


@lru_cache
def get_config() -> AppointmentsConfig:
    """Get cached configuration instance."""
    return AppointmentsConfig()


# Backwards compatibility - create Config as alias
Config = get_config()
