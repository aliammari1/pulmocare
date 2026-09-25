# PulmoCare

!!! danger "RESEARCH ONLY — NOT FOR CLINICAL USE"
    PulmoCare and the bundled **MedRAX** agent are for research, education, and
    engineering demonstration **only**. This is **not a medical device**, has not
    been cleared by any regulator, and **must not** be used for any clinical,
    diagnostic, or treatment decision. AI-generated output is unvalidated and may
    be incorrect.

PulmoCare is a medical-imaging platform built as a **FastAPI microservice mesh**
with a cross-platform **Flutter** client. It vendors
[**MedRAX**](https://github.com/bowang-lab/MedRAX) (ICML 2025,
[arXiv:2502.02673](https://arxiv.org/abs/2502.02673)) — a LangGraph chest X-ray
reasoning agent — and exposes its report-generation tools through a structured
radiology-report API.

## What's inside

- **Auth** (Keycloak-backed), **Patients**, **Appointments**, **Médecins**,
  **Médfiles**, **Ordonnances**, **Radiologues**, **Reports** services.
- **MedRAX agent** (`medagent`) — LangGraph tool-routing over chest X-ray tools.
- **Platform**: Keycloak, Vault, Consul, APISIX gateway, RabbitMQ, Redis,
  MongoDB, and an OpenTelemetry → Prometheus / Grafana / Loki / Tempo stack.
- **Flutter** app under `apps/mobile`.

## Quickstart

The real orchestration lives at `apps/api/docker-compose.yml`:

```bash
cd apps/api
docker compose up -d
```

Per-service development uses **uv**:

```bash
cd apps/api/services/auth/app
uv sync --dev
uv run pytest
uv run ruff check . && uv run ruff format --check .
```

See [Development](development.md) for details and
[Architecture](architecture.md) for the service map.
