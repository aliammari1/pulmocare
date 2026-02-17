"""
MongoDB client for database operations.
"""

from typing import TYPE_CHECKING, Any

from pymongo import MongoClient
from pymongo.collection import Collection
from pymongo.database import Database

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class MongoDBClient:
    """MongoDB client for database operations."""

    _instance: "MongoDBClient | None" = None

    def __new__(cls, config: "BaseConfig | None" = None) -> "MongoDBClient":
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
        self.client = MongoClient(
            host=config.mongodb_host,
            port=config.mongodb_port,
            username=config.mongodb_username,
            password=config.mongodb_password,
            authSource="admin",
            maxPoolSize=config.mongodb_pool_size,
            minPoolSize=config.mongodb_min_pool_size,
            maxIdleTimeMS=config.mongodb_max_idle_time_ms,
            connectTimeoutMS=config.mongodb_connect_timeout_ms,
            serverSelectionTimeoutMS=config.mongodb_server_selection_timeout_ms,
        )
        self.database: Database = self.client[config.mongodb_database]
        self._initialized = True

    def get_collection(self, collection_name: str) -> Collection:
        """Get a collection from the database."""
        return self.database[collection_name]

    def insert_one(self, collection_name: str, document: dict[str, Any]) -> str | None:
        """Insert a single document."""
        try:
            result = self.get_collection(collection_name).insert_one(document)
            return str(result.inserted_id)
        except Exception as e:
            print(f"MongoDB insert error: {e}")
            return None

    def insert_many(self, collection_name: str, documents: list[dict[str, Any]]) -> list[str]:
        """Insert multiple documents."""
        try:
            result = self.get_collection(collection_name).insert_many(documents)
            return [str(id) for id in result.inserted_ids]
        except Exception as e:
            print(f"MongoDB insert_many error: {e}")
            return []

    def find_one(self, collection_name: str, query: dict[str, Any]) -> dict[str, Any] | None:
        """Find a single document."""
        try:
            return self.get_collection(collection_name).find_one(query)
        except Exception as e:
            print(f"MongoDB find_one error: {e}")
            return None

    def find_many(
        self,
        collection_name: str,
        query: dict[str, Any],
        skip: int = 0,
        limit: int = 100,
        sort: list[tuple[str, int]] | None = None,
    ) -> list[dict[str, Any]]:
        """Find multiple documents."""
        try:
            cursor = self.get_collection(collection_name).find(query).skip(skip).limit(limit)
            if sort:
                cursor = cursor.sort(sort)
            return list(cursor)
        except Exception as e:
            print(f"MongoDB find_many error: {e}")
            return []

    def update_one(
        self,
        collection_name: str,
        query: dict[str, Any],
        update: dict[str, Any],
        upsert: bool = False,
    ) -> bool:
        """Update a single document."""
        try:
            result = self.get_collection(collection_name).update_one(query, {"$set": update}, upsert=upsert)
            return result.modified_count > 0 or result.upserted_id is not None
        except Exception as e:
            print(f"MongoDB update_one error: {e}")
            return False

    def update_many(
        self,
        collection_name: str,
        query: dict[str, Any],
        update: dict[str, Any],
    ) -> int:
        """Update multiple documents."""
        try:
            result = self.get_collection(collection_name).update_many(query, {"$set": update})
            return result.modified_count
        except Exception as e:
            print(f"MongoDB update_many error: {e}")
            return 0

    def delete_one(self, collection_name: str, query: dict[str, Any]) -> bool:
        """Delete a single document."""
        try:
            result = self.get_collection(collection_name).delete_one(query)
            return result.deleted_count > 0
        except Exception as e:
            print(f"MongoDB delete_one error: {e}")
            return False

    def delete_many(self, collection_name: str, query: dict[str, Any]) -> int:
        """Delete multiple documents."""
        try:
            result = self.get_collection(collection_name).delete_many(query)
            return result.deleted_count
        except Exception as e:
            print(f"MongoDB delete_many error: {e}")
            return 0

    def count_documents(self, collection_name: str, query: dict[str, Any] | None = None) -> int:
        """Count documents matching query."""
        try:
            return self.get_collection(collection_name).count_documents(query or {})
        except Exception as e:
            print(f"MongoDB count error: {e}")
            return 0

    def aggregate(self, collection_name: str, pipeline: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Run aggregation pipeline."""
        try:
            return list(self.get_collection(collection_name).aggregate(pipeline))
        except Exception as e:
            print(f"MongoDB aggregate error: {e}")
            return []

    def create_index(
        self,
        collection_name: str,
        keys: list[tuple[str, int]],
        unique: bool = False,
        sparse: bool = False,
    ) -> str | None:
        """Create an index on a collection."""
        try:
            return self.get_collection(collection_name).create_index(keys, unique=unique, sparse=sparse)
        except Exception as e:
            print(f"MongoDB create_index error: {e}")
            return None

    def check_health(self) -> str:
        """Check MongoDB connection health."""
        try:
            self.client.admin.command("ping")
            return "UP"
        except Exception as e:
            return f"DOWN: {e}"

    def close(self) -> None:
        """Close MongoDB connection."""
        try:
            self.client.close()
            print("Closed MongoDB connection")
        except Exception as e:
            print(f"Error closing MongoDB connection: {e}")


def get_mongodb_client(config: "BaseConfig | None" = None) -> MongoDBClient:
    """Get MongoDB client instance."""
    return MongoDBClient(config)
