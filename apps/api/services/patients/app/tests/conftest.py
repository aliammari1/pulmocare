"""Pytest fixtures for the patients service tests.

Redis / RabbitMQ / the auth service are mocked so tests exercise FastAPI wiring,
authorization and route behavior without external infrastructure.
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
    """Load app.py by path (the app/ directory can shadow normal imports)."""
    spec = importlib.util.spec_from_file_location("patients_app_module", APP_DIR / "app.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _healthy_client() -> MagicMock:
    """Return a backend client mock whose health check reports UP."""
    client = MagicMock()
    client.check_health.return_value = "UP"
    return client


@pytest.fixture
def _mock_backends(monkeypatch: pytest.MonkeyPatch) -> None:
    """Patch Redis/RabbitMQ clients before the FastAPI app is imported."""
    monkeypatch.setattr("pulmocare_shared.RedisClient", lambda *a, **k: _healthy_client())
    monkeypatch.setattr("pulmocare_shared.RabbitMQClient", lambda *a, **k: _healthy_client())
    monkeypatch.setattr("services.rabbitmq_client.RabbitMQClient", lambda *a, **k: _healthy_client())


@pytest.fixture
def app(_mock_backends):
    """Return a fresh patients FastAPI app for each test."""
    return _load_app_module().app


@pytest.fixture
async def client(app):
    from asgi_lifespan import LifespanManager
    from httpx import ASGITransport, AsyncClient

    async with LifespanManager(app):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac
