"""Smoke tests for the auth service login/token routes.

External Keycloak calls are mocked; these tests pin the HTTP contract and the
error-handling behaviour (e.g. wrong credentials must yield 401, never 200).
"""

import pytest

pytestmark = pytest.mark.asyncio


async def test_login_success_returns_tokens(client):
    ac, keycloak = client
    keycloak.login.return_value = {
        "access_token": "a.b.c",
        "refresh_token": "d.e.f",
        "expires_in": 3600,
        "user_id": "user-123",
        "email": "doc@example.com",
        "name": "Dr Example",
    }

    resp = await ac.post(
        "/api/auth/login",
        json={"email": "doc@example.com", "password": "correct-horse"},
    )

    assert resp.status_code == 200
    body = resp.json()
    assert body["access_token"] == "a.b.c"
    assert body["user_id"] == "user-123"
    keycloak.login.assert_called_once_with("doc@example.com", "correct-horse")


async def test_login_wrong_password_returns_401(client):
    ac, keycloak = client
    keycloak.login.side_effect = Exception("invalid_grant: Invalid user credentials")

    resp = await ac.post(
        "/api/auth/login",
        json={"email": "doc@example.com", "password": "wrong"},
    )

    # Security pin: bad credentials must NOT be accepted.
    assert resp.status_code == 401
    assert "incorrect" in resp.json()["detail"].lower()


async def test_login_rejects_malformed_email(client):
    ac, _ = client
    resp = await ac.post(
        "/api/auth/login",
        json={"email": "not-an-email", "password": "whatever"},
    )
    # Pydantic EmailStr validation -> 422 before any Keycloak call.
    assert resp.status_code == 422


async def test_token_verify_invalid_returns_invalid_flag(client):
    ac, keycloak = client
    keycloak.verify_token.side_effect = Exception("signature verification failed")

    resp = await ac.post("/api/auth/token/verify", json={"token": "garbage.token.value"})

    assert resp.status_code == 200
    body = resp.json()
    assert body["valid"] is False
    assert "error" in body


async def test_refresh_token_failure_returns_401(client):
    ac, keycloak = client
    keycloak.refresh_token.side_effect = Exception("expired refresh token")

    resp = await ac.post("/api/auth/token/refresh", json={"refresh_token": "stale"})

    assert resp.status_code == 401
