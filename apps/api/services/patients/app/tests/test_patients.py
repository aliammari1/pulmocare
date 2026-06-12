"""Smoke tests for the patients service.

These pin two important behaviours:
1. The service boots and serves health + OpenAPI.
2. Patient endpoints are auth-gated: no/invalid bearer token -> 401/403,
   never an unauthenticated data leak.
"""

import pytest

pytestmark = pytest.mark.asyncio


async def test_health(client):
    # The shared health router is mounted first and owns /health; with both
    # mocked backends reporting "UP" the overall status is "healthy".
    resp = await client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "healthy"
    assert body["service"] == "patients-service"
    assert body["dependencies"]["redis"] == "UP"


async def test_liveness_probe(client):
    resp = await client.get("/health/live")
    assert resp.status_code == 200
    assert resp.json()["status"] == "alive"


async def test_openapi_lists_patient_routes(client):
    resp = await client.get("/openapi.json")
    assert resp.status_code == 200
    paths = resp.json()["paths"]
    assert "/api/patients/{patient_id}" in paths
    assert "/api/patients/profile" in paths


async def test_get_patient_requires_auth(client):
    # No Authorization header -> HTTPBearer rejects with 403 (no credentials).
    resp = await client.get("/api/patients/some-id")
    assert resp.status_code in (401, 403)


async def test_profile_update_requires_auth(client):
    # Mutating endpoint must also be auth-gated.
    resp = await client.put("/api/patients/profile", json={"name": "x"})
    assert resp.status_code in (401, 403)
