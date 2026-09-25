"""Schema generation must not connect to production backing services."""

import importlib.util
from pathlib import Path
from unittest.mock import patch


def test_openapi_exports_without_mongodb(monkeypatch):
    monkeypatch.setenv("OTEL_SDK_DISABLED", "true")
    from services.mongodb_client import MongoDBClient

    app_file = Path(__file__).resolve().parents[1] / "app.py"
    spec = importlib.util.spec_from_file_location("reports_openapi_module", app_file)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)

    with patch.object(MongoDBClient, "__init__", side_effect=AssertionError("MongoDB used during schema export")):
        spec.loader.exec_module(module)
        schema = module.app.openapi()

    assert "/api/reports" in schema["paths"] or "/api/reports/" in schema["paths"]
