# PulmoCare — banner / social-preview direction

This file specifies the visual identity for the README hero and the GitHub
social-preview card (1280×640). Generate with the `brandkit` Claude skill (hero
+ social card) and `imagegen-frontend-web` / `-mobile` (wide README hero +
Flutter device mockup). Commit the output as local SVG/PNG under `assets/` so it
never rate-limits or 404s, then replace the TODO comment at the top of
`README.md`.

## Direction: clinical "control room"

- **Concept.** A calm, high-trust radiology control room — wall of soft-glowing
  monitors showing a chest X-ray, a Grafana-style telemetry panel, and a service
  mesh graph. Conveys "observable microservice platform for medical imaging,"
  not a cartoon hospital.
- **Mood.** Clinical, precise, quietly futuristic. Dark control-room ambience
  with a single focal X-ray light box.
- **Palette.** Deep slate / near-black background (`#0B1220`), clinical teal /
  cyan accents (`#14B8A6` / `#22D3EE`), soft white panel glow, one warm amber
  highlight for the "alert/insight" accent.
- **Type.** Clean grotesque (e.g. Inter / Söhne-like) wordmark "PulmoCare";
  small monospace captions for the telemetry/labels.
- **Mark.** A lung silhouette abstracted into a node-graph / waveform — bridging
  "pulmonary" and "microservice mesh + signal."
- **Must include.** A small, legible **"RESEARCH ONLY — NOT A MEDICAL DEVICE"**
  chip somewhere in the hero — the disclaimer is part of the brand, not an
  afterthought.
- **Mobile mockup.** A Flutter phone frame showing a patient/report screen, set
  beside the control-room scene for the README device row.

## Deliverables (TODO)

- [ ] `assets/hero.png` (wide README hero, ~1600×500)
- [ ] `assets/social-preview.png` (1280×640, set in Settings → Social preview)
- [ ] `assets/mark.svg` (the lung-node mark, monochrome + color)
- [ ] `assets/mobile-mockup.png` (Flutter device frame)

Status: **deferred** — image generation needs the brandkit/imagegen skills and
is gated behind the user. The README references these as a TODO.
