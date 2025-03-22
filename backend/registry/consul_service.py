import consul
import logging
import socket
import os
import uuid
import json

logger = logging.getLogger(__name__)

class ConsulService:
    def __init__(self, config):
        self.config = config
        self.service_id = f"registry-service-{uuid.uuid4()}"
        self.consul = consul.Consul(
            host=os.getenv('CONSUL_HOST', 'localhost'),
            port=int(os.getenv('CONSUL_PORT', '8500'))
        )

    def register_service(self):
        """Register service with Consul"""
        try:
            # Get container IP or fallback to hostname
            ip_address = socket.gethostbyname(socket.gethostname())

            logger.info(f"Registering registry service with Consul at {ip_address}:8761")

            # Register service with metadata for Kong
            self.consul.agent.service.register(
                name="registry-service",
                service_id=self.service_id,
                address=ip_address,
                port=8761,
                tags=["registry", "medical", "api"],
                meta={
                    "version": "1.0",
                    "environment": os.getenv("ENVIRONMENT", "production"),
                    "kong-upstream": "true",
                    "kong-route-protocols": "http",
                },
                check={
                    "name": "Registry health check",
                    "http": f"http://{ip_address}:8761/health",
                    "interval": "10s",
                    "timeout": "5s",
                    "deregister_critical_service_after": "30s"
                }
            )

            # Register Kong upstream
            self.register_kong_upstream()

            logger.info("Successfully registered registry service with Consul")
            return True
        except Exception as e:
            logger.error(f"Failed to register service with Consul: {str(e)}")
            raise

    def register_kong_upstream(self):
        """Register Kong upstream configuration in Consul KV store"""
        try:
            upstream_config = {
                "name": "registry-service-upstream",
                "targets": [
                    {
                        "target": f"{socket.gethostname()}:8761",
                        "weight": 100
                    }
                ],
                "healthchecks": {
                    "active": {
                        "healthy": {
                            "interval": 5,
                            "successes": 1
                        },
                        "unhealthy": {
                            "interval": 5,
                            "http_failures": 2
                        }
                    }
                }
            }

            self.consul.kv.put(
                'kong/upstreams/registry-service',
                json.dumps(upstream_config)
            )
            logger.info("Registered Kong upstream configuration in Consul")
        except Exception as e:
            logger.error(f"Failed to register Kong upstream: {str(e)}")
            raise

    def deregister_service(self):
        """Deregister service from Consul"""
        try:
            self.consul.agent.service.deregister(self.service_id)
            logger.info(f"Deregistered service {self.service_id} from Consul")
        except Exception as e:
            logger.error(f"Failed to deregister service: {str(e)}")
            raise