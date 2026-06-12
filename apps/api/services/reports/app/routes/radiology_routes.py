"""AI radiology-report endpoint (MedRAX report_generation / xray_vqa).

RESEARCH ONLY -- NOT FOR CLINICAL USE. Every response embeds the research-only
banner (see models/radiology.py).
"""

from __future__ import annotations

from fastapi import APIRouter, HTTPException

from models.radiology import RESEARCH_ONLY_DISCLAIMER, RadiologyReport, RadiologyReportRequest
from services import radiology_service

router = APIRouter(prefix="/api/reports/ai", tags=["AI Radiology (research only)"])


@router.get("/disclaimer")
async def disclaimer() -> dict[str, str | bool]:
    """Return the standing research-only disclaimer for this feature."""
    return {"research_only": True, "disclaimer": RESEARCH_ONLY_DISCLAIMER}


@router.post(
    "/radiology-report",
    response_model=RadiologyReport,
    summary="Generate a structured chest X-ray report (RESEARCH ONLY)",
)
async def radiology_report(request: RadiologyReportRequest) -> RadiologyReport:
    """Generate a structured radiology report from a chest X-ray.

    Backed by the vendored MedRAX report-generation and VQA tools
    (arXiv:2502.02673), with an optional claude-haiku-4-5 narrative step. The
    response always carries the RESEARCH-ONLY banner and is intended for
    clinician review/edit, never for clinical decision-making.
    """
    if not request.image_path:
        raise HTTPException(status_code=400, detail="image_path is required")

    return radiology_service.generate_report(
        image_path=request.image_path,
        question=request.question,
        include_narrative=request.include_narrative,
    )
