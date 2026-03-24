# PulmoCare Shared Module

Common utilities and shared services for PulmoCare microservices.

## Installation

### As a local editable dependency (recommended for development)

```bash
# From the service directory
uv add --editable ../shared
```

### In pyproject.toml

```toml
[project]
dependencies = [
    "pulmocare-shared @ file:///${PROJECT_ROOT}/../shared",
]
```

## Features

### Configuration

Centralized configuration using Pydantic Settings:

```python
from pulmocare_shared import BaseConfig

class ServiceConfig(BaseConfig):
    """Service-specific configuration."""
    service_name: str = "my-service"
    custom_setting: str = "default"
```

### Logging

Structured logging with OpenTelemetry integration:

```python
from pulmocare_shared import get_logger, init_logger

# Initialize with config
logger = init_logger(config)

# Use the logger
logger.info("Processing request", request_id="123")
logger.error("Something went wrong", error=str(e))
```

### Telemetry (OpenTelemetry)

Distributed tracing and metrics:

```python
from pulmocare_shared import setup_telemetry

# Setup telemetry for your FastAPI app
telemetry = setup_telemetry(config, app)

# Create custom spans
with telemetry.create_span("custom-operation"):
    # Your code here
    pass
```

### Clients

#### Redis Client

```python
from pulmocare_shared import RedisClient

redis = RedisClient(config)
redis.set("key", "value", ttl=300)
value = redis.get("key")
redis.set_json("data", {"foo": "bar"})
```

#### RabbitMQ Client

```python
from pulmocare_shared import RabbitMQClient

rabbitmq = RabbitMQClient(config)
rabbitmq.publish_event("patient.created", {"patient_id": "123"})
```

#### MongoDB Client

```python
from pulmocare_shared import MongoDBClient

mongodb = MongoDBClient(config)
mongodb.insert_one("patients", {"name": "John Doe"})
patients = mongodb.find_many("patients", {"active": True})
```

#### Consul Client

```python
from pulmocare_shared import ConsulClient

consul = ConsulClient(config)
consul.register_service(check_http=f"http://localhost:{config.port}/health")
```

### Middleware

#### CORS

```python
from pulmocare_shared import setup_cors

setup_cors(app, config)
```

#### Health Checks

```python
from pulmocare_shared.middleware import create_health_router

health_router = create_health_router(
    config=config,
    redis_client=redis,
    mongodb_client=mongodb,
)
app.include_router(health_router)
```

### Metrics

```python
from pulmocare_shared import setup_metrics
from pulmocare_shared.metrics import create_metrics_router

metrics = setup_metrics(config)
app.include_router(create_metrics_router())

# Track custom metrics
metrics.track_cache("patients", hit=True)
metrics.track_db_operation("find", "patients", duration=0.05)
```

## Development

```bash
# Install dependencies
uv sync

# Run linter
uv run ruff check .

# Run formatter
uv run ruff format .

# Run tests
uv run pytest
```

## Project Structure

```
shared/
├── pyproject.toml          # Package configuration
├── README.md               # This file
└── src/
    └── pulmocare_shared/
        ├── __init__.py     # Package exports
        ├── config.py       # Configuration module
        ├── logging.py      # Logging service
        ├── telemetry.py    # OpenTelemetry service
        ├── metrics.py      # Prometheus metrics
        ├── clients/
        │   ├── __init__.py
        │   ├── redis_client.py
        │   ├── rabbitmq_client.py
        │   ├── mongodb_client.py
        │   └── consul_client.py
        └── middleware/
            ├── __init__.py
            ├── cors.py
            └── health.py
```
