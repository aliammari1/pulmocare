import consul
import requests
import logging
import json
from datetime import datetime
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

class KongConsulSync:
    def __init__(self, config):
        self.config = config
        self.consul = consul.Consul(
            host=config.CONSUL_HOST,
            port=config.CONSUL_PORT,
            scheme=config.CONSUL_SCHEME
        )
        self.kong_admin_url = config.KONG_ADMIN_URL

    def sync_service(self, service_name: str, service_data: Dict) -> None:
        """
        Sync a service from Consul to Kong
        """
        try:
            # Extract service information
            address = service_data.get('ServiceAddress')
            port = service_data.get('ServicePort')
            tags = service_data.get('ServiceTags', [])
            meta = service_data.get('ServiceMeta', {})

            # Configure Kong upstream
            upstream_name = f"{service_name}-upstream"
            self._ensure_upstream(upstream_name)
            
            # Add target to upstream
            target_url = f"{address}:{port}"
            self._add_target_to_upstream(upstream_name, target_url)

            # Configure Kong service and routes based on metadata
            self._configure_kong_service(
                service_name=service_name,
                upstream_name=upstream_name,
                meta=meta,
                tags=tags
            )

            logger.info(f"Successfully synced service {service_name} to Kong")
        except Exception as e:
            logger.error(f"Failed to sync service {service_name} to Kong: {str(e)}")
            raise

    def _ensure_upstream(self, upstream_name: str) -> None:
        """
        Create or update Kong upstream
        """
        try:
            # Check if upstream exists
            response = requests.get(
                f"{self.kong_admin_url}/upstreams/{upstream_name}"
            )

            if response.status_code == 404:
                # Create new upstream
                response = requests.post(
                    f"{self.kong_admin_url}/upstreams",
                    json={
                        "name": upstream_name,
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
                )
                response.raise_for_status()
                logger.info(f"Created Kong upstream: {upstream_name}")

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to ensure upstream {upstream_name}: {str(e)}")
            raise

    def _add_target_to_upstream(self, upstream_name: str, target: str) -> None:
        """
        Add a target to a Kong upstream
        """
        try:
            response = requests.post(
                f"{self.kong_admin_url}/upstreams/{upstream_name}/targets",
                json={
                    "target": target,
                    "weight": 100
                }
            )
            response.raise_for_status()
            logger.info(f"Added target {target} to upstream {upstream_name}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to add target {target} to upstream {upstream_name}: {str(e)}")
            raise

    def _configure_kong_service(self, service_name: str, upstream_name: str, meta: Dict, tags: List[str]) -> None:
        """
        Configure Kong service and its routes based on metadata
        """
        try:
            # Create or update service
            service_url = f"http://{upstream_name}"
            service_data = {
                "name": service_name,
                "url": service_url,
                "retries": 5,
                "connect_timeout": 1000,
                "write_timeout": 60000,
                "read_timeout": 60000
            }

            # Check if service exists
            response = requests.get(f"{self.kong_admin_url}/services/{service_name}")
            
            if response.status_code == 404:
                # Create new service
                response = requests.post(
                    f"{self.kong_admin_url}/services",
                    json=service_data
                )
            else:
                # Update existing service
                response = requests.patch(
                    f"{self.kong_admin_url}/services/{service_name}",
                    json=service_data
                )
            
            response.raise_for_status()

            # Configure routes based on metadata
            self._configure_routes(service_name, meta)

            logger.info(f"Configured Kong service: {service_name}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to configure Kong service {service_name}: {str(e)}")
            raise

    def _configure_routes(self, service_name: str, meta: Dict) -> None:
        """
        Configure Kong routes for a service based on metadata
        """
        try:
            routes = meta.get('routes', [])
            for route in routes:
                route_data = {
                    "name": f"{service_name}-{route['name']}",
                    "service": {"name": service_name},
                    "paths": route.get('paths', [f"/api/{service_name}"]),
                    "strip_path": route.get('strip_path', False),
                    "preserve_host": route.get('preserve_host', True),
                    "methods": route.get('methods', ["GET", "POST", "PUT", "DELETE", "PATCH"])
                }

                # Add the route
                response = requests.post(
                    f"{self.kong_admin_url}/services/{service_name}/routes",
                    json=route_data
                )
                response.raise_for_status()

                # Configure plugins for the route if specified
                if 'plugins' in route:
                    for plugin in route['plugins']:
                        plugin_data = {
                            "name": plugin['name'],
                            "route": {"name": route_data['name']},
                            "config": plugin.get('config', {})
                        }
                        
                        response = requests.post(
                            f"{self.kong_admin_url}/routes/{route_data['name']}/plugins",
                            json=plugin_data
                        )
                        response.raise_for_status()

            logger.info(f"Configured routes for service: {service_name}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to configure routes for service {service_name}: {str(e)}")
            raise