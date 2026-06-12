"""Tests for the AI radiology-report service (MedRAX integration).

These exercise the service logic WITHOUT loading torch/transformers or any
model weights: the MedRAX tool loaders are monkeypatched. They pin two things
that matter:
1. The research-only banner is always present.
2. Missing model weights degrade gracefully (no exception, model_status set).
"""

import os

import pytest

from services import radiology_service


def test_disclaimer_present_on_every_report(monkeypatch):
    # Fake the MedRAX report tool: return a well-formed combined report.
    class FakeTool:
        def _run(self, image_path):
            return (
                "CHEST X-RAY REPORT\n\nFINDINGS:\nNo acute findings.\n\nIMPRESSION:\nNormal chest radiograph.",
                {"analysis_status": "completed"},
            )

    monkeypatch.setattr(radiology_service, "_load_report_tool", lambda: FakeTool())
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    report = radiology_service.generate_report("/data/cxr/normal1.jpg", include_narrative=True)

    assert report.research_only is True
    assert "RESEARCH ONLY" in report.disclaimer
    assert "NOT FOR CLINICAL USE" in report.disclaimer
    assert report.findings == "No acute findings."
    assert report.impression == "Normal chest radiograph."
    assert report.model_status == "completed"
    # No ANTHROPIC_API_KEY -> no narrative, but no crash.
    assert report.narrative is None


def test_missing_weights_degrade_gracefully(monkeypatch):
    def _boom():
        raise RuntimeError("model weights not found")

    monkeypatch.setattr(radiology_service, "_load_report_tool", _boom)
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    report = radiology_service.generate_report("/data/cxr/normal1.jpg")

    # Degraded, not failed; still a structured report with the banner.
    assert report.model_status == "degraded"
    assert report.findings is None
    assert report.research_only is True
    assert "unavailable" in (report.detail or "")


def test_vqa_path(monkeypatch):
    class FakeReport:
        def _run(self, image_path):
            return ("CHEST X-RAY REPORT\n\nFINDINGS:\nClear lungs.", {"analysis_status": "completed"})

    class FakeVQA:
        def _run(self, image_path, question):
            return ("No effusion is seen.", {})

    monkeypatch.setattr(radiology_service, "_load_report_tool", lambda: FakeReport())
    monkeypatch.setattr(radiology_service, "_load_vqa_tool", lambda: FakeVQA())
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    report = radiology_service.generate_report(
        "/data/cxr/effusion1.png",
        question="Is there pleural effusion?",
        include_narrative=False,
    )

    assert report.vqa_question == "Is there pleural effusion?"
    assert report.vqa_answer == "No effusion is seen."
    assert report.findings == "Clear lungs."


def test_split_report_handles_findings_only():
    f, i = radiology_service._split_report("CHEST X-RAY REPORT\n\nFINDINGS:\nLow lung volumes.")
    assert f == "Low lung volumes."
    assert i is None


def test_narrative_uses_haiku_model(monkeypatch):
    """The narrative step must call claude-haiku-4-5 via the Anthropic SDK."""
    pytest.importorskip("anthropic")
    import anthropic

    captured = {}

    class FakeBlock:
        type = "text"
        text = "Plain-language summary."

    class FakeMessage:
        content = [FakeBlock()]

    class FakeMessages:
        def create(self, **kwargs):
            captured.update(kwargs)
            return FakeMessage()

    class FakeClient:
        messages = FakeMessages()

    monkeypatch.setattr(anthropic, "Anthropic", lambda *a, **k: FakeClient())
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")

    out = radiology_service._narrate("Clear lungs.", "Normal.", None)

    assert out == "Plain-language summary."
    assert captured["model"] == "claude-haiku-4-5"
    assert os.environ.get("ANTHROPIC_API_KEY") == "test-key"
