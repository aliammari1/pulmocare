"""
Reports Service - FastAPI Application.

Handles authenticated medical report storage and export.
"""

import asyncio
import threading
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Response
from fastapi.responses import FileResponse
from fastapi.routing import APIRouter

from auth.keycloak_auth import get_current_report_writer, get_current_user
from config import get_config
from pulmocare_shared import setup_cors, setup_observability, setup_telemetry
from pulmocare_shared.middleware import health_router
from report_generator import ReportGenerator
from routes.assistant_routes import router as assistant_router
from routes.integration_routes import router as integration_router
from routes.radiology_routes import router as radiology_router
from services.mongodb_client import MongoDBClient
from services.rabbitmq_client import RabbitMQClient
from services.redis_client import RedisClient
from services.report_service import ReportService

config = get_config()
api = APIRouter()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    """Connect backing services at startup, leaving schema import side-effect free."""
    redis_client = RedisClient(config)
    mongodb_client = await asyncio.to_thread(MongoDBClient, config)
    rabbitmq_client = await asyncio.to_thread(RabbitMQClient, config)
    _app.state.report_service = ReportService(mongodb_client, redis_client, rabbitmq_client)
    try:
        yield
    finally:
        _app.state.report_service = None
        rabbitmq_client.close()
        mongodb_client.close()
        redis_client.close()


def _service() -> ReportService:
    service = getattr(app.state, "report_service", None)
    if service is None:
        raise HTTPException(status_code=503, detail="Reports service is not ready")
    return service


app = FastAPI(
    title="Reports API",
    version=config.version,
    docs_url="/docs" if config.is_development else None,
    redoc_url="/redoc" if config.is_development else None,
    lifespan=lifespan,
)

setup_cors(app, config)
setup_telemetry(config, app)
setup_observability(config, app)
app.include_router(health_router)

report_generator = ReportGenerator()


def _roles(user_info: dict) -> set[str]:
    return set(user_info.get("roles", []))


def _is_staff(user_info: dict) -> bool:
    return not _roles(user_info).isdisjoint({"doctor", "radiologist", "admin"})


def _ensure_can_write(report: dict, user_info: dict) -> None:
    roles = _roles(user_info)
    if "admin" in roles:
        return

    user_id = str(user_info.get("user_id", ""))
    owner_id = str(report.get("doctor_id") or report.get("created_by") or "")
    if user_id and owner_id == user_id:
        return

    raise HTTPException(
        status_code=403,
        detail="You do not have permission to modify this report",
    )


def _ensure_can_read(report: dict, user_info: dict) -> None:
    if _is_staff(user_info):
        return

    if "patient" in _roles(user_info) and str(report.get("patient_id", "")) == str(user_info.get("user_id", "")):
        return

    raise HTTPException(
        status_code=403,
        detail="You do not have access to this report",
    )


@api.get("/")
async def get_reports(
    search: str | None = None,
    user_info: dict = Depends(get_current_user),
):
    """List reports visible to the authenticated user."""
    roles = _roles(user_info)
    if _is_staff(user_info):
        return _service().get_all_reports(search=search)

    if "patient" in roles:
        return _service().get_all_reports(
            search=search,
            patient_id=str(user_info.get("user_id", "")),
        )

    raise HTTPException(status_code=403, detail="Clinical account role required")


@api.get("/{report_id}")
async def get_report(
    report_id: str,
    user_info: dict = Depends(get_current_user),
):
    """Get a report when the caller is allowed to view it."""
    report = _service().get_report_by_id(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    _ensure_can_read(report, user_info)
    return report


@api.post("/", status_code=201)
async def create_report(
    data: dict,
    user_info: dict = Depends(get_current_report_writer),
):
    """Create a report as an authenticated clinician."""
    if not data:
        raise HTTPException(status_code=400, detail="No data provided")

    payload = dict(data)
    writer_id = str(user_info.get("user_id", ""))
    payload["doctor_id"] = writer_id
    payload["created_by"] = writer_id
    return _service().create_report(payload)


@api.put("/{report_id}")
async def update_report(
    report_id: str,
    data: dict,
    user_info: dict = Depends(get_current_report_writer),
):
    """Update an existing report as an authenticated clinician."""
    if not data:
        raise HTTPException(status_code=400, detail="No data provided")

    existing = _service().get_raw_report(report_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Report not found")
    _ensure_can_write(existing, user_info)

    payload = dict(data)
    for immutable_key in (
        "_id",
        "id",
        "report_id",
        "patient_id",
        "doctor_id",
        "created_by",
        "created_at",
    ):
        payload.pop(immutable_key, None)
    payload["updated_by"] = user_info.get("user_id")
    report = _service().update_report(report_id, payload)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report


@api.delete("/{report_id}", status_code=204)
async def delete_report(
    report_id: str,
    user_info: dict = Depends(get_current_report_writer),
):
    """Delete a report as an authenticated clinician."""
    existing = _service().get_raw_report(report_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Report not found")
    _ensure_can_write(existing, user_info)

    if not _service().delete_report(report_id):
        raise HTTPException(status_code=404, detail="Report not found")
    return Response(status_code=204)


@api.get("/{report_id}/export")
async def export_report(
    report_id: str,
    user_info: dict = Depends(get_current_user),
):
    """Generate and download a report PDF when the caller can read it."""
    report = _service().get_raw_report(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    _ensure_can_read(report, user_info)
    output_path = report_generator.generate_pdf(report)

    return FileResponse(
        path=output_path,
        media_type="application/pdf",
        filename=f"medical_report_{report_id}.pdf",
    )


app.include_router(api, prefix="/api/reports")
app.include_router(integration_router)
app.include_router(assistant_router)
app.include_router(radiology_router)

from consumer import main as consumer_main

if __name__ == "__main__":
    consumer_thread = threading.Thread(target=consumer_main, daemon=True)
    consumer_thread.start()

    uvicorn.run(
        "app:app",
        host=config.host,
        port=config.port,
        reload=config.is_development,
        log_level="debug" if config.debug else "info",
    )
