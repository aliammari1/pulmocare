from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel

from auth.keycloak_auth import get_current_report_writer
from config import Config
from services.logger_service import logger_service
from services.mongodb_client import MongoDBClient
from services.rabbitmq_client import RabbitMQClient
from services.report_service import ReportService

router = APIRouter(prefix="/api/integration", tags=["Integration"])

mongodb_client = MongoDBClient(Config)
rabbitmq_client = RabbitMQClient(Config)
report_service = ReportService(mongodb_client, None, rabbitmq_client)


class AnalysisSummaryRequest(BaseModel):
    report_ids: list[str]
    summary_type: str = "general"


@router.post(
    "/analyze-report",
    status_code=status.HTTP_202_ACCEPTED,
)
async def analyze_report(
    report_id: str = Query(..., description="ID of the report to analyze"),
    user_info: dict = Depends(get_current_report_writer),
):
    """Queue an existing report for analysis."""
    del user_info
    try:
        if not report_service.get_report_by_id(report_id):
            raise HTTPException(status_code=404, detail="Report not found")

        if not report_service.queue_report_for_analysis(report_id):
            raise HTTPException(
                status_code=503,
                detail="Unable to queue report analysis",
            )

        return {"message": "Report queued for analysis", "report_id": report_id}
    except HTTPException:
        raise
    except Exception:
        logger_service.exception("Error queueing report analysis")
        raise HTTPException(
            status_code=500,
            detail="Unable to queue report analysis",
        )


@router.get("/report-analysis/{report_id}")
async def get_report_analysis(
    report_id: str,
    user_info: dict = Depends(get_current_report_writer),
):
    """Return persisted analysis results for a report."""
    del user_info
    try:
        analysis = mongodb_client.db.report_analyses.find_one({"report_id": report_id})
        if not analysis:
            raise HTTPException(
                status_code=404,
                detail="Report analysis not found",
            )

        analysis["_id"] = str(analysis["_id"])
        return analysis
    except HTTPException:
        raise
    except Exception:
        logger_service.exception("Error retrieving report analysis")
        raise HTTPException(
            status_code=500,
            detail="Unable to retrieve report analysis",
        )


@router.post(
    "/create-analysis-summary",
    status_code=status.HTTP_202_ACCEPTED,
)
async def create_analysis_summary(
    data: AnalysisSummaryRequest,
    user_info: dict = Depends(get_current_report_writer),
):
    """Queue a summary job for existing report analyses."""
    if not data.report_ids:
        raise HTTPException(status_code=400, detail="Report IDs are required")

    missing = [report_id for report_id in data.report_ids if not report_service.get_report_by_id(report_id)]
    if missing:
        raise HTTPException(
            status_code=404,
            detail="One or more reports were not found",
        )

    try:
        job_id = report_service.queue_summary_generation(
            report_ids=data.report_ids,
            summary_type=data.summary_type,
            requester_id=user_info.get("user_id"),
        )
        if not job_id:
            raise HTTPException(
                status_code=503,
                detail="Unable to queue summary generation",
            )
        return {"message": "Summary generation queued", "job_id": job_id}
    except HTTPException:
        raise
    except Exception:
        logger_service.exception("Error queueing summary generation")
        raise HTTPException(
            status_code=500,
            detail="Unable to queue summary generation",
        )
