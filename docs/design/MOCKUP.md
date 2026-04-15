# cctalk — Screen Mockups

ASCII wireframes annotated with SwiftUI component names and interaction hints.
All dimensions assume iPhone 15 Pro (393×852pt). `|` marks safe-area edges.

Legend:
- `[component]` — SwiftUI view name in `components/`
- `{gesture}` — user interaction
- `« state »` — view state
- `· · ·` — low-emphasis / tertiary content

---

## 1. Onboarding — QRScanView

First launch. No token in Keychain → root routes here.

```
┌───────────────────────────────────┐  ← safe area top
│                                   │
│   cctalk                          │  displayLarge, textPrimary
│   Par med din Mac                 │  bodyDefault, textSecondary
│                                   │
│   ┌───────────────────────────┐   │
│   │                           │   │  [QRScannerView]
│   │   ░░░░░░░░░░░░░░░░░░░     │   │  AVCaptureVideoPreviewLayer
│   │   ░░         ░░           │   │
│   │   ░░  ▓▓▓▓▓  ░░           │   │  scan reticle (corner brackets only,
│   │   ░░         ░░           │   │   strokeStrong, 2pt, rMd radius)
│   │   ░░░░░░░░░░░░░░░░░░░     │   │
│   │                           │   │  {tap}  torch toggle, bottom-right
│   │                     ◐     │   │         SF: bolt.fill / bolt.slash
│   └───────────────────────────┘   │
│                                   │
│   Kør på din Mac:                 │  captionMeta, textTertiary
│   curl <host>:7777/qr             │  monoToken, textSecondary
│                                   │
│                                   │
│   ┌───────────────────────────┐   │
│   │    Indtast manuelt        │   │  secondary button, outline
│   └───────────────────────────┘   │  {tap} → manual entry sheet
│                                   │
└───────────────────────────────────┘
```

### States

| State | Visual |
|---|---|
| « scanning » (default) | Live camera, reticle visible |
| « detected » | Reticle flashes `accent` 200ms, haptic success, auto-dismiss |
| « invalid-qr » | Reticle flashes `statusError`, toast "Ikke en cctalk-QR" |
| « camera-denied » | Camera view replaced with SF `video.slash.fill` + CTA "Åbn Indstillinger" |
| « manual-entry » | Sheet with `Server URL` + `Token` `TextField`s, primary `Forbind` button |

### First-launch empty state
Identical to default — scanner IS the onboarding. No separate welcome screen.

---

## 2. Main — ContentView (the hero screen)

Three horizontal lanes. Swipe left/right across the ENTIRE mid-lane (or the pill row) to change session. The pill row and mic button animate in concert.

```
┌───────────────────────────────────┐
│ ● cb-m1.taile1a732.ts.net     ⚙  │  [StatusBar]    [SettingsButton]
│                                   │   statusSuccess dot, monoToken
│                                   │   {tap ⚙} → SettingsView modal
├───────────────────────────────────┤
│                                   │
│  ╭──────╮ ╭──────╮ ╭──────╮ ╭─   │  [PillPicker]
│  │ cms  │ │ whop │ │cctalk│ │ …  │  rPill, 44pt tall
│  ╰──────╯ ╰──────╯ ╰──────╯ ╰─   │  selected = accent fill
│            ^                       │  others   = strokeSubtle outline
│            selected                │  {horizontal-swipe} scroll + snap
│                                    │  {tap} select + haptic .selection
│                                    │
│                                    │
│                                    │
│              ╭─────╮               │  [MicButton]  — 200pt circle
│              │     │               │  « idle »
│              │  🎙  │               │  SF: mic.fill, textOnAccent
│              │     │               │  accent fill, 8% top-light gradient
│              ╰─────╯               │
│                                    │  {long-press} begin listening
│                                    │  {release}    send
│                                    │  {tap while error} dismiss error
│                                    │
│        Tryk og hold for at tale    │  bodyDefault, textSecondary
│                                    │  (hidden once user speaks)
│                                    │
│                                    │
├───────────────────────────────────┤
│  Historik                          │  titleSection, textPrimary
│                                    │
│  ╭───────────────────────────────╮ │  [MessageCard]
│  │ ✓ cctalk · 10:42              │ │  captionMeta + statusSuccess glyph
│  │ test fra iphone               │ │  bodyDefault, textPrimary
│  ╰───────────────────────────────╯ │  {tap} resend
│                                    │  {swipe-left} → reveal delete
│  ╭───────────────────────────────╮ │
│  │ ✓ cms · 10:38                 │ │
│  │ kør typecheck                 │ │
│  ╰───────────────────────────────╯ │
│                                    │
│  ╭───────────────────────────────╮ │
│  │ ! whop · 10:31                │ │  statusError glyph
│  │ Fejl: 503 fra host            │ │
│  ╰───────────────────────────────╯ │
│                                    │
└───────────────────────────────────┘  ← safe area bottom
```

### Mic state variations

