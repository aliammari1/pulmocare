"""
Configuration for the Auth Service.

Extends the shared BaseConfig with auth-specific settings.
"""

from pydantic import Field

from pulmocare_shared.config import BaseConfig, load_env_file

# Load environment-specific .env file
load_env_file()


class AuthConfig(BaseConfig):
    """Configuration for the MedApp Authentication Service."""

    # Service info
    service_name: str = Field(default="auth-service")
    port: int = Field(default=8086)
    metrics_port: int = Field(default=9096)

    # Keycloak settings
    keycloak_url: str = Field(default="http://localhost:8090")
    keycloak_realm: str = Field(default="pulmocare")
    keycloak_client_id: str = Field(default="pulmocare-api")
    keycloak_client_secret: str = Field(default="pulmocare-secret")
    keycloak_admin_username: str = Field(default="admin")
    keycloak_admin_password: str = Field(default="admin")

    # Default redirect URL after login
    default_redirect_url: str = Field(default="http://localhost:3000")


# Singleton config instance
Config = AuthConfig()
