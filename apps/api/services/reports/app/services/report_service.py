import uuid
from datetime import datetime

from services.logger_service import logger_service


class ReportService:
    """Service for report business logic"""

    def __init__(self, mongodb_client, redis_client, rabbitmq_client):
        self.mongodb_client = mongodb_client
        self.redis_client = redis_client
        self.rabbitmq_client = rabbitmq_client
        self.db = mongodb_client.db

    def get_all_reports(self, search=None, patient_id=None):
        """Get reports with optional search and patient scoping."""
        try:
            query = {}
            if patient_id:
                query["patient_id"] = patient_id
            if search:
                query["$or"] = [
                    {"title": {"$regex": search, "$options": "i"}},
                    {"content": {"$regex": search, "$options": "i"}},
                ]
            return self.mongodb_client.find_reports(query)
        except Exception as e:
            logger_service.error(f"Error getting reports: {e!s}")
            raise

    def get_report_by_id(self, report_id):
        """Get a specific report by ID with caching"""
        try:
            if self.redis_client:
                cached_report = self.redis_client.get_report(report_id)
                if cached_report:
                    return cached_report

            report = self.mongodb_client.find_report_by_id(report_id)
            if report and self.redis_client:
                self.redis_client.cache_report(report_id, report)

            return report
        except Exception as e:
            logger_service.error(f"Error getting report {report_id}: {e!s}")
            raise

    def get_raw_report(self, report_id):
        """Get raw report data (needed for PDF generation)"""
        try:
            return self.mongodb_client.find_report_by_id(report_id)
        except Exception as e:
            logger_service.error(f"Error getting raw report {report_id}: {e!s}")
            raise

    def create_report(self, report_data):
        """Create a new report"""
        try:
            # Insert into database
            report = self.mongodb_client.insert_report(report_data)

            # Persisted report creation is the primary operation. Event delivery
            # is best-effort so a broker outage cannot turn a successful write
            # into a misleading client-side failure.
            try:
                if self.rabbitmq_client:
                    self.rabbitmq_client.publish_report_created(report["_id"])
            except Exception:
                logger_service.exception(
                    "Report persisted but report-created event could not be published"
                )

            return report
        except Exception as e:
            logger_service.error(f"Error creating report: {e!s}")
            raise

    def update_report(self, report_id, report_data):
        """Update an existing report"""
        try:
            # Update in database
            updated_report = self.mongodb_client.update_report(report_id, report_data)

            if updated_report:
                try:
                    if self.redis_client:
                        self.redis_client.invalidate_report(report_id)
                except Exception:
                    logger_service.exception(
                        "Report updated but cache invalidation failed"
                    )

                try:
                    if self.rabbitmq_client:
                        self.rabbitmq_client.publish_report_updated(report_id)
                except Exception:
                    logger_service.exception(
                        "Report updated but report-updated event could not be published"
                    )

            return updated_report
        except Exception as e:
            logger_service.error(f"Error updating report {report_id}: {e!s}")
            raise

    def delete_report(self, report_id):
        """Delete a report"""
        try:
            # Delete from database
            success = self.mongodb_client.delete_report(report_id)

            if success:
                try:
                    if self.redis_client:
                        self.redis_client.invalidate_report(report_id)
                except Exception:
                    logger_service.exception(
                        "Report deleted but cache invalidation failed"
                    )

                try:
                    if self.rabbitmq_client:
                        self.rabbitmq_client.publish_report_deleted(report_id)
                except Exception:
                    logger_service.exception(
                        "Report deleted but report-deleted event could not be published"
                    )

            return success
        except Exception as e:
            logger_service.error(f"Error deleting report {report_id}: {e!s}")
            raise

    def queue_report_for_analysis(self, report_id: str) -> bool:
        """Queue a report for analysis"""
        try:
            report = self.mongodb_client.find_report_by_id(report_id)
            if not report:
                logger_service.error(f"Report not found: {report_id}")
                return False

            self.mongodb_client.update_report(
                report_id,
                {
                    "analysis_status": "queued",
                    "queued_at": datetime.utcnow().isoformat(),
                },
            )

            # Create an analysis record
            self.db.report_analyses.insert_one(
                {
                    "report_id": report_id,
                    "status": "queued",
                    "queued_at": datetime.utcnow().isoformat(),
                }
            )

            # Send to RabbitMQ for processing
            message = {
                "report_id": report_id,
                "timestamp": datetime.utcnow().isoformat(),
            }

            self.rabbitmq_client.publish_message(
                exchange="medical.reports",
                routing_key="report.analysis.requested",
                message=message,
            )

            return True

        except Exception as e:
            logger_service.error(f"Error queueing report for analysis: {e}")
            return False

    def queue_summary_generation(
        self,
        report_ids: list[str],
        summary_type: str,
        requester_id: str | None = None,
    ) -> str:
        """Queue a summary generation job"""
        try:
            # Generate a job ID
            job_id = str(uuid.uuid4())

            # Create a job record
            job = {
                "job_id": job_id,
                "report_ids": report_ids,
                "summary_type": summary_type,
                "requester_id": requester_id,
                "status": "queued",
                "created_at": datetime.utcnow().isoformat(),
            }

            # Save to database
            self.db.summary_jobs.insert_one(job)

            # Send to RabbitMQ for processing
            message = {
                "job_id": job_id,
                "report_ids": report_ids,
                "summary_type": summary_type,
                "requester_id": requester_id,
                "timestamp": datetime.utcnow().isoformat(),
            }

            self.rabbitmq_client.publish_message(
                exchange="medical.reports",
                routing_key="report.summary.requested",
                message=message,
            )

            return job_id

        except Exception as e:
            logger_service.error(f"Error queueing summary generation: {e}")
            return None
