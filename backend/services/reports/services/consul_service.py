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
                        token=self.config.CONSUL_TOKEN,
                        timeout=3
                    )
                    # Test connection with a simple ping
                    consul_client.agent.self()
                except Exception as e:
                    if self.config.REGISTRY_IGNORE_ERRORS:
                        self.logger.warning(f"Skipping Consul registration in development mode: {str(e)}")
                        return
                    raise
            else:
                # Production settings with longer timeout
                consul_client = consul.Consul(
                    host=self.config.CONSUL_HOST,
                    port=self.config.CONSUL_PORT,
                    token=self.config.CONSUL_TOKEN,
                    scheme='http'
                )
            
            # Get hostname and container IP
            hostname = os.getenv('HOSTNAME', socket.gethostname())
            service_id = f"{self.config.SERVICE_NAME}-{hostname}"
            service_name = self.config.SERVICE_NAME
            
            try:
                # In Docker, use container IP for internal network
                container_ip = socket.gethostbyname(hostname)
                
                # For development on Windows, make sure we use the actual network interface
                if self.config.ENV == 'development' and container_ip == '127.0.0.1':
                    container_ip = self._get_local_ip()
            except:
                container_ip = '127.0.0.1'  # fallback
            
            # Register service with better health check config
            consul_client.agent.service.register(
                name=service_name,
                service_id=service_id,
                address=container_ip,
                port=self.config.PORT,
                tags=[service_name.split('-')[0], 'medical', 'api'],
                check={
                    'name': f'{service_name} health check',
                    'http': f'http://{container_ip}:{self.config.PORT}/health',
                    'interval': self.config.HEALTH_CHECK_INTERVAL,
                    'timeout': self.config.HEALTH_CHECK_TIMEOUT,
                    'deregister_critical_service_after': self.config.HEALTH_CHECK_DEREGISTER_TIMEOUT
                }
            )
            self.logger.info(f"Registered service with Consul: {service_id} at {container_ip}:{self.config.PORT}")
            
            # Register additional metadata if registry service is available
            try:
                self._register_metadata(service_name, container_ip, self.config.PORT)
            except Exception as e:
                if self.config.REGISTRY_IGNORE_ERRORS:
                    self.logger.warning(f"Failed to register metadata (ignored in dev mode): {str(e)}")
                else:
                    raise
                
        except Exception as e:
            self.logger.error(f"Failed to register with Consul: {str(e)}")
            if not self.config.REGISTRY_IGNORE_ERRORS:
                raise
    
    def _get_local_ip(self):
        """Get a non-loopback IP address for the local machine"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(('8.8.8.8', 80))
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
                registry_host = "localhost"
                registry_port = 8761
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
