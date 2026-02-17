"""
Redis client for caching and session management.
"""

import json
from typing import TYPE_CHECKING, Any

import redis

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class RedisClient:
    """Redis client service for caching and session management."""

    _instance: "RedisClient | None" = None

    def __new__(cls, config: "BaseConfig | None" = None) -> "RedisClient":
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
        self.client = redis.Redis(
            host=config.redis_host,
            port=config.redis_port,
            password=config.redis_password,
            db=config.redis_db,
            decode_responses=True,
            socket_timeout=5,
            socket_connect_timeout=5,
        )
        self.ttl = config.cache_ttl
        self._initialized = True

    def get(self, key: str) -> str | None:
        """Get value from cache."""
        try:
            return self.client.get(key)
        except Exception as e:
            print(f"Redis get error: {e}")
            return None

    def set(self, key: str, value: str, ttl: int | None = None) -> bool:
        """Set value in cache."""
        try:
            ttl = ttl or self.ttl
            self.client.setex(key, ttl, value)
            return True
        except Exception as e:
            print(f"Redis set error: {e}")
            return False

    def delete(self, key: str) -> bool:
        """Delete key from cache."""
        try:
            self.client.delete(key)
            return True
        except Exception as e:
            print(f"Redis delete error: {e}")
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        try:
            return bool(self.client.exists(key))
        except Exception as e:
            print(f"Redis exists error: {e}")
            return False

    def get_json(self, key: str) -> dict | None:
        """Get JSON value from cache."""
        try:
            value = self.get(key)
            if value:
                return json.loads(value)
            return None
        except json.JSONDecodeError as e:
            print(f"Redis JSON decode error: {e}")
            return None

    def set_json(self, key: str, value: dict | list, ttl: int | None = None) -> bool:
        """Set JSON value in cache."""
        try:
            return self.set(key, json.dumps(value), ttl)
        except (TypeError, ValueError) as e:
            print(f"Redis JSON encode error: {e}")
            return False

    def increment(self, key: str, amount: int = 1) -> int | None:
        """Increment a counter in cache."""
        try:
            return self.client.incr(key, amount)
        except Exception as e:
            print(f"Redis increment error: {e}")
            return None

    def decrement(self, key: str, amount: int = 1) -> int | None:
        """Decrement a counter in cache."""
        try:
            return self.client.decr(key, amount)
        except Exception as e:
            print(f"Redis decrement error: {e}")
            return None

    def expire(self, key: str, ttl: int) -> bool:
        """Set expiry on a key."""
        try:
            return bool(self.client.expire(key, ttl))
        except Exception as e:
            print(f"Redis expire error: {e}")
            return False

    def keys(self, pattern: str = "*") -> list[str]:
        """Get keys matching pattern."""
        try:
            return self.client.keys(pattern)
        except Exception as e:
            print(f"Redis keys error: {e}")
            return []

    def flush_pattern(self, pattern: str) -> int:
        """Delete all keys matching pattern."""
        try:
            keys = self.keys(pattern)
            if keys:
                return self.client.delete(*keys)
            return 0
        except Exception as e:
            print(f"Redis flush pattern error: {e}")
            return 0

    def check_health(self) -> str:
        """Check Redis connection health."""
        try:
            self.client.ping()
            return "UP"
        except Exception as e:
            return f"DOWN: {e}"

    def close(self) -> None:
        """Close Redis connection."""
        try:
            self.client.close()
            print("Closed Redis connection")
        except Exception as e:
            print(f"Error closing Redis connection: {e}")

    # Convenience methods for specific use cases
    def cache_entity(self, entity_type: str, entity_id: str, data: dict, ttl: int | None = None) -> bool:
        """Cache an entity (patient, doctor, etc.)."""
        key = f"{entity_type}:{entity_id}"
        return self.set_json(key, data, ttl)

    def get_cached_entity(self, entity_type: str, entity_id: str) -> dict | None:
        """Get cached entity."""
        key = f"{entity_type}:{entity_id}"
        return self.get_json(key)

    def invalidate_entity(self, entity_type: str, entity_id: str) -> bool:
        """Invalidate cached entity."""
        key = f"{entity_type}:{entity_id}"
        return self.delete(key)


def get_redis_client(config: "BaseConfig | None" = None) -> RedisClient:
    """Get Redis client instance."""
    return RedisClient(config)
