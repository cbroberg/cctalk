# cctalk — Design System

> A calm, monochrome voice-relay app. One primary action per screen. One accent.
> Reference: Overcast, Things 3, Apple Voice Memos, Castro.

---

## 1. Accent

**Primary accent: `#3B82F6` — `accentBlue`** (SF-Blue-adjacent, slightly cooler).

Chosen for:
- Apple-native feel without being literal system blue
- High legibility in dark mode (AA contrast on `#0B0B0F`)
- Works as both fill and outline
- Desaturated enough that it does not compete with the green/red status colors

Semantic names used throughout the code:

| Semantic token | Light | Dark | Usage |
|---|---|---|---|
| `accent` | `#2563EB` | `#3B82F6` | Primary action (mic idle, selected pill, CTAs) |
| `accentMuted` | `#DBEAFE` | `#1E3A8A` | Selected pill background glow, focus rings |
| `accentPressed` | `#1D4ED8` | `#60A5FA` | `:active` state on accent surfaces |

No gradients except a single 8% linear overlay on the mic button (top-highlight, bottom-shade) for subtle depth.

---

## 2. Color Palette

### Backgrounds (tiered)

| Token | Light | Dark | Purpose |
|---|---|---|---|
| `bgBase` | `#F7F7F8` | `#0B0B0F` | Main window |
| `bgElevated` | `#FFFFFF` | `#16161C` | Cards, modals, history rows |
| `bgOverlay` | `rgba(0,0,0,0.04)` | `rgba(255,255,255,0.06)` | Hover/pressed wash |
| `bgScrim` | `rgba(0,0,0,0.4)` | `rgba(0,0,0,0.6)` | Modal scrim |

### Text

| Token | Light | Dark |
|---|---|---|
| `textPrimary` | `#0B0B0F` | `#F5F5F7` |
| `textSecondary` | `#44444C` | `#A1A1AA` |
| `textTertiary` | `#7A7A85` | `#6B6B74` |
| `textOnAccent` | `#FFFFFF` | `#FFFFFF` |

### Borders / dividers

| Token | Light | Dark |
|---|---|---|
| `strokeSubtle` | `#E5E5EA` | `#26262E` |
| `strokeStrong` | `#C7C7CC` | `#3A3A42` |

### Status

| Token | Light | Dark | Usage |
|---|---|---|---|
| `statusSuccess` | `#16A34A` | `#22C55E` | Delivery check, Tailscale online dot |
| `statusError` | `#DC2626` | `#F87171` | Mic error, failed send |
| `statusWarn` | `#D97706` | `#FBBF24` | Stale session, reconnecting |
| `statusOffline` | `#7A7A85` | `#6B6B74` | Tailscale offline dot |

All status colors pass WCAG AA (≥4.5:1) on both `bgBase` tiers.

---

## 3. Typography

SF Pro, system-provided. No custom font files. All type ships with `Font.Design` hints so it picks up Dynamic Type automatically.

| Role | Font | Size | Weight | Tracking | Leading |
|---|---|---|---|---|---|
| `displayLarge` | SF Pro Display | 34 | `.bold` | +0.37 | 41 |
| `titleHeader` | SF Pro Display | 22 | `.semibold` | +0.35 | 28 |
| `titleSection` | SF Pro Display | 17 | `.semibold` | -0.41 | 22 |
| `bodyDefault` | SF Pro Text | 17 | `.regular` | -0.41 | 22 |
| `bodyEmphasis` | SF Pro Text | 17 | `.medium` | -0.41 | 22 |
| `calloutLive` | SF Pro Text | 20 | `.regular` | -0.32 | 25 |
| `captionMeta` | SF Pro Text | 13 | `.regular` | -0.08 | 18 |
| `footnoteMicro` | SF Pro Text | 11 | `.medium` | +0.07 | 13 |
| `monoToken` | SF Mono | 13 | `.regular` | 0 | 18 |

`calloutLive` is used for the live transcription directly under the mic. It is the emotional focal point when listening — one size up from body, relaxed.

All text uses `.dynamicTypeSize(...DynamicTypeSize.accessibility2)` as the default upper bound; mic button layout reflows above that.

---

## 4. Spacing (4pt grid)

| Token | pt |
|---|---|
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 24 |
| `xxl` | 32 |
| `huge` | 48 |

Screen edge insets: `lg` (16pt) on iPhone 13-mini class, `xl` (24pt) on Pro-Max class via `.safeAreaPadding`.

---

## 5. Radius

| Token | pt | Used for |
|---|---|---|
| `rXs` | 4 | Inline chips (status dot pill) |
| `rSm` | 8 | Small buttons, toast |
| `rMd` | 12 | History cards, text fields |
| `rLg` | 16 | Modals |
| `rPill` | 999 | Pill picker items |
| `rCircle` | `.circle` (50%) | Mic button |

---

## 6. Animation

Exposed as static constants so they are composable and consistent.

