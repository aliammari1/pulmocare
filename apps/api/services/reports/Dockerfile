# Reports Service Dockerfile
# Uses uv for fast Python package management
# Includes AI/ML dependencies (LangChain, Ollama, etc.)

FROM python:3.12-slim AS builder

# Install uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app/services/reports/app

# Install system dependencies for building
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy shared module first (for editable install - maintains relative path ../../shared)
COPY ./shared /app/services/shared

# Copy service pyproject.toml
COPY ./reports/app/pyproject.toml ./pyproject.toml

# Set UV configuration for builds
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Install dependencies only (cached layer)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-project

# Copy service application code
COPY ./reports/app .

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
    tesseract-ocr \
    tesseract-ocr-fra \
    tesseract-ocr-eng \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

# Copy the virtual environment from builder
COPY --from=builder /app/services/reports/app/.venv /app/.venv
COPY --from=builder /app/services/reports/app /app

# Set ownership
RUN chown -R appuser:appuser /app

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH" \
    PORT=8085 \
    METRICS_PORT=9095 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH="/app:$PYTHONPATH"

# Expose ports
EXPOSE 8085
EXPOSE 9095

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8085/health || exit 1

# Start the service
CMD ["python", "app.py"]