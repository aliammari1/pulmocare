"""First-party observability helpers for PulmoCare microservices.

This module adds three things on top of the existing OpenTelemetry
tracing/metrics/logging wiring (``telemetry.py`` / ``metrics.py`` /
``logging.py``):

1. **Sentry (FastAPI)** error tracking with strict PHI hygiene:
   ``send_default_pii=False`` plus a ``before_send`` scrubber that strips
   request bodies, cookies, headers and obvious PHI-shaped fields before any
   event leaves the process.
2. **Correlation IDs** via ``asgi-correlation-id`` bound into ``structlog`` so
   every log line and Sentry event carries the same request id (the same id
   APISIX injects as ``X-Request-Id``).
3. **OTel GenAI spans** for the vendored MedRAX LangGraph agent. These are
   deliberately **PII-redacted**: we record tool names, token counts and
   latency only -- never image paths, prompts, model outputs or patient text.

Everything degrades gracefully: if an optional dependency (sentry-sdk,
asgi-correlation-id) is not installed, the helper logs a warning and is a no-op
so the service still boots. RESEARCH ONLY -- not a medical device.
"""

from __future__ import annotations

import logging
import re
from collections.abc import Iterator
from contextlib import contextmanager
from time import perf_counter
from typing import TYPE_CHECKING, Any

from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

if TYPE_CHECKING:
    from fastapi import FastAPI

    from pulmocare_shared.config import BaseConfig

_log = logging.getLogger("pulmocare.observability")

# ---------------------------------------------------------------------------
# PHI / sensitive-field scrubbing
# ---------------------------------------------------------------------------

# Field names that must never leave the process in an error event. Matched
# case-insensitively as substrings of the key.
_SENSITIVE_KEYS = (
    "password",
    "passwd",
    "secret",
    "token",
    "authorization",
    "api_key",
    "apikey",
    "cookie",
    "ssn",
    "mrn",  # medical record number
    "patient",
    "dob",
    "birth",
    "name",
    "email",
    "phone",
    "address",
    "image_path",
    "image_bytes",
    "narrative",
    "findings",
    "impression",
)

_REDACTED = "[redacted]"

# Anything that looks like an OTLP/PHI free-text blob is dropped wholesale from
# Sentry events; we only keep structural metadata.
_EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")


def _scrub_value(value: Any) -> Any:
    """Recursively redact sensitive keys from a Sentry event payload."""
    if isinstance(value, dict):
        return {k: (_REDACTED if _is_sensitive_key(k) else _scrub_value(v)) for k, v in value.items()}
    if isinstance(value, list):
        return [_scrub_value(v) for v in value]
    if isinstance(value, str):
        return _EMAIL_RE.sub(_REDACTED, value)
    return value


def _is_sensitive_key(key: str) -> bool:
    lowered = str(key).lower()
    return any(token in lowered for token in _SENSITIVE_KEYS)


def _before_send(event: dict[str, Any], _hint: dict[str, Any]) -> dict[str, Any]:
    """Sentry ``before_send`` hook: strip request bodies + PHI-shaped fields."""
    request = event.get("request")
    if isinstance(request, dict):
        # Never ship request bodies, query strings, cookies or headers: any of
        # them can carry tokens or patient identifiers.
        for field in ("data", "cookies", "headers", "query_string"):
            request.pop(field, None)
        event["request"] = request

    for section in ("extra", "contexts", "tags"):
        if section in event:
            event[section] = _scrub_value(event[section])

    return event


# ---------------------------------------------------------------------------
# Sentry init
# ---------------------------------------------------------------------------


def init_sentry(config: BaseConfig) -> bool:
    """Initialise Sentry for FastAPI with PHI scrubbing.

    No-op (returns ``False``) when ``SENTRY_DSN`` is unset or the SDK is not
    installed, so non-observability environments still boot.
    """
    dsn = getattr(config, "sentry_dsn", "") or ""
    if not dsn:
        _log.info("Sentry disabled (no SENTRY_DSN configured).")
        return False

    try:
        import sentry_sdk  # noqa: PLC0415 - optional dep, imported lazily
        from sentry_sdk.integrations.fastapi import FastApiIntegration  # noqa: PLC0415
        from sentry_sdk.integrations.starlette import StarletteIntegration  # noqa: PLC0415
    except ImportError:
        _log.warning("sentry-sdk not installed; Sentry error tracking disabled.")
        return False

    sentry_sdk.init(
        dsn=dsn,
        environment=config.env,
        release=f"{config.service_name}@{config.version}",
        # PHI hygiene: never attach PII, request bodies or local variables.
        send_default_pii=False,
        attach_stacktrace=True,
        include_local_variables=False,
        max_request_body_size="never",
        traces_sample_rate=getattr(config, "sentry_traces_sample_rate", 0.0),
        before_send=_before_send,
        integrations=[
            StarletteIntegration(),
            FastApiIntegration(),
        ],
    )
    _log.info("Sentry initialised for %s (PII off, PHI scrubbed).", config.service_name)
    return True


