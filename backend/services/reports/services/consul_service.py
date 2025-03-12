import os
import socket
import logging
import consul
import requests

class ConsulService:
    """Service for Consul registration and discovery"""
    
    def __init__(self, config):
        self.config = config
        self.logger = logging.getLogger(__name__)
        
    def register_service(self):
        """Register service with Consul"""
        try:
            consul_client = consul.Consul(
                host=self.config.CONSUL_HOST,
                port=self.config.CONSUL_PORT
            )
            
            # Get hostname or use container name
            hostname = os.getenv('HOSTNAME', socket.gethostname())
            service_id = f"{self.config.SERVICE_NAME}-{hostname}"
            
            # Use consistent service name
            service_name = self.config.SERVICE_NAME
            
            # Get the actual host address for registration
            try:
                container_ip = socket.gethostbyname(hostname)
            except:
                container_ip = '127.0.0.1'  # fallback
            
            # Ensure port is correct
            service_port = self.config.PORT
            
            # Register with better health check config and metadata
            consul_client.agent.service.register(
                name=service_name,
                service_id=service_id,
                address=container_ip,
                port=service_port,
                check={
                    'name': f'{service_name} health check',
                    'http': f'http://{container_ip}:{service_port}/health',
                    'interval': self.config.HEALTH_CHECK_INTERVAL,
                    'timeout': self.config.HEALTH_CHECK_TIMEOUT,
                    'deregister_critical_service_after': self.config.HEALTH_CHECK_DEREGISTER_TIMEOUT
                },
                tags=[service_name.split('-')[0], 'medical', 'api']
            )
            self.logger.info(f"Registered service with Consul: {service_id} at {container_ip}:{service_port}")
            
            # Register service metadata in registry service
            self._register_metadata(service_name, container_ip, service_port)
                
        except Exception as e:
            self.logger.error(f"Failed to register with Consul: {str(e)}")
    
    def _register_metadata(self, service_name, container_ip, service_port):
        """Register additional metadata with registry service"""
        try:
            registry_url = "http://registry:8761/services/metadata"
            requests.post(
                registry_url,
                json={
                    'name': service_name,
                    'address': container_ip,
                    'port': service_port,
                    'team': 'Medical Team',
                    'documentation': f'https://github.com/aliammari/medapp/wiki/{service_name}'
                },
                timeout=5
            )
            self.logger.info(f"Registered metadata with registry service")
        except Exception as registry_error:
            self.logger.warning(f"Failed to register metadata with registry: {str(registry_error)}")
