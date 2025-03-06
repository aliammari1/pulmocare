FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install  -r requirements.txt

# Copy application code
COPY . .

# Environment variables
ENV SERVER_PORT=8761
ENV CONSUL_HOST=consul
ENV CONSUL_PORT=8500

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${SERVER_PORT}/health || exit 1

# Expose port
EXPOSE ${SERVER_PORT}

# Start the service
CMD ["gunicorn", "--bind", "0.0.0.0:8761", "--workers", "4", "--threads", "2", "app:app"]