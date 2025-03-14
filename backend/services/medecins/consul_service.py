import consul
import logging
import socket
import os
import uuid

logger = logging.getLogger(__name__)

class ConsulService:
    def __init__(self, config):
        self.config = config
        self.service_id = f"{config.SERVICE_NAME}-{uuid.uuid4()}"
        self.consul = consul.Consul(
            host=config.CONSUL_HOST,
            port=config.CONSUL_PORT
        )

    def register_service(self):
        """Register service with Consul"""
        try:
            # Get container IP or fallback to hostname
            ip_address = socket.gethostbyname(socket.gethostname())

            logger.info(f"Registering service {self.config.SERVICE_NAME} with Consul at {ip_address}:8081")

            # Register service
            self.consul.agent.service.register(
                name=self.config.SERVICE_NAME,
                service_id=self.service_id,
                address=ip_address,
                port=8081,
                tags=["microservice", "medical"],
                check={
                    "name": f"Health check for {self.config.SERVICE_NAME}",
                    "http": f"http://{ip_address}:8081/health",
                    "interval": self.config.HEALTH_CHECK_INTERVAL,
                    "timeout": self.config.HEALTH_CHECK_TIMEOUT,
                    "deregister_critical_service_after": self.config.HEALTH_CHECK_DEREGISTER_TIMEOUT
                }
            )

            logger.info(f"Successfully registered {self.config.SERVICE_NAME} with Consul")
            return True
        except Exception as e:
            logger.error(f"Failed to register service with Consul: {str(e)}")
            raise

    def deregister_service(self):
        """Deregister service from Consul"""
        try:
            self.consul.agent.service.deregister(self.service_id)
            logger.info(f"Deregistered service {self.service_id} from Consul")
        except Exception as e:
            logger.error(f"Failed to deregister service: {str(e)}")
            raise