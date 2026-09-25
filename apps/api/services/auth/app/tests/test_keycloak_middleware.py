"""Security contract for local JWT validation and role enforcement."""

from unittest.mock import Mock

import jwt
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from middleware.keycloak_auth import KeycloakMiddleware
from models.auth import Role


def credentials() -> HTTPAuthorizationCredentials:
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials="example.jwt")


@pytest.mark.asyncio
async def test_missing_or_wrong_role_is_forbidden(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware()
    for roles in ([], ["patient"]):
        monkeypatch.setattr(middleware, "verify_token", lambda _token, roles=roles: {"realm_access": {"roles": roles}})
        with pytest.raises(HTTPException) as exc:
            await middleware.get_current_user(credentials(), required_roles=[Role.DOCTOR])
        assert exc.value.status_code == 403


@pytest.mark.asyncio
async def test_invalid_jwt_does_not_expose_verifier_detail(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware()

    def reject(_token: str) -> None:
        raise jwt.InvalidTokenError("internal signing key details")

    monkeypatch.setattr(middleware, "verify_token", reject)
    with pytest.raises(HTTPException) as exc:
        await middleware.get_current_user(credentials())
    assert exc.value.status_code == 401
    assert "internal signing key details" not in exc.value.detail


def test_configured_audience_is_verified(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("KEYCLOAK_AUDIENCE", "pulmocare-api")
    middleware = KeycloakMiddleware()
    monkeypatch.setattr(middleware, "get_public_key", lambda _kid: "public-key")
    monkeypatch.setattr(jwt, "get_unverified_header", lambda _token: {"kid": "key-1"})
    decode = Mock(return_value={"sub": "user-1"})
    monkeypatch.setattr(jwt, "decode", decode)

    assert middleware.verify_token("example.jwt") == {"sub": "user-1"}
    assert decode.call_args.kwargs["audience"] == "pulmocare-api"
    assert decode.call_args.kwargs["options"]["verify_aud"] is True
