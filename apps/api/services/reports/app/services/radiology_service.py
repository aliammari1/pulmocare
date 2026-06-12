"""Radiology-report service: MedRAX tools + a Claude narrative step.

This wraps the vendored MedRAX (arXiv:2502.02673) report-generation and VQA
tools behind a small service so the FastAPI layer never imports torch directly.

Design notes:
- Heavy MedRAX tools (torch/transformers + model weights) are imported and
  constructed *lazily* and cached, so importing this module -- and unit-testing
  the route -- does not require a GPU or downloaded weights.
- If the weights/tools are unavailable, the service degrades gracefully and the
  endpoint still returns a structured (empty-findings) report flagged
  model_status="degraded" rather than 500-ing.
- The narrative step uses the Anthropic SDK (claude-haiku-4-5). It is optional
  and disabled automatically when ANTHROPIC_API_KEY is not set.

NOTHING here is for clinical use. See models/radiology.py for the banner.
"""

from __future__ import annotations

import os

from models.radiology import RESEARCH_ONLY_DISCLAIMER, RadiologyReport
from pulmocare_shared import genai_tool_span

# MedRAX is vendored at apps/api/services/medagent. It is not a dependency of
# the reports service's pyproject (it carries heavy ML deps + its own license);
# the tools are imported lazily and only when weights are actually present.
NARRATIVE_MODEL = "claude-haiku-4-5"

_report_tool = None
_vqa_tool = None


def _load_report_tool():
    """Lazily construct the MedRAX report-generation tool (cached)."""
    global _report_tool
    if _report_tool is None:
        # Imported here so module import never pulls in torch.
        from medrax.tools.report_generation import ChestXRayReportGeneratorTool

        _report_tool = ChestXRayReportGeneratorTool(device="cpu")
    return _report_tool


def _load_vqa_tool():
    """Lazily construct the MedRAX VQA tool (cached)."""
    global _vqa_tool
    if _vqa_tool is None:
        from medrax.tools.xray_vqa import XRayVQATool

        _vqa_tool = XRayVQATool()
    return _vqa_tool


def _narrate(findings: str | None, impression: str | None, vqa_answer: str | None) -> str | None:
    """Add a plain-language narrative via claude-haiku-4-5, if configured."""
    if not os.getenv("ANTHROPIC_API_KEY"):
        return None
    try:
        import anthropic
    except ImportError:
        return None

    client = anthropic.Anthropic()
    body = "\n".join(
        part
        for part in (
            f"Findings: {findings}" if findings else None,
            f"Impression: {impression}" if impression else None,
            f"VQA answer: {vqa_answer}" if vqa_answer else None,
        )
        if part
    )
    if not body:
        return None

    system = (
        "You are assisting a RESEARCH demo (not a medical device). Rewrite the "
        "structured chest X-ray findings below into a short, neutral, "
        "plain-language summary for a clinician to review and edit. Do NOT add "
        "findings that are not present. Do NOT give diagnoses or "
        "recommendations. Keep it under 120 words."
    )
    # GenAI span records model id + token usage only (no prompt / output text).
    with genai_tool_span("claude_narrative", operation="chat", model=NARRATIVE_MODEL) as span:
        message = client.messages.create(
            model=NARRATIVE_MODEL,
            max_tokens=512,
            system=system,
            messages=[{"role": "user", "content": body}],
        )
        usage = getattr(message, "usage", None)
        if usage is not None:
            span["input_tokens"] = getattr(usage, "input_tokens", 0)
            span["output_tokens"] = getattr(usage, "output_tokens", 0)
    return "".join(block.text for block in message.content if block.type == "text")


def generate_report(
    image_path: str,
    question: str | None = None,
    include_narrative: bool = True,
) -> RadiologyReport:
    """Generate a structured chest X-ray report from MedRAX tools.

    Always returns a RadiologyReport carrying the research-only banner. If the
    MedRAX weights are unavailable, model_status is "degraded" and findings are
    left empty rather than raising.
    """
    findings: str | None = None
    impression: str | None = None
    vqa_answer: str | None = None
    status = "completed"
    detail: str | None = None

    try:
        # PII-redacted GenAI span: records tool name + latency only, never the
        # image path or the generated findings text.
        with genai_tool_span("ChestXRayReportGeneratorTool"):
            report_text, meta = _load_report_tool()._run(image_path)
        if meta.get("analysis_status") == "completed":
            # MedRAX formats "CHEST X-RAY REPORT\n\nFINDINGS:\n...\n\nIMPRESSION:\n..."
            findings, impression = _split_report(report_text)
        else:
            status = "failed"
            detail = meta.get("error", "report generation failed")
    except Exception as e:
        status = "degraded"
        detail = f"MedRAX report model unavailable: {e}"

    if question:
        try:
            with genai_tool_span("XRayVQATool"):
                vqa_answer, _ = _load_vqa_tool()._run(image_path, question)
        except Exception as e:
            if status == "completed":
                status = "degraded"
            detail = (detail + "; " if detail else "") + f"VQA unavailable: {e}"

    narrative = None
    if include_narrative and (findings or impression or vqa_answer):
        try:
            narrative = _narrate(findings, impression, vqa_answer)
        except Exception as e:
            detail = (detail + "; " if detail else "") + f"narrative unavailable: {e}"

    return RadiologyReport(
        disclaimer=RESEARCH_ONLY_DISCLAIMER,
        research_only=True,
        image_path=image_path,
        findings=findings,
        impression=impression,
        vqa_question=question,
        vqa_answer=vqa_answer,
        narrative=narrative,
        model_status=status,
        detail=detail,
    )


def _split_report(report_text: str) -> tuple[str | None, str | None]:
    """Parse MedRAX's combined report string into (findings, impression)."""
    findings = impression = None
    if "FINDINGS:" in report_text:
        rest = report_text.split("FINDINGS:", 1)[1]
        if "IMPRESSION:" in rest:
            f, i = rest.split("IMPRESSION:", 1)
            findings, impression = f.strip(), i.strip()
        else:
            findings = rest.strip()
    else:
        findings = report_text.strip() or None
    return findings, impression
