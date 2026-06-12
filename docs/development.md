# Development

## Toolchain

- **uv** for every Python service (lockfile per service).
- **ruff** for lint + format (no black, no flake8).
- **ty** for type-checking (pre-1.0; non-blocking in CI for now).
- **pytest** + **pytest-asyncio** + **httpx.AsyncClient** + **asgi-lifespan**.

## Per-service loop

Most services live under `apps/api/services/<svc>/app`:

```bash
cd apps/api/services/auth/app
uv sync --dev
uv run ruff check .
uv run ruff format --check .
uv run pytest
```

## Tests today

| Service | Tests | Status |
|---|---|---|
| `auth` | health, OpenAPI, login (success/401/422), token verify/refresh | passing |
| `patients` | health, liveness, route registration, auth gating | passing |
| `medagent` | LangGraph tool-routing (mocked model + tools) | passing (CI) |

Integration tests (testcontainers: Postgres/Mongo/RabbitMQ/Redis) and
schemathesis OpenAPI fuzzing are wired as **scheduled / manual** CI jobs only —
they need Docker and are not part of the per-push gate.

## Radiology-report endpoint

`apps/api/services/reports` exposes a structured radiology-report endpoint that
drives MedRAX's `chest_xray_report_generator` / `xray_vqa` tools and adds a
Claude (`claude-haiku-4-5`) narrative step. Every response embeds the
RESEARCH-ONLY disclaimer. The MedRAX model weights are loaded lazily and are not
required to import or test the route.

## Documentation

This site uses **mkdocs-material**. The full build aggregates per-service docs
via `mkdocs-monorepo-plugin` and renders API docstrings via
`mkdocstrings[python]`; install those from `docs/requirements.txt`:

```bash
pip install -r docs/requirements.txt
mkdocs serve
```
