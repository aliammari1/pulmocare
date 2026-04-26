# Open Source Growth Plan

This plan converts the repository review into an actionable backlog for Pulmocare.

## Quick wins

- Add architecture diagrams for backend services, AI model flow, mobile clients, and report storage.
- Add OpenAPI documentation for public backend endpoints.
- Add backend tests with pytest and FastAPI TestClient.
- Add Flutter tests for critical mobile flows.
- Add dependency scanning and CI quality gates.
- Document privacy, retention, and healthcare-data handling assumptions.

## Bugs and bad practices to watch

- Unvalidated request and response payloads at AI and report APIs.
- Client-side exposure of service keys or environment-specific configuration.
- Missing graceful fallback when OCR, transcription, or model inference fails.
- Tight coupling between model code, API handlers, and storage.
- Silent failures in scheduling, report uploads, or offline synchronization.

## Star growth strategy

1. Add a short demo video using synthetic medical data.
2. Publish a clear local setup path with seeded demo data.
3. Add `good first issue` tasks for docs, UI states, translations, and tests.
4. Add screenshots for report creation, image analysis, and scheduling.
5. Write a technical article about building privacy-conscious AI healthcare tooling.

## Trending-library opportunities

- Use Pydantic-AI-style schema validation for structured AI outputs.
- Use Polars for high-performance analytics on anonymized metrics.
- Use Data-Formulator-style dashboards for patient/report insights.
- Use FastMCP-style boundaries for tool/model integrations.

## Suggested next PRs

- Add CI for backend and Flutter tests.
- Add `docs/ARCHITECTURE.md` with service boundaries and data flow.
- Add API validation tests for high-risk endpoints.
