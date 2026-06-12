# assets/

Committed local brand assets (SVG/PNG) so the README never rate-limits or 404s.

See [`../BANNER.md`](../BANNER.md) for the single image-gen prompt (clinical
"control-room" direction). Generate with the `brandkit` /
`imagegen-frontend-web` Claude skills and commit:

- `banner.png` — 1280×640 social-preview card (the README already references it)
- `banner-hero.png` — wide README hero (~1600×500), optional
- `mark.svg` — the lung-node mark (mono + color), optional
- `demo.gif` — short screen recording of the HF Space agent run (upload X-ray →
  tool routing → research-only report). Referenced by the README "▶ Try the live
  X-ray agent" hero; record from the deployed Space (`deploy/hf-space/`).

These are **deferred** (image/recording generation is gated behind the user).
