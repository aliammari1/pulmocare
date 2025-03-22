import consul
import logging
import socket
import os
import uuid
import json
import requests
from typing import Optional

logger = logging.getLogger(__name__)

class BaseConsulService:
    def __init__(self, service_name, service_port, tags=None):
        self.service_name = service_name
        self.service_port = service_port
        self.service_id = f"{service_name}-{uuid.uuid4()}"
        self.tags = tags or []
        if "api" not in self.tags:
            self.tags.append("api")
        
        self.consul = consul.Consul(
            host=os.getenv('CONSUL_HOST', 'localhost'),
            port=int(os.getenv('CONSUL_PORT', '8500'))
        )

    def register(self):
        """Register service with Consul"""
        try:
            ip_address = socket.gethostbyname(socket.gethostname())
            
            logger.info(f"Registering {self.service_name} with Consul at {ip_address}:{self.service_port}")
            
            # Register service with metadata for Kong
            self.consul.agent.service.register(
                name=self.service_name,
                service_id=self.service_id,
                address=ip_address,
                port=self.service_port,
                tags=self.tags,
                meta={
                    "version": os.getenv("SERVICE_VERSION", "1.0"),
                    "environment": os.getenv("ENVIRONMENT", "production"),
                    "kong-upstream": "true",
                    "kong-route-protocols": "http",
                },
                check={
                    "name": f"{self.service_name} health check",
                    "http": f"http://{ip_address}:{self.service_port}/health",
                    "interval": "10s",
                    "timeout": "5s",
                    "deregister_critical_service_after": "30s"
                }
            )

            # Register Kong upstream configuration
            self.register_kong_upstream(ip_address)
            
            logger.info(f"Successfully registered {self.service_name} with Consul")
            return True
        except Exception as e:
            logger.error(f"Failed to register {self.service_name} with Consul: {str(e)}")
            raise

    def register_kong_upstream(self, ip_address):
        """Register Kong upstream configuration in Consul KV store"""
        try:
            upstream_config = {
                "name": f"{self.service_name}-upstream",
                "targets": [
                    {
                        "target": f"{ip_address}:{self.service_port}",
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
                            "http_failures": 2,
                            "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]
                        },
                        "type": "http",
                        "http_path": "/health",
                        "timeout": 1
                    },
                    "passive": {
                        "healthy": {
                            "successes": 1
                        },
                        "unhealthy": {
                            "http_failures": 2
                        }
                    }
                }
            }
            
            self.consul.kv.put(
                f'kong/upstreams/{self.service_name}',
                json.dumps(upstream_config)
            )
            logger.info(f"Registered Kong upstream configuration for {self.service_name}")
        except Exception as e:
            logger.error(f"Failed to register Kong upstream for {self.service_name}: {str(e)}")
            raise

    def deregister(self):
        """Deregister service from Consul"""
        try:
            self.consul.agent.service.deregister(self.service_id)
            logger.info(f"Deregistered service {self.service_id} from Consul")
        except Exception as e:
            logger.error(f"Failed to deregister service: {str(e)}")
            raise