| Token | Definition | Used for |
|---|---|---|
| `springSnappy` | `.spring(response: 0.28, dampingFraction: 0.82)` | Pill select, toast enter |
| `springDefault` | `.spring(response: 0.35, dampingFraction: 0.7)` | All state transitions |
| `springBouncy` | `.spring(response: 0.45, dampingFraction: 0.6)` | Mic scale on press |
| `easeQuick` | `.easeOut(duration: 0.18)` | Fade out toast, success check |
| `easeGentle` | `.easeInOut(duration: 0.24)` | Color cross-fade on mic |
| `pulse` | `.easeInOut(duration: 1.1).repeatForever(autoreverses: true)` | Listening pulse scale 1.00 → 1.05 |
| `shimmer` | `.linear(duration: 1.4).repeatForever(autoreverses: false)` | Sending-state ring sweep |

Motion is limited. Any view not in the list above should use `springDefault`.

**Reduced Motion**: `@Environment(\.accessibilityReduceMotion)` disables `pulse`, `shimmer`, and the bouncy spring — swaps to `easeQuick` opacity cross-fade.

---

## 7. Haptics

Maps each user-visible event to a concrete haptic. Implemented via a tiny `Haptics` helper in `Theme.swift`.

| Interaction | Haptic | Rationale |
|---|---|---|
| Pill selection (swipe or tap) | `UISelectionFeedbackGenerator.selectionChanged()` | Light, confirms discrete choice |
| Mic press begin (idle → listening) | `UIImpactFeedbackGenerator(.medium).impactOccurred()` | Commit feel |
| Mic release (listening → sending) | `UIImpactFeedbackGenerator(.soft).impactOccurred(intensity: 0.6)` | Lighter, signals hand-off |
| Send success | `UINotificationFeedbackGenerator().notificationOccurred(.success)` | System-learned "done" |
| Send failure | `UINotificationFeedbackGenerator().notificationOccurred(.error)` | Clear distinct buzz |
| Swipe-to-delete row armed | `UIImpactFeedbackGenerator(.rigid).impactOccurred(intensity: 0.5)` | Confirms threshold crossed |
| QR capture | `UINotificationFeedbackGenerator().notificationOccurred(.success)` | Onboarding payoff |
| Long-press history row | `UIImpactFeedbackGenerator(.medium).impactOccurred()` | Matches system long-press |

Respect `UIAccessibility.isReduceMotionEnabled` **and** a future `Settings.hapticsLevel` (full / minimal / off) — the `Haptics` helper gates on both.

---

## 8. Accessibility

- **Minimum hit target**: 44×44pt. Pills pad to 44pt height even when text is short. The 200pt mic dwarfs this easily.
- **Dynamic Type**: supported up to `.accessibility2` for stacked body text. Above that, history rows stack label/meta vertically; the mic button anchors to `min(screenHeight * 0.32, 200pt)`.
- **VoiceOver labels**:
  - Mic button: label `"Tal besked"`, value reflects state (`"Klar"`, `"Lytter"`, `"Sender"`, `"Sendt"`, `"Fejl, dobbelttap for detaljer"`), hint `"Dobbelttap og hold for at diktere"`.
  - Pills: label `"<sessionName>, <state>"`, value `selected ? "valgt" : ""`, hint `"Dobbelttap for at skifte session"`.
  - History row: composed label `"Sendt til <session> klokken <time>, besked: <text>"`, custom actions for Resend og Slet.
  - Tailscale dot: `accessibilityLabel("Tailscale: online")` / `"offline"`.
- **Contrast**: all text tokens ≥4.5:1 on their intended background. Accent-on-background 5.1:1 in dark, 4.8:1 in light.
- **Focus order**: status dot → pills → mic → transcript → history.
- **Reduced Motion**: see §6.
- **Reduced Transparency**: `bgOverlay` wash becomes opaque `strokeSubtle`.
- **Increase Contrast**: swap `strokeSubtle` → `strokeStrong`, dim `textTertiary` → `textSecondary`.

---

## 9. Iconography

SF Symbols only. Weight `.regular`, scale `.medium` unless noted.

| Concept | Symbol |
|---|---|
| Mic idle | `mic.fill` |
| Mic listening | `waveform` (animated via `.symbolEffect(.variableColor.iterative)`) |
| Mic sending | `arrow.up.circle.fill` |
| Mic success | `checkmark.circle.fill` |
| Mic error | `exclamationmark.circle.fill` |
| Settings | `gearshape` |
| QR | `qrcode.viewfinder` |
| Tailscale online | `circle.fill` (sized 8pt, statusSuccess) |
| Resend | `arrow.up.forward` |
| Delete | `trash` |
| Copy | `doc.on.doc` |
| Close modal | `xmark` |

---

## 10. File layout

```
docs/design/
├── DESIGN.md          ← this file
├── MOCKUP.md          ← wireframes
├── APP_ICON.md        ← icon concept directions
└── components/
    ├── Theme.swift    ← all tokens above as Swift constants
    ├── PillPicker.swift
    ├── MicButton.swift
    ├── MessageCard.swift
    ├── Toast.swift
    └── QRScannerView.swift
```
