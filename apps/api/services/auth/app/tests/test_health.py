"""Smoke tests for the auth service health endpoint."""

import pytest

pytestmark = pytest.mark.asyncio


async def test_health_returns_healthy(client):
    ac, _ = client
    resp = await ac.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "healthy"
    assert body["service"] == "auth-service"


async def test_openapi_schema_is_served(client):
    ac, _ = client
    resp = await ac.get("/openapi.json")
    assert resp.status_code == 200
    schema = resp.json()
    # Core auth routes should be registered.
    assert "/api/auth/login" in schema["paths"]
    assert "/api/auth/register" in schema["paths"]
