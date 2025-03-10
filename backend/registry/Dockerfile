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

# Expose port
EXPOSE ${SERVER_PORT}

# Start the service
CMD ["python", "app.py"]