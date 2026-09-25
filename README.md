<!-- Banner: generate assets/banner.png from BANNER.md (brandkit / imagegen). -->
<!-- Until generated, the line below 404s gracefully; commit assets/banner.png to fix. -->
![PulmoCare — research-only chest X-ray reasoning platform](assets/banner.png)

# PulmoCare

> **Open-source, self-hostable chest-X-ray AI agent** — built on
> [**MedRAX**](https://github.com/bowang-lab/MedRAX) (ICML 2025) — packaged as a
> **FastAPI microservice mesh + Flutter** client. **RESEARCH ONLY.**

[![CI](https://img.shields.io/badge/CI-uv%20%2B%20ruff%20%2B%20pytest-blue?style=flat-square)](.github/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT%20(first--party)-green?style=flat-square)](LICENSE)
[![MedRAX](https://img.shields.io/badge/agent-MedRAX%20(Apache--2.0)-orange?style=flat-square)](apps/api/services/medagent/LICENSE)
[![docs: mkdocs-material](https://img.shields.io/badge/docs-mkdocs--material-1098f7?style=flat-square)](mkdocs.yml)
[![Open in HF Spaces](https://img.shields.io/badge/%F0%9F%A4%97%20Demo-HF%20ZeroGPU%20Space-yellow?style=flat-square)](deploy/hf-space/)
[![Open in Colab](https://img.shields.io/badge/reproduce-Colab-F9AB00?style=flat-square&logo=googlecolab&logoColor=white)](deploy/colab/reproduce_chestagentbench.ipynb)
[![Star this repo](https://img.shields.io/github/stars/aliammari1/pulmocare?style=flat-square&logo=github&label=Star)](https://github.com/aliammari1/pulmocare)

## ▶ Try the live X-ray agent — no install

> **[Open in 🤗 Hugging Face Spaces](deploy/hf-space/)** ·
> **[Reproduce in Colab](deploy/colab/reproduce_chestagentbench.ipynb)**

The headline demo is a **Hugging Face ZeroGPU Gradio Space** wrapping MedRAX's
own agent UI: upload a chest X-ray, watch the LangGraph agent route across its
classification / VQA / report-generation tools, and read a structured,
research-only report. No local GPU, no setup.

<!-- Demo GIF: drop a recording at assets/demo.gif (see assets/README.md). Until
     then this 404s gracefully. -->
![PulmoCare live X-ray agent demo](assets/demo.gif)

If this is useful for your research, **[⭐ star the repo](https://github.com/aliammari1/pulmocare)**
— it helps others find a self-hostable, reproducible MedRAX deployment.

> [!CAUTION]
> **RESEARCH ONLY — NOT FOR CLINICAL USE.** PulmoCare and the bundled MedRAX
> agent are for research, education, and engineering demonstration **only**.
> This is **not a medical device**, has not been cleared by the FDA/EMA or any
> regulator, and **must not** be used for any clinical, diagnostic, or treatment
> decision for real patients. AI-generated output is unvalidated and may be
> incorrect. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

---

## What this actually is

PulmoCare is a polyglot monorepo built around an **observable FastAPI
microservice mesh**. Everything below is wired in
[`apps/api/docker-compose.yml`](apps/api/docker-compose.yml) and is the real,
runnable system — not aspiration:

| Concern | Component |
|---|---|
| Identity / SSO | **Keycloak** (+ Postgres) |
| Secrets | **Vault** |
| Service discovery | **Consul**, etcd |
| API gateway | **Apache APISIX** (+ dashboard) |
| Messaging | **RabbitMQ** |
| Cache | **Redis** |
| Data / object store | **MongoDB**, **MinIO** |
| Tracing / metrics / logs | **OpenTelemetry Collector** → **Prometheus**, Tempo, Loki, **Grafana** |
| Quality / CI | SonarQube, Jenkins, Portainer |

Application services (independent `uv` projects under
`apps/api/services/<svc>/app`): **auth**, **patients**, **appointments**,
**medecins**, **medfiles**, **ordonnances**, **radiologues**, **reports** — plus
**`medagent`**, a vendored MedRAX LangGraph agent.

The Flutter client lives under [`apps/mobile`](apps/mobile).

> [!NOTE]
> **Honest status.** The Kubernetes manifests (`apps/api/k8s`) and Ansible
> playbooks (`apps/api/ansible`) are **aspirational** — use `docker compose` for
> development. Several services and the Flutter app are works in progress.

## Architecture

```mermaid
flowchart LR
  App[Flutter app] --> GW[APISIX gateway]
  GW --> Auth[auth / Keycloak]
  GW --> Patients[patients]
  GW --> Reports[reports + AI]
  GW --> Agent[medagent / MedRAX]
  Patients -. verify token .-> Auth
  Auth & Patients & Reports & Agent -- OTel --> OTEL[Collector] --> Prom[Prometheus] --> Graf[Grafana]
```

More detail (service mesh + the MedRAX tool graph) in [`docs/`](docs/).

## Quickstart

```bash
# Full stack (Keycloak, Vault, Consul, APISIX, RabbitMQ, OTel, ...)
cd apps/api
docker compose up -d        # real orchestration lives here

# Develop a single service (toolchain: uv + ruff)
cd apps/api/services/auth/app
uv sync --dev
uv run pytest
uv run ruff check . && uv run ruff format --check .
```

## AI feature — structured radiology reports (research only)

The **reports** service exposes MedRAX's report-generation and VQA tools as a
structured endpoint:

```
POST /api/reports/ai/radiology-report
GET  /api/reports/ai/disclaimer
```

It returns structured `findings` / `impression` (and optional `xray_vqa`
answer), plus an optional plain-language narrative generated by Claude
(`claude-haiku-4-5`). **Every response carries the RESEARCH-ONLY banner** and is
intended for clinician review/edit, never for clinical use. MedRAX model weights
load lazily; with no weights the endpoint degrades gracefully instead of
failing. See [`docs/medrax.md`](docs/medrax.md).

## MedRAX attribution

`apps/api/services/medagent` is a vendored copy of **MedRAX**
([bowang-lab/MedRAX](https://github.com/bowang-lab/MedRAX), ICML 2025,
[arXiv:2502.02673](https://arxiv.org/abs/2502.02673)), redistributed under the
**Apache License 2.0** (kept intact at `apps/api/services/medagent/LICENSE`).
First-party PulmoCare code is **MIT** ([`LICENSE`](LICENSE)). See
[`NOTICE`](NOTICE) and [`CITATION.cff`](CITATION.cff).

## Demo & hosting

The headline demo is a **Hugging Face ZeroGPU Gradio Space** wrapping MedRAX's
own `interface.py` (`create_demo`). A ready-to-push scaffold lives at
[`deploy/hf-space/`](deploy/hf-space/) (`app.py` + `requirements.txt` + the Space
`README.md` with `sdk: gradio` / `hardware: zero-gpu` front-matter). It loads the
agent, wraps GPU tool calls in `@spaces.GPU`, and shows the RESEARCH-ONLY banner.

- **ML demo** → HF ZeroGPU Space (Gradio-only; *using* ZeroGPU is free, *hosting*
  needs HF PRO).
- **API mesh** → a free container host. Note (2026): **Fly.io's free tier is
  gone** and **Koyeb dropped free web compute**; **Render** still offers an
  always-free Docker web service (750 hr/month, spins down after 15 min idle) —
  good for one demo service, not the full multi-sidecar mesh.
- **Docs** → Cloudflare Pages (mkdocs build). Workers run JS/WASM, not
  long-running Python, so the FastAPI mesh is **not** a Workers fit.

Full steps, secrets, and cited 2026 sources: [`deploy/README.md`](deploy/README.md).
(Live deploys are gated behind accounts/tokens; the scaffolds are ready.)

## Reproducibility & community

- **MedRAX / ChestAgentBench** reproduction notebook stub:
  [`deploy/colab/reproduce_chestagentbench.ipynb`](deploy/colab/reproduce_chestagentbench.ipynb)
  (points at the upstream benchmark; no weights committed here).
- Suggested **GitHub topics**: `medical-imaging`, `chest-xray`, `langgraph`,
  `medrax`, `fastapi`, `microservices`, `flutter`, `radiology`, `research-only`,
  `observability`.
- Submission targets: the MedRAX ICML reproducibility track and
  **Awesome-Healthcare-Foundation-Models** (as a downstream integration), with
  the RESEARCH-ONLY disclaimer kept prominent.
- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md) ·
  [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) · [`SECURITY.md`](SECURITY.md).

## Engineering decisions

- **License scoping, not blanket MIT.** MedRAX is vendored under Apache-2.0 with
  citation obligations; relicensing it would be wrong. First-party code is MIT;
  the agent keeps its license + a `NOTICE`/`CITATION.cff`.
- **uv + ruff, no black/pip.** Every service is an isolated `uv` project; CI runs
  a real per-service matrix (`uv sync` → `ruff check`/`format --check` → `ty` →
  `pytest`) with no `|| echo` failure-swallowing.
- **Test the agent's routing, not its weights.** MedRAX tool-routing is tested
  with a scripted model + mocked tools — no GPU/weights in CI. testcontainers
  and schemathesis are scheduled/manual CI jobs.
- **Cloudflare Pages for docs only.** The FastAPI mesh + ML + Keycloak/Vault are
  container/k8s workloads, not a Workers fit; only the mkdocs site deploys to CF
  Pages (gated on secrets). The live ML demo goes to a HF Space.
- **PHI-aware AI review.** A `claude-code-action` workflow flags PHI handling in
  patients/medfiles and any AI output missing the research banner.
- **Observability that respects PHI.** Sentry (FastAPI) runs with
  `send_default_pii=False` and a `before_send` scrubber that strips request
  bodies, cookies, headers and PHI-shaped fields; OTel **GenAI spans** trace the
  MedRAX agent recording **only** tool names, token counts and latency (never
  image paths, prompts or outputs); `asgi-correlation-id` + structlog share one
  request id across logs, traces and Sentry (see
  `apps/api/services/shared/src/pulmocare_shared/observability.py`).
- **Rate-limited AI routes.** The APISIX gateway applies Redis-backed
  `limit-count` + `limit-req` to `/api/reports/ai/*` so the expensive GPU/LLM
  endpoints can't be hammered (`apps/api/config/apisix/apisix.yaml`).

## Documentation

mkdocs-material site (Mermaid diagrams, MedRAX tool graph). Build locally:

```bash
pip install -r docs/requirements.txt
mkdocs serve
```

## License

- First-party code: **MIT** — [`LICENSE`](LICENSE).
- `apps/api/services/medagent` (MedRAX): **Apache-2.0** — kept intact.
- Model weights / datasets: their own licenses; not distributed here.

**RESEARCH ONLY — not a medical device.**

## Related projects

Part of a wider open-source portfolio by [@aliammari1](https://github.com/aliammari1):

- **[readrealm](https://github.com/aliammari1/readrealm)** — open-source AI
  book-chat (one backend → Android / iOS / Flutter).
- **[JobPrep](https://github.com/aliammari1/JobPrep)** — open-source, BYOK,
  self-hostable AI interview-prep platform.
- **[github-traffic-analytics](https://github.com/aliammari1/github-traffic-analytics)**
  — keep your GitHub repo traffic past the 14-day window.

Built with **[MedRAX](https://github.com/bowang-lab/MedRAX)** (ICML 2025) — if
PulmoCare is useful, please cite MedRAX too (see [`CITATION.cff`](CITATION.cff)).

## Author

**Ali Ammari** — [@aliammari1](https://github.com/aliammari1)
