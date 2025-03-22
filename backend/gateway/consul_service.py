import consul
import logging
import socket
import os
import uuid
import sys
from base_consul_service import BaseConsulService

logger = logging.getLogger(__name__)

class ConsulService(BaseConsulService):
    """Gateway service Consul integration with Kong-specific enhancements"""
    
    def __init__(self, config):
        self.config = config
        self.service_id = f"gateway-service-{uuid.uuid4()}"
        self.consul = consul.Consul(
            host=os.getenv('CONSUL_HOST', 'localhost'),
            port=int(os.getenv('CONSUL_PORT', '8500'))
        )

    def register_service(self) -> bool:
        """Override to add Kong-specific metadata"""
        try:
            result = super().register_service()
            if result:
                # Add Kong-specific metadata
                self.consul.kv.put(
                    f'kong/services/{self.config.SERVICE_NAME}/routes',
                    'api-gateway'
                )
                self.consul.kv.put(
                    f'kong/services/{self.config.SERVICE_NAME}/plugins',
                    'jwt,rate-limiting,cors'
                )
            return result
        except Exception as e:
            self.logger.error(f"Failed to register Kong metadata: {str(e)}")
            return False

    def deregister_service(self):
        """Deregister service from Consul"""
        try:
            self.consul.agent.service.deregister(self.service_id)
            logger.info(f"Deregistered service {self.service_id} from Consul")
        except Exception as e:
            logger.error(f"Failed to deregister service: {str(e)}")
            raise