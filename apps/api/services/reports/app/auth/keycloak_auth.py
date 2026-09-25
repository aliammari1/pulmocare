import os
from typing import Annotated

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

security = HTTPBearer()


class KeycloakAuth:
    """Authentication integration for the reports service."""

    def __init__(self) -> None:
        self.auth_service_url = os.getenv(
            "AUTH_SERVICE_URL",
            "http://auth-service:8086",
        ).rstrip("/")

    async def verify_token(self, token: str) -> dict:
        """Verify a bearer token with the auth service."""
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"{self.auth_service_url}/api/auth/token/verify",
                    json={"token": token},
                )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication service unavailable",
            ) from exc

        verification = response.json()
        if not verification.get("valid", False):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return verification

    async def get_current_user(
        self,
        credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    ) -> dict:
        return await self.verify_token(credentials.credentials)

    @staticmethod
    def _require_role(user_info: dict, allowed_roles: set[str]) -> dict:
        roles = set(user_info.get("roles", []))
        if roles.isdisjoint(allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return user_info

    async def get_current_report_writer(
        self,
        user_info: Annotated[dict, Depends(get_current_user)],
    ) -> dict:
        """Require a clinician/admin role for report mutations."""
        return self._require_role(
            user_info,
            {"doctor", "radiologist", "admin"},
        )


keycloak_auth = KeycloakAuth()

get_current_user = keycloak_auth.get_current_user
get_current_report_writer = keycloak_auth.get_current_report_writer
