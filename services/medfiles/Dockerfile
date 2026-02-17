# MedFiles Service Dockerfile
# Uses uv for fast Python package management
# Handles medical file uploads with MinIO

FROM python:3.12-slim AS builder

# Install uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app/services/medfiles/app

# Install system dependencies for building
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy shared module first (for editable install - maintains relative path ../../shared)
COPY ./shared /app/services/shared

# Copy service pyproject.toml
COPY ./medfiles/app/pyproject.toml ./pyproject.toml

# Set UV configuration for builds
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Install dependencies only (cached layer)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-project

# Copy service application code
COPY ./medfiles/app .

# Install the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync

# Production stage
FROM python:3.12-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

# Copy the virtual environment from builder
COPY --from=builder /app/services/medfiles/app/.venv /app/.venv
COPY --from=builder /app/services/medfiles/app /app

# Set ownership
RUN chown -R appuser:appuser /app

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PORT=8088 \
    METRICS_PORT=9088 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH="/app:$PYTHONPATH"

# Expose ports
EXPOSE 8088
EXPOSE 9088

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8088/health || exit 1

# Start the service
CMD ["python", "app.py"]
