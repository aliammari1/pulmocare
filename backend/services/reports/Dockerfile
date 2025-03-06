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
ENV PORT=8083
ENV CONSUL_HOST=medapp-consul
ENV CONSUL_PORT=8500
ENV MONGODB_HOST=mongodb
ENV MONGODB_PORT=27017
ENV MONGODB_DATABASE=medapp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE ${PORT}

# Start the service
CMD ["gunicorn", "--bind", "0.0.0.0:8083", "--workers", "4", "--threads", "2", "--timeout", "120", "app:app"]