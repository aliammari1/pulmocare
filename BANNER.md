# PulmoCare — banner prompt

One crisp image-generation prompt for the README hero / GitHub social preview.
Generate with the `brandkit` skill (hero + 1280×640 social card) or
`imagegen-frontend-web` (wide hero). Commit the output locally as
`assets/banner.png` (1280×640 social card) and `assets/banner-hero.png` (wide
~1600×500 hero) so the README never rate-limits or 404s. The README already
references `assets/banner.png`.

## The prompt

> A calm, high-trust **radiology control room**, dark and quietly futuristic.
> Deep slate / near-black ambience (`#0B1220`) with a single focal light box
> glowing on the left showing a **chest X-ray**. To its right, the X-ray's lung
> silhouette abstracts into a **glowing node graph** (a LangGraph-style agent
> tool-graph) in clinical teal and cyan (`#14B8A6`, `#22D3EE`), flowing into a
> small **Grafana-style telemetry panel** with thin line charts. On the far
> right, a **Flutter phone mockup** shows a clean patient/report screen in the
> same teal/slate palette. One warm amber accent marks a single "insight" node.
> Clean grotesque wordmark **"PulmoCare"** (Inter / Söhne-like) upper area, small
> monospace captions on the panels. A small, legible chip reads
> **"RESEARCH ONLY — NOT A MEDICAL DEVICE"**. Wide cinematic composition,
> 1280×640, soft volumetric glow, no cartoon hospital clichés, no real patient
> faces, no text other than the wordmark, the caption labels, and the chip.

## Palette & type (for consistency)

- Background `#0B1220` (deep slate/near-black); accents `#14B8A6` / `#22D3EE`
  (clinical teal/cyan); one warm amber highlight; soft white panel glow.
- Wordmark: clean grotesque (Inter / Söhne-like). Captions: monospace.
- Mark concept: a lung silhouette abstracted into a node-graph / waveform —
  bridging "pulmonary" and "microservice mesh + signal."

## Deliverables

- [ ] `assets/banner.png` — 1280×640 social preview (Settings → Social preview)
- [ ] `assets/banner-hero.png` — wide README hero (~1600×500)
- [ ] `assets/mark.svg` — the lung-node mark (mono + color), optional

Status: image generation is **deferred** (needs the brandkit/imagegen skills and
is gated behind the user). The README points at `assets/banner.png`.
