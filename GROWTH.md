# GROWTH.md — discoverability & community kit (PulmoCare)

Internal, ready-to-fire kit for making PulmoCare **discoverable, useful to
others, and shareable**. Nothing here changes the product; it's positioning +
submission drafts. The repo stays **RESEARCH ONLY — not a medical device**, and
that disclaimer must remain prominent in every post below.

> **One-liner:** Open-source, self-hostable chest-X-ray AI agent — built on
> MedRAX (ICML 2025) — packaged as a FastAPI microservice mesh + Flutter.
> Research only.

---

## 1. GitHub repo metadata (set on github.com → repo → ⚙ / "About")

**About (≤ 350 chars, keyword-rich):**

> Open-source, self-hostable chest-X-ray AI agent built on MedRAX (ICML 2025).
> A FastAPI microservice mesh + Flutter client with a LangGraph radiology agent,
> APISIX gateway, Keycloak/Vault, and full OpenTelemetry observability.
> RESEARCH ONLY — not a medical device.

**Topics (8–12, exact-match search terms; limit is 20):**

```
medical-imaging
chest-xray
langgraph
ai-agent
fastapi
flutter
healthcare-ai
self-hosted
medrax
radiology
microservices
observability
```

**Website field:** point at the deployed mkdocs site (Cloudflare Pages) once live.

**Also:** add a social-preview image (Settings → Social preview) using
`assets/banner.png`, and pin the repo on the profile.

---

## 2. Unique hook

The wedge vs. raw MedRAX: **MedRAX is a research agent + Gradio demo; PulmoCare
is a *deployable system* around it** — a real microservice mesh (APISIX,
Keycloak, Vault, Consul, RabbitMQ, OTel→Grafana), a structured
`/api/reports/ai/radiology-report` endpoint, PHI-aware observability, rate
limiting, and a cross-platform Flutter client. "If you want to *run* MedRAX as a
service, not just a notebook, start here."

The headline demo is the **HF ZeroGPU Gradio Space** (`deploy/hf-space/`) — the
"no install, try it now" magnet — plus a Colab reproducibility notebook.

---

## 3. r/MachineLearning [P] post (reproducibility framing)

> **Title:** [P] PulmoCare — a self-hostable, observable deployment of MedRAX
> (ICML'25 chest-X-ray agent): FastAPI mesh + Flutter + live HF Space
>
> **Body:**
> MedRAX ([bowang-lab/MedRAX](https://github.com/bowang-lab/MedRAX),
> arXiv:2502.02673) is a great LangGraph chest-X-ray reasoning agent, but it
> ships as a research repo + Gradio demo. I wanted to see what it takes to run it
> as an actual *system*, so I built PulmoCare around it:
>
> - the MedRAX agent is **vendored unmodified** (Apache-2.0, license + NOTICE +
>   CITATION kept intact) and exposed through a structured radiology-report API;
> - around it: a FastAPI microservice mesh (auth/Keycloak, patients, reports,
>   …), APISIX gateway with Redis-backed rate limits on the AI routes, and full
>   OpenTelemetry tracing/metrics/logs into Prometheus/Grafana/Loki/Tempo;
> - **PHI-aware observability**: Sentry with PII off + a PHI scrubber, and OTel
>   GenAI spans that record only tool names / token counts / latency — never
>   image paths, prompts, or model output;
> - a cross-platform Flutter client;
> - a **live HF ZeroGPU Space** to try the agent with no install, and a Colab
>   notebook that points at the upstream ChestAgentBench for reproduction.
>
> **Strictly RESEARCH ONLY — not a medical device, not for any clinical use.**
> Feedback on the deployment/observability design welcome. Repo + Space links in
> the comments.
>
> *(Seed first comment with the GitHub + HF Space + Colab links; reply within the
> hour; post Tue–Thu ~13:00–16:00 UTC. Build subreddit karma first.)*

---

## 4. Hugging Face Space share

- Publish `deploy/hf-space/` as a ZeroGPU Gradio Space (hosting needs HF PRO;
  *using* ZeroGPU is free). Front-matter already sets `sdk: gradio` /
  `hardware: zero-gpu` and the RESEARCH-ONLY banner.
- Tag the Space: `medical-imaging`, `chest-xray`, `langgraph`, `agent`,
  `radiology`, `medrax`.
- Link the Space ⇄ the GitHub repo (both directions) and add the "Open in HF
  Spaces" badge (already in the README).
- Share in the HF "i-made-this" / community-spaces channel with the same
  research-only framing.

---

## 5. Awesome-list / directory submissions

- **[Awesome-Healthcare-Foundation-Models](https://github.com/Jianing-Qiu/Awesome-Healthcare-Foundation-Models)**
  — submit PulmoCare as a *downstream integration / deployment* of MedRAX (not a
  new model), under a "tools / deployments" framing, RESEARCH-ONLY noted.
  Suggested entry: *PulmoCare — self-hostable deployment of MedRAX (FastAPI mesh
  + Flutter + HF Space).*
- **MedRAX ICML reproducibility track** — submit the Colab reproduction
  notebook (`deploy/colab/reproduce_chestagentbench.ipynb`).
- **awesome-langchain / awesome-llm-apps** — under "agents", as a LangGraph
  medical-imaging agent deployment.
- **awesome-fastapi**, **awesome-flutter** — as a real-world microservice-mesh /
  cross-platform example.
- **awesome-selfhosted** is a *poor* fit (clinical/PHI tooling) — skip to keep
  the research-only line clean.

---

## 6. MedRAX courtesy backlink ("built with")

MedRAX is the foundation and carries citation obligations. Keep the credit
visible and reciprocal:

- README H1 + "Related projects" footer link to `bowang-lab/MedRAX` and ask
  downstream users to cite MedRAX (done; see `CITATION.cff` / `NOTICE`).
- When sharing, lead with "built on MedRAX (ICML'25)" — it borrows the upstream
  project's credibility *and* is the honest framing.
- Optional courtesy: open a small PR / issue on MedRAX offering to list PulmoCare
  under a "Built with MedRAX / community deployments" section, if they want one.

---

## 7. Checklist

- [ ] Set About + 8–12 topics + social preview on GitHub.
- [ ] Generate `assets/banner.png` + `assets/demo.gif` (gated on user).
- [ ] Publish the HF ZeroGPU Space; cross-link with the repo.
- [ ] Submit to Awesome-Healthcare-Foundation-Models + MedRAX repro track.
- [ ] Post the r/MachineLearning [P] thread (good timing, seed first comment).
- [ ] Keep the RESEARCH-ONLY disclaimer prominent everywhere.
