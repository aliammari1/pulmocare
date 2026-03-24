"""
Consul client for service discovery and configuration.
"""

from typing import TYPE_CHECKING, Any

import consul

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class ConsulClient:
    """Consul client for service discovery and health checks."""

    _instance: "ConsulClient | None" = None

    def __new__(cls, config: "BaseConfig | None" = None) -> "ConsulClient":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, config: "BaseConfig | None" = None) -> None:
        if self._initialized:
            return

        if config is None:
            from pulmocare_shared.config import get_config
            config = get_config()

        self.config = config
        self.client = consul.Consul(
            host=config.consul_host,
            port=config.consul_port,
            token=config.consul_token if config.consul_token else None,
        )
        self._initialized = True

    def register_service(
        self,
        service_name: str | None = None,
        service_id: str | None = None,
        address: str | None = None,
        port: int | None = None,
        tags: list[str] | None = None,
        check_http: str | None = None,
        check_interval: str = "10s",
        check_timeout: str = "5s",
        deregister_critical_service_after: str = "30s",
    ) -> bool:
        """Register a service with Consul."""
        try:
            service_name = service_name or self.config.service_name
            service_id = service_id or f"{service_name}-{self.config.host}:{self.config.port}"
            address = address or self.config.host
            port = port or self.config.port

            check = None
            if check_http:
                check = consul.Check.http(
                    check_http,
                    interval=check_interval,
                    timeout=check_timeout,
                    deregister=deregister_critical_service_after,
                )

            self.client.agent.service.register(
                name=service_name,
                service_id=service_id,
                address=address,
                port=port,
                tags=tags or [self.config.env, self.config.version],
                check=check,
            )

            print(f"Registered service {service_name} with Consul")
            return True

        except Exception as e:
            print(f"Failed to register service with Consul: {e}")
            return False

    def deregister_service(self, service_id: str | None = None) -> bool:
        """Deregister a service from Consul."""
        try:
            service_id = service_id or f"{self.config.service_name}-{self.config.host}:{self.config.port}"
            self.client.agent.service.deregister(service_id)
            print(f"Deregistered service {service_id} from Consul")
            return True
        except Exception as e:
            print(f"Failed to deregister service from Consul: {e}")
            return False

    def get_service(self, service_name: str) -> list[dict[str, Any]]:
        """Get healthy instances of a service."""
        try:
            _, services = self.client.health.service(service_name, passing=True)
            return [
                {
                    "id": service["Service"]["ID"],
                    "address": service["Service"]["Address"],
                    "port": service["Service"]["Port"],
                    "tags": service["Service"]["Tags"],
                }
                for service in services
            ]
        except Exception as e:
            print(f"Failed to get service {service_name}: {e}")
            return []

    def get_service_url(self, service_name: str) -> str | None:
        """Get URL for a service (first healthy instance)."""
        services = self.get_service(service_name)
        if services:
            service = services[0]
            return f"http://{service['address']}:{service['port']}"
        return None

    def get_kv(self, key: str) -> str | None:
        """Get a value from Consul KV store."""
        try:
            _, data = self.client.kv.get(key)
            if data:
                return data["Value"].decode("utf-8")
            return None
        except Exception as e:
            print(f"Failed to get KV {key}: {e}")
            return None

    def set_kv(self, key: str, value: str) -> bool:
        """Set a value in Consul KV store."""
        try:
            return self.client.kv.put(key, value)
        except Exception as e:
            print(f"Failed to set KV {key}: {e}")
            return False

    def delete_kv(self, key: str) -> bool:
        """Delete a value from Consul KV store."""
        try:
            return self.client.kv.delete(key)
        except Exception as e:
            print(f"Failed to delete KV {key}: {e}")
            return False

    def check_health(self) -> str:
        """Check Consul connection health."""
        try:
            self.client.status.leader()
            return "UP"
        except Exception as e:
            return f"DOWN: {e}"


def get_consul_client(config: "BaseConfig | None" = None) -> ConsulClient:
    """Get Consul client instance."""
    return ConsulClient(config)
