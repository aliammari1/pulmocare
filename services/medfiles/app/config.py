"""
Configuration module for MedFiles Service.

Extends the shared BaseConfig with service-specific settings.
Handles medical file storage with MinIO integration.
"""

from functools import lru_cache

from pydantic import Field
from pulmocare_shared import BaseConfig


class MedFilesConfig(BaseConfig):
    """Configuration for the MedFiles microservice."""

    service_name: str = Field(default="medfiles-service", description="Service name")
    port: int = Field(default=8088, description="Service port")

    # MinIO settings
    minio_host: str = Field(default="minio", description="MinIO host")
    minio_port: int = Field(default=9000, description="MinIO port")
    minio_access_key: str = Field(default="minioadmin", description="MinIO access key")
    minio_secret_key: str = Field(default="minioadmin", description="MinIO secret key")
    minio_region: str = Field(default="us-east-1", description="MinIO region")
    minio_secure: bool = Field(default=False, description="Use HTTPS for MinIO")
    
    # Storage bucket configuration
    minio_bucket_dicom: str = Field(default="dicom-files", description="DICOM files bucket")
    minio_bucket_documents: str = Field(default="medical-documents", description="Medical documents bucket")
    minio_bucket_images: str = Field(default="medical-images", description="Medical images bucket")

    # File handling settings
    max_upload_size: int = Field(default=100 * 1024 * 1024, description="Max upload size (100MB)")
    allowed_extensions: list[str] = Field(
        default=["dcm", "dicom", "pdf", "jpg", "jpeg", "png", "doc", "docx"],
        description="Allowed file extensions"
    )
    
    # DICOM processing settings
    dicom_anonymize: bool = Field(default=False, description="Anonymize DICOM files on upload")
    dicom_thumbnail_size: tuple = Field(default=(256, 256), description="DICOM thumbnail size")
    
    # Temporary storage
    temp_dir: str = Field(default="/tmp/medfiles", description="Temporary file directory")

    @property
    def minio_endpoint(self) -> str:
        """Get MinIO endpoint URL."""
        return f"{self.minio_host}:{self.minio_port}"


@lru_cache
def get_config() -> MedFilesConfig:
    """Get cached configuration instance."""
    return MedFilesConfig()


# Backwards compatibility - create Config as alias
Config = get_config()
