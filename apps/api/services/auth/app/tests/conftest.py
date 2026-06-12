"""Pytest fixtures for the auth service smoke tests.

These tests run with no Keycloak/Redis/RabbitMQ available: external
collaborators are mocked, so they exercise the FastAPI wiring, request/response
models, and error handling -- not the real Keycloak backend. Run with:

    uv run pytest
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType
from unittest.mock import MagicMock

import pytest

# The service stores its application package under app/ with flat imports
# (``from routes... import``), so the app directory must be importable.
APP_DIR = Path(__file__).resolve().parents[1]
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))


def _load_app_module() -> ModuleType:
    """Load app.py by file path.

    ``app/`` is itself a package, so a plain ``import app`` resolves to the
    (empty) package rather than the ``app.py`` ASGI module. Load it explicitly.
    """
    spec = importlib.util.spec_from_file_location("auth_app_module", APP_DIR / "app.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def mock_keycloak(monkeypatch: pytest.MonkeyPatch) -> MagicMock:
    """Patch KeycloakService so no real Keycloak server is contacted.

    Patches the class *before* app import so the module-level singletons in
    ``app.py`` and ``routes.auth_routes`` pick up the mock.
    """
    instance = MagicMock()
    fake_cls = MagicMock(return_value=instance)
    monkeypatch.setattr("services.keycloak_service.KeycloakService", fake_cls)
    return instance


@pytest.fixture
async def client(mock_keycloak: MagicMock):
    """Async HTTP client bound to the auth ASGI app with lifespan managed."""
    from asgi_lifespan import LifespanManager
    from httpx import ASGITransport, AsyncClient

    # Replace the module-level keycloak_service used by route handlers with the
    # mock before loading the app (which wires the routers).
    from routes import auth_routes

    auth_routes.keycloak_service = mock_keycloak

    app_module = _load_app_module()
    async with LifespanManager(app_module.app):
        transport = ASGITransport(app=app_module.app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac, mock_keycloak
