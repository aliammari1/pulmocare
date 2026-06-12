---
title: PulmoCare MedRAX (Research Only)
emoji: 🫁
colorFrom: slate
colorTo: teal
sdk: gradio
sdk_version: 5.49.1
python_version: "3.12"
app_file: app.py
pinned: false
license: apache-2.0
hardware: zero-gpu
short_description: RESEARCH-ONLY chest X-ray reasoning demo (MedRAX / LangGraph)
tags:
  - medical-imaging
  - chest-xray
  - langgraph
  - medrax
  - research-only
---

# PulmoCare — MedRAX demo (RESEARCH ONLY)

> [!CAUTION]
> **RESEARCH ONLY — NOT FOR CLINICAL USE.** This Space wraps the
> [MedRAX](https://github.com/bowang-lab/MedRAX) chest X-ray reasoning agent
> (ICML 2025, [arXiv:2502.02673](https://arxiv.org/abs/2502.02673)). It is a
> research and engineering demonstration. It is **not a medical device**, is not
> cleared by any regulator, and must **never** be used for any clinical,
> diagnostic, or treatment decision. AI output is unvalidated and may be wrong.

This is the public demo for **[PulmoCare](https://github.com/aliammari1/pulmocare)** —
a research-only FastAPI microservice mesh + Flutter client built around MedRAX.
The full mesh (Keycloak, Vault, Consul, APISIX, RabbitMQ, OpenTelemetry, …) is a
container/Kubernetes workload and is **not** what runs here; this Space hosts only
the interactive MedRAX agent so the reasoning experience is reproducible online.

## How this Space is built

ZeroGPU Spaces are **Gradio-only** and run on shared NVIDIA RTX Pro 6000 Blackwell
GPUs allocated on demand. The app reuses MedRAX's upstream `interface.py`
(`create_demo`) and `main.py` (`initialize_agent`) unchanged — we only add:

- `app.py` — a thin entrypoint that initializes the agent, wraps GPU-bound work
  with `@spaces.GPU`, prepends the RESEARCH-ONLY banner, and `demo.launch()`es.
- `requirements.txt` — pinned to the ZeroGPU-supported stack (Gradio 4+, Torch
  2.8+, `spaces`).

### Deploying it (concrete steps)

1. A Hugging Face account with a **PRO** subscription (required to *host* a ZeroGPU
   Space; using existing ZeroGPU Spaces is free). See
   <https://huggingface.co/docs/hub/en/spaces-zerogpu>.
2. Create a new **Gradio** Space, pick **ZeroGPU** hardware.
3. Copy `app.py`, `requirements.txt`, and this `README.md` into the Space repo
   (the YAML front-matter above sets `sdk: gradio` + `hardware: zero-gpu`).
4. Vendor MedRAX into the Space — either `pip install` from the upstream repo in
   `requirements.txt`, or copy `apps/api/services/medagent/{interface.py,main.py,medrax/}`
   into the Space. The `system_prompts.txt` lives at `medrax/docs/system_prompts.txt`.
5. Add Space **secrets**: `OPENAI_API_KEY` (or `OPENAI_BASE_URL` for Azure/other)
   for the LangGraph reasoning model.
6. Model weights load lazily from the HF Hub on first use; keep the default tool
   set small to stay within the per-call GPU duration.

> The MedRAX vision tools (classifier, segmentation, report generator) need the
> GPU; the LangGraph orchestration runs on CPU. Only the tool calls are wrapped
> in `@spaces.GPU` so queue priority stays high.
