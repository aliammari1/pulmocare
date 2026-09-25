"""Pytest fixtures for the patients service smoke tests.

Redis / RabbitMQ / the auth service are all mocked, so these tests exercise the
FastAPI wiring and authorization gates without external infrastructure. Run:

    uv run pytest
"""

from __future__ import annotations

import importlib.util
import os
import sys
from pathlib import Path
from types import ModuleType
from unittest.mock import MagicMock

import pytest

# Keep OpenTelemetry from trying to reach a collector during tests.
os.environ.setdefault("OTEL_SDK_DISABLED", "true")
os.environ.setdefault("ENV", "test")

APP_DIR = Path(__file__).resolve().parents[1]
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))


def _load_app_module() -> ModuleType:
    """Load app.py by path (``app/`` is a package, shadowing ``import app``)."""
    spec = importlib.util.spec_from_file_location("patients_app_module", APP_DIR / "app.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _healthy_client() -> MagicMock:
    """A backend client mock whose health check reports a valid 'UP' string."""
    client = MagicMock()
    client.check_health.return_value = "UP"
    return client


@pytest.fixture
def _mock_backends(monkeypatch: pytest.MonkeyPatch) -> None:
    """Patch the shared Redis/RabbitMQ clients before app import."""
    monkeypatch.setattr("pulmocare_shared.RedisClient", lambda *a, **k: _healthy_client())
    monkeypatch.setattr("pulmocare_shared.RabbitMQClient", lambda *a, **k: _healthy_client())
    # patients_routes constructs its own RabbitMQ client at import time too.
    monkeypatch.setattr("services.rabbitmq_client.RabbitMQClient", lambda *a, **k: _healthy_client())


@pytest.fixture
async def client(_mock_backends):
    from asgi_lifespan import LifespanManager
    from httpx import ASGITransport, AsyncClient

    app_module = _load_app_module()
    async with LifespanManager(app_module.app):
        transport = ASGITransport(app=app_module.app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac
