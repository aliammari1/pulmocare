import json
import logging
import os
from typing import Any

import jwt
import requests
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.algorithms import RSAAlgorithm

from models.auth import Role

# Security scheme for Swagger UI
security = HTTPBearer()
logger = logging.getLogger(__name__)


class KeycloakMiddleware:
    """
    Middleware to handle Keycloak authentication for FastAPI applications.
    This provides token validation and role-based access control.
    """

    def __init__(self, keycloak_url=None, realm=None, client_id=None, client_secret=None):
        """
        Initialize the Keycloak middleware.

        Args:
            keycloak_url: Base URL of the Keycloak server
            realm: Keycloak realm name
            client_id: Client ID for the application
            client_secret: Client secret for the application
        """
        self.keycloak_url = keycloak_url or os.getenv("KEYCLOAK_URL", "http://keycloak:8080")

        # Strip trailing '/auth' if present as newer Keycloak versions don't use this path
        if self.keycloak_url.endswith("/auth"):
            print("Detected '/auth' suffix in Keycloak URL, removing it for compatibility with newer versions")
            self.keycloak_url = self.keycloak_url.removesuffix("/auth")

        self.realm = realm or os.getenv("KEYCLOAK_REALM", "pulmocare")
        self.client_id = client_id or os.getenv("KEYCLOAK_CLIENT_ID", "pulmocare-api")
        self.client_secret = client_secret or os.getenv("KEYCLOAK_CLIENT_SECRET", "pulmocare-secret")
        self.audience = os.getenv("KEYCLOAK_AUDIENCE") or None

        # Cache for public key to avoid repeated requests
        self._public_key = None
        self._jwks: dict[str, Any] | None = None

        # Well-known endpoints
        self.well_known_url = f"{self.keycloak_url}/realms/{self.realm}/.well-known/openid-configuration"
        self.token_introspection_url = (
            f"{self.keycloak_url}/realms/{self.realm}/protocol/openid-connect/token/introspect"
        )

        logger.info("Keycloak middleware initialized for realm %s", self.realm)

    def _fetch_jwks(self):
        response = requests.get(self.well_known_url, timeout=10)
        response.raise_for_status()
        jwks_uri = response.json().get("jwks_uri")
        if not jwks_uri:
            raise jwt.InvalidTokenError("Keycloak discovery document has no jwks_uri")

        response = requests.get(jwks_uri, timeout=10)
        response.raise_for_status()
        self._jwks = response.json()

    def get_public_key(self, kid=None):
        """Resolve the signing key and refresh JWKS once on key rotation."""
        if not self._jwks:
            self._fetch_jwks()

        jwks = self._jwks or {}
        keys = jwks.get("keys", [])
        if kid:
            for key in keys:
                if key.get("kid") == kid:
                    return RSAAlgorithm.from_jwk(json.dumps(key))

            # Keycloak may have rotated keys since the cache was populated.
            self._fetch_jwks()
            refreshed_jwks = self._jwks or {}
            for key in refreshed_jwks.get("keys", []):
                if key.get("kid") == kid:
                    return RSAAlgorithm.from_jwk(json.dumps(key))
            raise jwt.InvalidTokenError("Token signing key is not trusted")

        if len(keys) == 1:
            return RSAAlgorithm.from_jwk(json.dumps(keys[0]))

        raise jwt.InvalidTokenError("Token header does not identify a signing key")

    def verify_token(self, token):
        """
        Verify a JWT token using the public key.

        Args:
            token: JWT token to verify

        Returns:
            Decoded token payload if valid

        Raises:
            jwt.InvalidTokenError: If token is invalid
        """
        try:
            # Get the unverified headers to extract the kid
            headers = jwt.get_unverified_header(token)
            kid = headers.get("kid")

            # Get the public key
            public_key = self.get_public_key(kid)

            # Verify the token
            payload = jwt.decode(
                token,
                public_key,
                algorithms=["RS256"],
                issuer=f"{self.keycloak_url}/realms/{self.realm}",
                audience=self.audience,
                options={
                    "verify_signature": True,
                    "verify_exp": True,
                    "verify_nbf": True,
                    "verify_iat": True,
                    "verify_aud": self.audience is not None,
                    "verify_iss": True,
                    "require": ["exp", "iat"],
                },
            )

            return payload
        except jwt.InvalidTokenError:
            raise

    def introspect_token(self, token):
        """
        Introspect a token with Keycloak server for detailed validation.

        Args:
            token: Token to introspect

        Returns:
            Token information if valid
        """
        try:
            response = requests.post(
                self.token_introspection_url,
                data={
                    "token": token,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=10,
            )
            response.raise_for_status()
            result = response.json()

            if not result.get("active", False):
                raise jwt.InvalidTokenError("Token is not active")

            return result
        except (requests.RequestException, jwt.InvalidTokenError):
            raise

    async def get_current_user(
        self,
        credentials: HTTPAuthorizationCredentials = Depends(security),
        required_roles: list[Role] | None = None,
    ) -> dict[str, Any]:
        """
        FastAPI dependency to get the current authenticated user.

        Args:
            credentials: HTTP Bearer token credentials
            required_roles: List of roles required to access the endpoint

        Returns:
            User information from the token

        Raises:
            HTTPException: If authentication or authorization fails
        """
        if not credentials:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization header missing",
                headers={"WWW-Authenticate": "Bearer"},
            )

        try:
            token = credentials.credentials

            # Normal token verification path
            payload = self.verify_token(token)

            # Check for required roles if specified
            if required_roles:
                user_roles = payload.get("realm_access", {}).get("roles", [])
                if not any(role in user_roles for role in required_roles):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Insufficient permissions",
                    )

            # Add user ID to the payload (for convenience)
            payload["user_id"] = payload.get("sub")
            return payload

        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except HTTPException:
            raise
        except (requests.RequestException, ValueError, TypeError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication failed",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # Role-based dependencies
    async def get_admin_user(self, user=Depends(get_current_user)):
        """
        Dependency to require admin role.
        """
        return await self.get_current_user(required_roles=[Role.ADMIN])

    async def get_doctor_user(self, user=Depends(get_current_user)):
        """
        Dependency to require doctor role.
        """
        return await self.get_current_user(required_roles=[Role.DOCTOR])

    async def get_patient_user(self, user=Depends(get_current_user)):
        """
        Dependency to require patient role.
        """
        return await self.get_current_user(required_roles=[Role.PATIENT])

    async def get_radiologist_user(self, user=Depends(get_current_user)):
        """
        Dependency to require radiologist role.
        """
        return await self.get_current_user(required_roles=[Role.RADIOLOGIST])


# Create a global instance that can be imported directly
keycloak_middleware = KeycloakMiddleware()

# Export dependencies for convenience
get_current_user = keycloak_middleware.get_current_user
get_admin_user = keycloak_middleware.get_admin_user
get_doctor_user = keycloak_middleware.get_doctor_user
get_patient_user = keycloak_middleware.get_patient_user
get_radiologist_user = keycloak_middleware.get_radiologist_user
