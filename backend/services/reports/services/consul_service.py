import os
import socket
import logging
import consul
import requests
from config import Config

class ConsulService:
    """Service for Consul registration and discovery"""
    
    def __init__(self, config):
        self.config = config
        self.logger = logging.getLogger(__name__)
        
    def register_service(self):
        """Register service with Consul"""
        try:
            # Skip registration in development if we can't connect to Consul
            if self.config.ENV == 'development':
                try:
                    # Try with a short timeout in development
                    consul_client = consul.Consul(
                        host=self.config.CONSUL_HOST,
                        port=self.config.CONSUL_PORT,
                        scheme='http',
                        token=self.config.CONSUL_TOKEN,
                        verify=False,
                        timeout=3
                    )
                    # Test connection with a simple ping
                    consul_client.agent.self()
                except Exception as e:
                    self.logger.warning(f"Skipping Consul registration in development mode: {str(e)}")
                    return
            else:
                # Production settings with longer timeout
                consul_client = consul.Consul(
                    host=self.config.CONSUL_HOST,
                    port=self.config.CONSUL_PORT,
                    scheme='http',
                    token=self.config.CONSUL_TOKEN
                )
            
            # Get hostname or use container name
            hostname = os.getenv('HOSTNAME', socket.gethostname())
            service_id = f"{self.config.SERVICE_NAME}-{hostname}"
            
            # Use consistent service name
            service_name = self.config.SERVICE_NAME
            
            # Get the actual host address for registration
            try:
                # In Docker, use container IP for internal network
                container_ip = socket.gethostbyname(hostname)
                
                # For development on Windows, make sure we use the actual network interface
                if self.config.ENV == 'development' and container_ip == '127.0.0.1':
                    # Get the non-loopback IP address
                    container_ip = self._get_local_ip()
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
    
    def _get_local_ip(self):
        """Get a non-loopback IP address for the local machine"""
        try:
            # Create a socket that connects to an external server
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            # It doesn't actually connect, just sets up the socket
            s.connect(('8.8.8.8', 80))
            # Get the local IP address used for the connection
            local_ip = s.getsockname()[0]
            s.close()
            return local_ip
        except:
            return '127.0.0.1'
    
    def _register_metadata(self, service_name, container_ip, service_port):
        """Register additional metadata with registry service"""
        try:
            # Skip in development if registry errors should be ignored
            if self.config.ENV == 'development' and self.config.REGISTRY_IGNORE_ERRORS:
                registry_host = self.config.REGISTRY_HOST
                registry_port = self.config.REGISTRY_PORT
            else:
                registry_host = "registry"
                registry_port = 8761
                
            registry_url = f"http://{registry_host}:{registry_port}/services/metadata"
            
            # Shorter timeout in development
            timeout = 3 if self.config.ENV == 'development' else 10
            
            requests.post(
                registry_url,
                json={
                    'name': service_name,
                    'address': container_ip,
                    'port': service_port,
                    'team': 'Medical Team',
                    'documentation': f'https://github.com/aliammari/medapp/wiki/{service_name}'
                },
                timeout=timeout
            )
            self.logger.info(f"Registered metadata with registry service")
        except Exception as registry_error:
            if self.config.ENV == 'development' and self.config.REGISTRY_IGNORE_ERRORS:
                self.logger.warning(f"Failed to register metadata with registry: {str(registry_error)}")
            else:
                self.logger.error(f"Failed to register metadata with registry: {str(registry_error)}")