```
« idle »                « listening »           « sending »
 ╭─────╮                 ╭─────╮                 ╭─────╮
 │     │                 │ ░░░ │  pulse 1.0↔1.05 │  ⟳  │  shimmer ring
 │  🎙  │                 │ ∿∿∿ │  waveform       │     │  SF: arrow.up.circle.fill
 │     │                 │ ░░░ │  accentMuted    │     │
 ╰─────╯                 ╰─────╯  halo            ╰─────╯

« success »             « error »
 ╭─────╮                 ╭─────╮
 │     │                 │     │
 │  ✓  │  statusSuccess  │  !  │  statusError
 │     │  fade out 200ms │     │  persists until tap
 ╰─────╯                 ╰─────╯
```

### Hero interaction: swipe between channels

The pill row and the transcript area share a `DragGesture`. On the main area:

```
     ┌──────────────────────────┐
  ←  │    swipe area (whole     │  →
     │    mid + bottom lane)    │
     └──────────────────────────┘
     {drag-horizontal > 60pt}
     → select prev/next pill
     → spring translate pill row
     → haptic .selection at snap
```

The picker itself is authoritative — the drag on the canvas is a convenience that moves `selectedIndex` by ±1 and scrolls the pill into view.

### Empty / edge states

| Situation | Treatment |
|---|---|
| No sessions available | Pill row collapses; shows single disabled chip "Ingen aktive cc-sessioner". Mic dimmed to 40% opacity, disabled. Helper text: "Start en cc-session på din Mac." |
| Offline (no Tailscale) | Status dot → `statusOffline` grey. Banner slides in from top: "Ikke forbundet til din Mac". Mic disabled. Retry chip in banner. |
| First launch after pairing | Pills + mic visible, history lane shows placeholder: "Dine seneste beskeder vises her." (textTertiary, bodyDefault, centered). |
| Mic permission denied | Mic shows SF `mic.slash.fill`, tap → sheet "Tillad mikrofon i Indstillinger" with `Åbn Indstillinger` CTA. |
| Speech recognition unavailable (da-DK not downloaded) | Inline note under mic: "Dansk tale er ikke hentet. Åbn Indstillinger → Generelt → Tastatur." with chevron. |
| Send fails | Toast from top: [Toast] with statusError, "Kunne ikke sende · Prøv igen". Row added to history with `!` prefix. |
| Send succeeds | Toast: statusSuccess, "Sendt til cctalk". 1.4s auto-dismiss. |

---

## 3. Settings — SettingsView (sheet)

Presented as `.sheet`, medium detent.

```
┌───────────────────────────────────┐
│    ▔▔▔                            │  drag indicator
│  Indstillinger              ✕     │  titleHeader    {tap ✕} dismiss
│                                   │
│  SERVER                           │  footnoteMicro, textTertiary, uppercased
│  ┌─────────────────────────────┐  │
│  │ cb-m1.taile1a732.ts.net  🔒 │  │  monoToken, {tap 🔒} reveal/edit
│  └─────────────────────────────┘  │
│                                   │
│  TOKEN                            │
│  ┌─────────────────────────────┐  │
│  │ ••••••••••••••••••••  👁    │  │  {tap 👁} toggle reveal
│  └─────────────────────────────┘  │
│                                   │
│  ┌─────────────────────────────┐  │
│  │  Par via QR                 │  │  primary button, accent fill
│  └─────────────────────────────┘  │  {tap} push QRScannerView
│                                   │
│  ─────────────────────────────    │  strokeSubtle divider
│                                   │
│  HAPTIK                           │
│  ○ Alle  ● Minimal  ○ Fra         │  [HapticsPicker] segmented
│                                   │
│  ─────────────────────────────    │
│                                   │
│  OM                               │
│  Version        1.0 (1)           │  bodyDefault · monoToken
│                                   │
│  ┌─────────────────────────────┐  │
│  │  Debug-log                  │  │  secondary button, outline
│  └─────────────────────────────┘  │  {tap} push DebugLogView
│                                   │
└───────────────────────────────────┘
```

### DebugLogView

```
┌───────────────────────────────────┐
│ ‹ Tilbage        Debug       📋   │  {tap 📋} copy entire log
│                                   │
│ 10:42:01  POST /speak  200  142ms │  monoToken, 11pt
│ 10:41:47  GET  /sessions 200  38ms│  wrap disabled, scroll-horizontal
│ 10:41:12  POST /target   200  22ms│
│ ...                               │
│                                   │
└───────────────────────────────────┘
```

Last 50 requests, color-coded by status (2xx textSecondary, 4xx statusWarn, 5xx statusError).

---

## 4. Global overlays

### Toast

```
                ┌─────────────────────┐
                │ ✓  Sendt til cctalk │   [Toast]
                └─────────────────────┘   bgElevated, rSm, shadow
                    ↑ slides from top safe-area
                    auto-dismiss 1.4s (success) / 3.0s (error)
                    {swipe-up} dismiss immediately
```

### Reconnecting banner

```
┌───────────────────────────────────┐
│  ⟳  Forbinder igen…               │   bgElevated, statusWarn text
└───────────────────────────────────┘
      fixed below status bar, height 32pt
```
