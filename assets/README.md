# assets/

Committed local brand assets (SVG/PNG) so the README never rate-limits or 404s.

See [`../BANNER.md`](../BANNER.md) for the single image-gen prompt (clinical
"control-room" direction). Generate with the `brandkit` /
`imagegen-frontend-web` Claude skills and commit:

- `banner.png` — 1280×640 social-preview card (the README already references it)
- `banner-hero.png` — wide README hero (~1600×500), optional
- `mark.svg` — the lung-node mark (mono + color), optional

These are **deferred** (image generation is gated behind the user).
