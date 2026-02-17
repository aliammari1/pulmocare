"""
CORS middleware configuration for FastAPI applications.
"""

from typing import TYPE_CHECKING

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


def setup_cors(
    app: FastAPI,
    config: "BaseConfig | None" = None,
    allow_origins: list[str] | None = None,
    allow_credentials: bool = True,
    allow_methods: list[str] | None = None,
    allow_headers: list[str] | None = None,
) -> None:
    """
    Configure CORS middleware for a FastAPI application.

    Args:
        app: FastAPI application instance
        config: Optional configuration (uses get_config() if not provided)
        allow_origins: List of allowed origins (overrides config)
        allow_credentials: Whether to allow credentials
        allow_methods: List of allowed HTTP methods
        allow_headers: List of allowed headers
    """
    if config is None:
        from pulmocare_shared.config import get_config
        config = get_config()

    origins = allow_origins or config.cors_origins
    methods = allow_methods or ["*"]
    headers = allow_headers or ["*"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=allow_credentials,
        allow_methods=methods,
        allow_headers=headers,
    )