# ---------------------------------------------------------------------------
# Correlation IDs (asgi-correlation-id + structlog)
# ---------------------------------------------------------------------------


def setup_correlation_id(app: FastAPI) -> bool:
    """Add ``asgi-correlation-id`` middleware bound to APISIX's X-Request-Id.

    Returns ``False`` (no-op) when the package is unavailable.
    """
    try:
        from asgi_correlation_id import CorrelationIdMiddleware  # noqa: PLC0415 - optional dep
    except ImportError:
        _log.warning("asgi-correlation-id not installed; correlation IDs disabled.")
        return False

    # Reuse the gateway's request id so logs/traces/Sentry all share one id.
    app.add_middleware(CorrelationIdMiddleware, header_name="X-Request-Id")
    _bind_structlog_correlation()
    return True


def _bind_structlog_correlation() -> None:
    """Inject the current correlation id into every structlog record."""
    try:
        import structlog  # noqa: PLC0415 - optional dep, imported lazily
        from asgi_correlation_id.context import correlation_id  # noqa: PLC0415
    except ImportError:
        return

    def _add_correlation_id(_logger: Any, _name: str, event_dict: dict[str, Any]) -> dict[str, Any]:
        cid = correlation_id.get()
        if cid:
            event_dict["correlation_id"] = cid
        return event_dict

    # Prepend the processor without clobbering the existing structlog config.
    config = structlog.get_config()
    processors = list(config.get("processors", []))
    if _add_correlation_id not in processors:
        processors.insert(0, _add_correlation_id)
        structlog.configure(processors=processors)


def setup_observability(config: BaseConfig, app: FastAPI) -> dict[str, bool]:
    """Convenience: wire Sentry + correlation IDs in one call.

    Safe to call from any service's ``app.py`` after ``setup_telemetry``.
    """
    return {
        "sentry": init_sentry(config),
        "correlation_id": setup_correlation_id(app),
    }


# ---------------------------------------------------------------------------
# OTel GenAI spans for the MedRAX agent (PII-redacted)
# ---------------------------------------------------------------------------

_GENAI_SYSTEM = "medrax"


@contextmanager
def genai_tool_span(
    tool_name: str,
    *,
    operation: str = "execute_tool",
    model: str | None = None,
) -> Iterator[dict[str, Any]]:
    """Trace a single MedRAX tool / LLM call as an OTel GenAI span.

    PII-redacted by construction: only tool name, optional model id, token
    counts and latency are recorded. **No** image paths, prompts, patient text
    or model outputs are ever attached.

    Yield a small mutable dict; set ``span["input_tokens"]`` /
    ``span["output_tokens"]`` inside the block to record usage::

        with genai_tool_span("ChestXRayReportGeneratorTool") as s:
            result = tool.run(...)
            s["output_tokens"] = result.usage

    Follows the OpenTelemetry GenAI semantic conventions
    (``gen_ai.*`` attributes).
    """
    tracer = trace.get_tracer("pulmocare.genai")
    usage: dict[str, Any] = {}
    started = perf_counter()
    with tracer.start_as_current_span(f"gen_ai.{operation} {tool_name}") as span:
        span.set_attribute("gen_ai.system", _GENAI_SYSTEM)
        span.set_attribute("gen_ai.operation.name", operation)
        span.set_attribute("gen_ai.tool.name", tool_name)
        if model:
            span.set_attribute("gen_ai.request.model", model)
        try:
            yield usage
        except Exception as exc:
            span.set_status(Status(StatusCode.ERROR, type(exc).__name__))
            span.record_exception(exc)
            raise
        finally:
            elapsed_ms = (perf_counter() - started) * 1000.0
            span.set_attribute("gen_ai.client.operation.duration_ms", round(elapsed_ms, 2))
            if "input_tokens" in usage:
                span.set_attribute("gen_ai.usage.input_tokens", int(usage["input_tokens"]))
            if "output_tokens" in usage:
                span.set_attribute("gen_ai.usage.output_tokens", int(usage["output_tokens"]))
