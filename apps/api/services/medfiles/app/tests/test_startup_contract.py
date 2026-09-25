"""The files service must start with the current shared config API."""

from unittest.mock import Mock

from app import app
from services import minio_service


def test_minio_uses_boolean_secure_setting(monkeypatch):
    fake_minio = Mock()
    monkeypatch.setattr(minio_service, "Minio", fake_minio)
    client = minio_service.MinioService()
    try:
        assert fake_minio.call_args.kwargs["secure"] is False
    finally:
        client.executor.shutdown(wait=False)


def test_openapi_schema_includes_file_upload():
    schema = app.openapi()
    assert "/api/files/upload" in schema["paths"]
