# cctalk — App Icon Concepts

Three directions. All obey the house rules: no skeuomorphism, no gradients beyond
a single ≤8% depth wash, no glassmorphism, monochrome + single accent.

Target rendering sizes to validate:
- **1024×1024** — App Store marketing
- **180×180** — iPhone home screen @3x
- **60×60** — Spotlight / Notification @3x
- **20×20** — Settings / list glyph @3x

All concepts use a square canvas with `22.37%` corner-mask (Apple squircle) automatically applied by Xcode — the source art must be a plain rounded rectangle or full-bleed.

---

## Concept A — "The Dot"

### Core visual
A single solid accent-blue dot, centered, diameter ≈32% of canvas, on a near-black background (`#0B0B0F`). That's it. No text, no waveform, no mic. The dot is the transmit indicator. It reads as "live", "recording", "channel open".

### Why it works
- Maximum restraint. Same energy as Things 3 (a checkbox) or Overcast (an arc).
- Instantly readable at 20pt.
- Scales to any size without losing identity.
- Accent color is the icon — reinforces app's one-accent design system.

### Scaling
| Size | Effect |
|---|---|
| 1024 | Dot ≈ 328pt, hairline inner ring `strokeSubtle` at 4pt offset for subtle depth (optional) |
| 180 | Identical proportions, still clearly a dot |
| 60 | Still a dot, background and dot still distinct |
| 20 | Reads as a blue circle on dark — perfectly legible in Settings list |

### Color
- Background: `#0B0B0F`
- Dot: `#3B82F6` (accent)
- Optional inner hairline: `#26262E` at 1pt (removed ≤60pt)

### Risk
Could be mistaken for a Bluetooth/status indicator icon at tiny sizes. Mitigation: keep the dot large (≥30% of canvas) so it reads as deliberate, not a UI glyph.

---

## Concept B — "Speech Bracket"

### Core visual
The cctalk "channel" metaphor rendered as a single XML-ish angle bracket `‹›` — two thin accent-blue chevrons on dark, forming an implied speech bubble without drawing one. It nods to the `<channel source="buddy" type="voice">` payload the app emits.

### Why it works
- Directly encodes the app's purpose (it emits a channel tag).
- Developer-native — resonates with the target user (a senior dev using Claude Code).
- Two simple strokes = scales beautifully.
- Works monochrome if the accent is later retuned.

### Layout
- Left chevron `‹` at 22% from left edge, apex pointing in.
- Right chevron `›` at 22% from right edge, apex pointing in.
- Chevron stroke width: 7% of canvas. Stroke cap: round.
- Vertical centered. Height ≈52% of canvas.

### Scaling
| Size | Effect |
|---|---|
| 1024 | Chevrons stroke ~72pt, crisp |
| 180 | Stroke ~13pt — still clearly a bracket |
| 60 | Stroke ~4pt — simplify: reduce gap between chevrons by 10% |
| 20 | At this size the two chevrons merge visually into a diamond outline — still distinctive, still "not-a-mic" |

### Color
- Background: `#0B0B0F`
- Strokes: `#3B82F6`
- No gradient, no inner shadow.

### Risk
Might read as "code" more than "voice". That's acceptable — the app IS voice-to-code.

---

## Concept C — "Signal Arc"

### Core visual
A mic's acoustic footprint abstracted: three concentric quarter-arcs in accent blue, emanating from the lower-left corner, like a radar sweep or Tailscale's ripple. No mic body. No waveform.

### Why it works
- Communicates "broadcast / send" without literal imagery.
- Echoes the pulse animation on the mic button — icon and app share a motion language (even though the icon is static).
- Asymmetric composition stands out on a home screen full of centered glyphs.
- The arcs can be re-drawn at render time per size to preserve stroke weight.

### Layout
- Three arcs, radii 30% / 55% / 80% of canvas width, origin at lower-left corner (inset 12% from edges to keep inside the squircle safe area).
- Stroke weight tapers: innermost 8%, middle 6%, outermost 4%.
- Outermost arc opacity 60% to imply distance/fade (single flat tint, not a gradient).

### Scaling
| Size | Effect |
|---|---|
| 1024 | All three arcs render crisply |
| 180 | Drop opacity step on outermost — all three fully opaque |
| 60 | Drop the outermost arc entirely — two arcs remain |
| 20 | Drop to ONE arc, thickened to 14% — reads as a simple curve |

### Color
- Background: `#0B0B0F`
- Arcs: `#3B82F6` (outermost at 60% alpha on baseline size)

### Risk
Two-arc and one-arc variants need manual tuning — not a single source asset. Mitigation: ship as an Asset Catalog image set with explicit 1x/2x/3x PNGs plus a separate 20pt variant, exported from a single Figma master with layer visibility rules.

---

## Recommendation

**Ship Concept A ("The Dot")** for v1 TestFlight. It is the lowest-risk, most on-brand option and costs almost nothing to produce. Concept B is the stronger second choice once the app gains a public identity. Concept C is a motion-icon idea that belongs to a future animated app-icon experiment (iOS 18+ behavior).
