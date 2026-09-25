# PulmoCare — deploy & demo plan

PulmoCare has three deploy targets, each chosen for the workload it actually
fits. Nothing here is auto-deployed: each target is gated behind an account /
secret (see notes). **RESEARCH ONLY — not a medical device.**

| Target | What | Where | Why |
|---|---|---|---|
| Docs | mkdocs-material site | **Cloudflare Pages** | static build, free, no Node burden |
| ML demo | MedRAX Gradio agent | **Hugging Face ZeroGPU Space** | GPU-on-demand, reproducible online |
| API mesh | FastAPI services | **free container host** (see below) | needs long-running Python + sidecars |

## Why not Cloudflare Workers for the API?

Cloudflare Workers run **JS/WASM**, not long-running Python, and cannot host the
FastAPI services, the ML tools, or the Keycloak/Vault/Consul/APISIX/RabbitMQ
sidecars. So:

- **Docs only** go to Cloudflare Pages (the mkdocs build).
- The **mesh** stays a container/Kubernetes workload (`apps/api/docker-compose.yml`).
- The **live ML demo** goes to a Hugging Face ZeroGPU Gradio Space.

This split (right CF primitive per workload) is the honest engineering story.

## 1. ML demo — Hugging Face ZeroGPU Space (headline demo)

Scaffold: [`deploy/hf-space/`](hf-space/) (`app.py`, `requirements.txt`, `README.md`
with the Space YAML front-matter). It reuses MedRAX's upstream `interface.py`
(`create_demo`) + `main.py` (`initialize_agent`), wraps GPU tool calls in
`@spaces.GPU`, and shows the RESEARCH-ONLY banner.

Key facts (2026, cited below):

- ZeroGPU Spaces are **Gradio-only**; Docker/Static/Streamlit cannot schedule
  onto ZeroGPU.
- Backing hardware is **NVIDIA RTX Pro 6000 Blackwell** (`large` = 48 GB half
  GPU, default; `xlarge` = 96 GB full GPU at 2× quota).
- **Using** existing ZeroGPU Spaces is free (free account: 5 min/day quota;
  unauthenticated: 2 min/day). **Hosting your own** ZeroGPU Space requires a
  **PRO** subscription (personal) or Team/Enterprise (org).
- Supported stack: Gradio 4+, PyTorch 2.8+, Python 3.10/3.12. No `torch.compile`
  (use AoT compilation). Models go on `cuda` at module level.

Steps and secrets are in [`deploy/hf-space/README.md`](hf-space/README.md).

## 2. API mesh — free container host (honest options, 2026)

The free-container landscape shifted in 2026 (cited below):

- **Fly.io** — no longer has a free tier for new signups; it is now paid only.
- **Koyeb** — removed its free *web service* compute (free Postgres only now).
- **Render** — still offers an **always-free web service**: **750 instance
  hours / month**, 512 MB / 0.1 CPU, Docker build supported, but **spins down
  after 15 min idle** (~1 min cold start). Good enough for a single demo
  service with seeded data; not for the full multi-sidecar mesh.

Recommendation: deploy **one** representative FastAPI service (e.g. `reports`
or `auth`) to **Render** from its service Dockerfile as a "try the API"
endpoint, and keep the full mesh as `docker compose up` locally / on a VM.
Document the cold-start honestly. A `render.yaml` blueprint can pin the build;
add it per-service when a Render account/token exists.

## 3. Docs — Cloudflare Pages

`mkdocs build` output deploys to Cloudflare Pages via `cloudflare/wrangler-action`
(see `.github/workflows/docs.yml`), gated on `CLOUDFLARE_API_TOKEN` /
`CLOUDFLARE_ACCOUNT_ID` secrets.

## Sources (2026)

- HF Spaces ZeroGPU — <https://huggingface.co/docs/hub/en/spaces-zerogpu>
- HF Gradio Spaces SDK — <https://huggingface.co/docs/hub/spaces-sdks-gradio>
- ZeroGPU AoT compilation — <https://huggingface.co/blog/zerogpu-aoti>
- Render free tier — <https://render.com/docs/free>
- Render "real free tier in 2026" — <https://render.com/articles/platforms-with-a-real-free-tier-for-developers-in-2026>
- Fly.io free-tier status (2026) — <https://expresstech.io/7-fly-io-alternatives-in-2026-real-pricing-after-the-free-tier-died/>
- Koyeb vs Render — <https://www.koyeb.com/docs/compare/render-vs-koyeb>
- MedRAX — <https://github.com/bowang-lab/MedRAX> · <https://arxiv.org/abs/2502.02673>
