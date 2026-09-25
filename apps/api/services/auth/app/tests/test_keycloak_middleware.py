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


def test_unknown_signing_key_refreshes_jwks_once(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware()
    middleware._jwks = {"keys": [{"kid": "old"}]}
    fetch = Mock(side_effect=lambda: setattr(middleware, "_jwks", {"keys": [{"kid": "new"}]}))
    monkeypatch.setattr(middleware, "_fetch_jwks", fetch)
    from_jwk = Mock(return_value="trusted-key")
    monkeypatch.setattr("middleware.keycloak_auth.RSAAlgorithm.from_jwk", from_jwk)

    assert middleware.get_public_key("new") == "trusted-key"
    fetch.assert_called_once_with()


def test_untrusted_signing_key_fails_closed(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware()
    middleware._jwks = {"keys": [{"kid": "old"}]}
    monkeypatch.setattr(middleware, "_fetch_jwks", lambda: None)

    with pytest.raises(jwt.InvalidTokenError, match="not trusted"):
        middleware.get_public_key("attacker")


def test_introspection_requires_active_token(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware(client_id="api", client_secret="test-secret")
    response = Mock()
    response.json.return_value = {"active": False}
    post = Mock(return_value=response)
    monkeypatch.setattr("middleware.keycloak_auth.requests.post", post)

    with pytest.raises(jwt.InvalidTokenError, match="not active"):
        middleware.introspect_token("revoked.jwt")
    post.assert_called_once()
    assert post.call_args.kwargs["timeout"] == 10


@pytest.mark.asyncio
async def test_expired_token_is_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware()

    def expired(_token: str) -> None:
        raise jwt.ExpiredSignatureError()

    monkeypatch.setattr(middleware, "verify_token", expired)
    with pytest.raises(HTTPException) as exc:
        await middleware.get_current_user(credentials())
    assert exc.value.status_code == 401


@pytest.mark.asyncio
async def test_valid_role_is_retained(monkeypatch: pytest.MonkeyPatch) -> None:
    middleware = KeycloakMiddleware()
    monkeypatch.setattr(
        middleware,
        "verify_token",
        lambda _token: {"sub": "doctor-1", "realm_access": {"roles": ["doctor"]}},
    )

    user = await middleware.get_current_user(credentials(), required_roles=[Role.DOCTOR])
    assert user["user_id"] == "doctor-1"
