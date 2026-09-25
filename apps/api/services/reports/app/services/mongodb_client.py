import time
from datetime import UTC, datetime

from bson import ObjectId
from pymongo import MongoClient

from services.logger_service import logger_service


class MongoDBClient:
    """MongoDB client service for database operations."""

    def __init__(self, config):
        self.config = config
        self.client = None
        self.db = None
        self.reports_collection = None
        self.init_connection()

    def init_connection(self):
        """Initialize MongoDB using the shared typed configuration."""
        max_retries = 5
        retry_delay = 1

        for attempt in range(max_retries):
            try:
                self.client = MongoClient(
                    self.config.mongodb_uri,
                    maxPoolSize=self.config.mongodb_pool_size,
                    minPoolSize=self.config.mongodb_min_pool_size,
                    maxIdleTimeMS=self.config.mongodb_max_idle_time_ms,
                    connectTimeoutMS=self.config.mongodb_connect_timeout_ms,
                    serverSelectionTimeoutMS=(self.config.mongodb_server_selection_timeout_ms),
                )
                self.db = self.client[self.config.mongodb_database]

                if "reports" not in self.db.list_collection_names():
                    self.db.create_collection("reports")

                self.reports_collection = self.db["reports"]
                self.db.command("ping")
                logger_service.info("Connected to MongoDB successfully")
                return
            except Exception as exc:
                logger_service.error(f"MongoDB connection attempt {attempt + 1} failed: {exc!s}")
                if attempt < max_retries - 1:
                    time.sleep(retry_delay)
                    retry_delay *= 2

        raise RuntimeError("Failed to connect to MongoDB after multiple attempts")

    @staticmethod
    def _report_query(report_id: str) -> dict:
        try:
            return {"_id": ObjectId(report_id)}
        except Exception:
            return {"report_id": report_id}

    def find_reports(self, query=None):
        reports = list(self.reports_collection.find(query or {}))
        for report in reports:
            report["_id"] = str(report["_id"])
        return reports

    def find_report_by_id(self, report_id):
        report = self.reports_collection.find_one(self._report_query(report_id))
        if report:
            report["_id"] = str(report["_id"])
        return report

    def insert_report(self, report_data):
        now = datetime.now(UTC)
        report_data["created_at"] = now
        report_data["updated_at"] = now

        result = self.reports_collection.insert_one(report_data)
        report_data["_id"] = str(result.inserted_id)
        return report_data

    def update_report(self, report_id, report_data):
        report_data["updated_at"] = datetime.now(UTC)
        result = self.reports_collection.update_one(
            self._report_query(report_id),
            {"$set": report_data},
        )
        if result.matched_count == 0:
            return None

        report = self.find_report_by_id(report_id)
        return report or report_data

    def delete_report(self, report_id):
        result = self.reports_collection.delete_one(self._report_query(report_id))
        return result.deleted_count > 0

    def close(self):
        if self.client:
            self.client.close()
            logger_service.info("Closed MongoDB connection")

    def check_health(self):
        try:
            self.db.command("ping")
            return "UP"
        except Exception as exc:
            return f"DOWN: {exc!s}"
