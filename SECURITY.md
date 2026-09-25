# Security Policy

> **RESEARCH ONLY — NOT FOR CLINICAL USE.** PulmoCare is not a medical device
> and must not process real patient data in production. Do not load real PHI
> (protected health information) into this software.

## Reporting a vulnerability

Please report security issues **privately** — do not open a public issue.

- Use GitHub's **"Report a vulnerability"** (Security → Advisories) on this repo, or
- email **ammari.ali.0001@gmail.com** with subject `PulmoCare security`.

Include: affected component/service, reproduction steps, and impact. We aim to
acknowledge within a few days.

## Scope and PHI

This is a research/demo platform. Even so, the codebase touches patient-shaped
data, so we care about:

- **PHI leakage** — patient identifiers, attributes, medical history, or images
  appearing in logs, error messages, traces, or unauthenticated responses.
- **Authorization gaps** on patient/medfiles endpoints.
- **Secret handling** — Keycloak / Vault / MinIO / RabbitMQ credentials.
- **AI output** returned without the RESEARCH-ONLY banner.

## Tooling

Automated scanning runs in CI (see `.github/workflows/`):

- **CodeQL** (python + javascript/typescript)
- **Trivy** (filesystem + IaC: `k8s/`, `ansible/`, compose; SHA-pinned action)
- **gitleaks** (secret scanning)
- **actionlint** (workflow hardening)
- **claude-code-action** PR review tuned to PHI handling

Do not commit real secrets. `.env*` files are gitignored (except `.env.example`).
