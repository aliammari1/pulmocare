# License & disclaimer

!!! danger "RESEARCH ONLY — NOT FOR CLINICAL USE"
    PulmoCare is **not a medical device** and must not be used for clinical
    diagnosis or treatment. See `LICENSE` and `NOTICE` in the repository root.

## Scope

- **First-party code** (FastAPI services excluding `medagent`, the Flutter app,
  shared libraries, infra, CI, docs) is licensed **MIT** — see `LICENSE`.
- **`apps/api/services/medagent`** is a vendored copy of **MedRAX**, licensed
  **Apache-2.0**; its `LICENSE` is retained intact and is **not** relicensed.
- **Model weights and datasets** (CheXagent, TorchXRayVision, LLaVA-Med,
  MIMIC-CXR, CheXpert, …) carry their own licenses / data-use agreements and are
  **not** distributed here.

## Attribution

If you use this work academically, cite MedRAX — see `CITATION.cff`:

> Fallahpour, Ma, Munim, Lyu, Wang. *MedRAX: Medical Reasoning Agent for Chest
> X-ray.* ICML 2025. arXiv:2502.02673.
