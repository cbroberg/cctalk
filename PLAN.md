# cctalk-ios — PLAN.md

Native iOS app til stemme-relay fra iPhone/AirPods til valgfri cc-session.

## Vision

Gå rundt med AirPods. Tryk én gang. Skift cc-session på swipe. Tal. Afslut. Tekst lander i den cc-session du valgte, som `<channel source="buddy" type="voice">`. Ingen Shortcuts-piksel-nusseri. Apple-native UX.

## Arkitektur-beslutning: cloud-buddy?

### Kort svar: ikke i v1.

| Behov | Løsning i v1 | Løsning hvis cloud |
|---|---|---|
| Tilgang udefra | Tailscale (virker allerede) | cloud-buddy relay |
| Auth | Token i Keychain (QR fra Mac) | email/pw + OAuth |
| App Store approval | Ingen — TestFlight intern | Nødvendig med demo-login |
| Multi-device picker | `~/.buddy/channels/*.json` direkte | Cloud-database |

TestFlight intern = ingen Apple-review krævet, ingen login-krav for approvers. Cloud-buddy er **scope creep** indtil én af disse er sand:
- Du vil offentliggøre i App Store
- Andre brugere skal bruge app'en
- Du arbejder på netværk hvor Tailscale er blokeret

### Anbefaling: **cloud-buddy udskydes til Fase 3** (eller droppes helt).

## Fase 1 — MVP (lokal, TestFlight intern)

### Scope
- **Onboarding**: QR-scan af config fra Mac (`cctalk://config?baseUrl=...&token=...`) → gemt i Keychain
- **Session picker**: horisontal pill-række øverst, auto-refreshes hvert 10s fra `/sessions`
- **Mic**: stor knap midt på skærmen, états `idle → listening → sending → success/error`
- **Live transkription**: `SFSpeechRecognizer` da-DK, on-device, partial results vist mens man taler
- **Send**: auto på stop, POST `/speak` med valgt target
- **Delivery confirmation**: toast med ✓ + session-navn eller rød fejl-toast

### Explicit out of scope
- AirPods stem-gesture
- Baggrundslyd (screen-off lytning)
- Cloud auth / login-skærm
- History / resend
- Siri Shortcuts

### Bundle + identity
- Bundle ID: **`app.webhouse.cctalk`** (matcher cms-mobile konvention)
- Team ID: `7NAG4UJCT9`
- Min iOS: **17.0** (SFSpeechRecognizer on-device dansk + SwiftUI moderne API'er)
- Orientering: portrait-only
- iPad: **nej** i v1

## Fase 1.5 — To-vejs voice ("cc taler tilbage")

**Mål**: Afløser CC Remote Control. Gå en tur med AirPods, tal til cc i en valgt session, cc svarer højt med native TTS. Ingen skærm nødvendig efter første tap.

### Arkitektur

```
cc-turn → buddy-hook → buddy filter → cctalk server → SSE push → iPhone → AVSpeechSynthesizer → AirPods
```

1. **Buddy-hook**: buddy ser allerede hver cc-turn. Tilføjes en filter-funktion der extract'er "speech-worthy" indhold:
   - DROP: code blocks (```), tool_use payloads, tool_result, thinking, filpaths, diffs
   - KEEP: prose-paragrafer, spørgsmål, status-sætninger, konklusioner
   - Output: 1–3 korte sætninger (maks ~200 ord)
2. **Buddy POST til cctalk**: nyt endpoint `POST /say { text, targetSession }` — samme auth som resten
3. **cctalk server push**: ny SSE-stream `GET /stream?session=<id>&token=<t>` — iPhone holder én persistent forbindelse
4. **iPhone mod.**: TTSService wrapper omkring `AVSpeechSynthesizer` (da-DK voice, on-device, gratis)
5. **Background audio**: Info.plist → `UIBackgroundModes: audio`, så app'en holder mic+TTS aktiv med skærm slukket i AirPods-scenariet

### Hvorfor on-device TTS (AVSpeechSynthesizer)

- ✅ Matcher Christians "undgå API-tunge løsninger"-regel
- ✅ Nul latency — lyd starter inden for 100ms
- ✅ Virker offline (vigtigt hvis Tailscale dropper midlertidigt på en gåtur)
- ✅ Gratis — ingen ElevenLabs/OpenAI-cost
- ✅ Dansk stemme tilgængelig (Siri-kvalitet i iOS 17+)
- ❌ Mindre "natural" end ElevenLabs, men fuldt forståelig til prose

### Remote-control-funktioner

Via `MPRemoteCommandCenter` og `AVAudioSession`:
- Long-press AirPod-stem → start ny diktering (pauser nuværende TTS automatisk)
- Double-tap stem → skip nuværende TTS-besked
- Triple-tap stem → repeat sidste besked

### Walking-flow (end-to-end)

1. AirPods i ørerne, app låst i baggrund
2. Long-press stem → mic starter, TTS pauser
3. "Kør tests i cms og fortæl hvis der er fejl" → sendes til valgt session
4. cc arbejder (få sekunder til få minutter)
5. Når cc svarer med tekst-indhold → buddy filter → SSE push → AirPods siger: "Alle 247 tests passerer. Build-tid 12 sekunder."
6. Fortsætter gåturen, long-press for næste kommando

### Ekstra features

- **Session-switch via stemme**: "Skift til whop" → app swipe'er til whop-pill og parser bekræftelse
- **Stille-mode**: toggle i Settings der sender mic-tekst men IKKE læser svar højt (fx møder, tog)
- **Lyd-history**: replay af sidste 20 TTS-beskeder med timestamp, swipe-to-resend på tap

### Server-ændringer (cctalk)

```js
app.post('/say', async (c) => {
  // samme auth
  // body: { text, target }
  // push via EventEmitter til connected SSE-clients filtered by target session
});

app.get('/stream', async (c) => {
  // SSE stream, token i querystring (EventSource understøtter ikke custom headers)
  // emit: data: {"type":"say","text":"...","target":"..."}
});
```

### Buddy-ændringer (ny package i buddy-mono)

`packages/speech-filter` — pure function: `extractSpeech(turn: AssistantTurn): string[]`

Integration i buddy-hook: efter flag-review færdig → kald `extractSpeech(turn)` → for hver sætning → POST til lokal cctalk-server med target = buddy-channel's cwd.

### Fase 1.5 — Out of scope

- Multi-language (kun dansk i v1)
- Voice cloning af Christians stemme
- Cloud TTS
- Interrupting TTS mid-response (altid hele sætninger)

### Milestones

| # | Task | Tid |
|---|---|---|
| 1.5-M1 | `AVSpeechSynthesizer` wrapper + simpelt tap-to-speak i Settings-debug | 30m |
| 1.5-M2 | cctalk `/say` endpoint + SSE `/stream` | 1h |
| 1.5-M3 | iPhone SSE-lytter + auto-play af indkomne beskeder | 1h |
| 1.5-M4 | Background audio mode + lock-screen playback | 45m |
| 1.5-M5 | Buddy speech-filter package (drop code/tool calls) | 1.5h |
| 1.5-M6 | Buddy-hook integrerer filter + POST til cctalk | 1h |
| 1.5-M7 | `MPRemoteCommandCenter` til AirPods-gestures | 1h |
| 1.5-M8 | End-to-end gåtur-test | 30m |

**Total: ~7 timer**

### Acceptkriterier

- Tager AirPods på → går en tur → siger "status på cms" → hører cc svar på dansk i AirPods
- Kan skifte session uden at tage telefonen op (via stemme eller stem-gestures)
- App'en overlever skærm-lås i mindst 30 min med aktiv SSE-forbindelse
- Buddy filter misser ikke substantive svar men inkluderer aldrig code/diffs/paths i TTS-output

## Fase 2 — Polish

- **AirPods long-press** → open app + auto-start mic (kræver `AVAudioSession.setCategory(.playAndRecord, mode: .voiceChat)`)
- **Background audio mode** → `UIBackgroundModes: audio` i Info.plist, app holder mic aktiv med skærm slukket
- **History-liste** — sidste 20 beskeder med timestamp + target, tap for re-send
- **Siri Shortcut "Tal til cc"** — native `AppIntent` for hands-free launch
- **Undo/rediger** — vis transkription + rediger-knap før send (toggleable i settings)

## Fase 1.75 — QR-pairing via buddy dashboard

Hvis buddy får indbygget QR-generator i sit dashboard ("Enheder → Tilføj cctalk iPhone"), kan cctalk-app'en parre direkte fra buddy web UI. Eliminerer behovet for at bruge Mac-terminalen til at vise QR. Let at lave — buddy har allerede auth + ved hvilken `cctalk`-server der kører lokalt. Samlet: ~1 times arbejde i buddy.

## Fase 3 (udskudt) — cloud-buddy

Kun hvis én af scenarierne ovenfor trigger behov. Skitse:
- `cctalk.webhouse.app` Hono server (Fly.io, arn)
- NextAuth magic-link + email/pw
- WebSocket tunnel: lokal `cctalk` server registrerer hos cloud-buddy og får pusht indgående beskeder
- Dashboard: "dine Macs", "aktive sessions", "sidste aktivitet", QR-udgiver
- iOS app tilføjer "Login"-skærm ved siden af QR-scan

## Tech stack

### iOS app
- Swift 5.10, Xcode 16+
- SwiftUI (ingen UIKit-bro)
- `SFSpeechRecognizer` + `AVAudioEngine`
- `URLSession` async/await
- `Keychain` via `Security.framework` (ingen tredjepartslib)
- `AVCaptureMetadataOutput` til QR-scan
- Ingen CocoaPods, ingen SwiftPM-deps (ren stdlib)

### Server (eksisterende `cctalk`)
Tilføjes:
- `GET /qr` — returnerer PNG QR af `cctalk://config?baseUrl=<encoded>&token=<encoded>`
  - Deps: `qrcode` npm-pakke
- `GET /sessions` — udvides med `lastSeen` timestamp
- (Optional Fase 2) WebSocket `/stream` for delivery-ack live

### Distribution — identisk med cms-mobile
- **fastlane** + ASC API Key (`AuthKey_62YPBGB98M.p8`, Admin)
- `fastlane beta` lane: build → signér → upload TestFlight
- Intern testergruppe: kun cb@webhouse.dk (+ eventuelle andre devices)
- Ingen review → app dukker op på din iPhone inden for ~10 min via TestFlight-app
- Hver gang vi opdaterer: én kommando → ny build på din telefon

## App UX — design brief til design-agent

### Vibe
Apple-native, rolig, mørk. Én accentfarve (blå), ellers monokrom. Reference: Overcast, Things 3, Voice Memos.

### Hovedskærm (én skærm, tre lag)

**Top (8% af skærm):**
- Tailscale-status dot (grøn/rød) + server-navn mikroskopisk tekst
- Horisontal scrollbar med session-pills — valgt pill har solid fill, andre har outline
- Pills genereres fra `/sessions`, opdateres auto
- Tap pill = skift target (gem til server via `/target`)

**Midte (60% af skærm):**
- Massiv cirkulær mic-knap (~200pt)
- Farve-states:
  - Idle: accentfarve fyldning
  - Listening: pulserende med glow (haptic tap)
  - Sending: spinner
  - Success: grøn ✓ (200ms fade)
  - Error: rød ! (stay until tap)
- Under knappen: live transkription, grå mens der tales, sort når finaliseret

**Bund (32% af skærm):**
- Sidste 3 sendte beskeder, hver som en kort-række:
  - `✓ cctalk · 10:42 · "test fra iphone"`
  - Swipe venstre = slet fra listen
  - Tap = resend med samme target

### Settings (modal fra gear-ikon)
- Server URL (masked, unlock-toggle)
- Token (masked, reveal-toggle)
- "Pair via QR" stor knap → åbner scanner
- Version + build-nummer
- Debug log (sidste 50 requests, kopiér-knap)

### Onboarding (first launch)
- Fullscreen QR-scanner med overlay
- Tekst: "Scan QR på din Mac: `http://<magic-dns>:7777/qr`"
- Fallback-knap "Indtast manuelt" → tekstfelter
- Efter scan: auto-fetch `/sessions`, grøn check, naviger til hovedskærm

### Typografi
- SF Pro Display — headers
- SF Pro Text — body
- Monospaced for tokens/URLs (SF Mono)

### Animation
- `.spring(response: 0.35, dampingFraction: 0.7)` på alle state-skift
- Pulse på aktiv mic: `.repeatForever(autoreverses: true)` scale 1.0 ↔ 1.05
- Haptic: `.selection` ved pill-skift, `.impact(.medium)` ved mic tap, `.notification(.success)` ved levering

### Accessibility
- VoiceOver labels på alt
- Dynamic Type support
- Minimum kontrast 4.5:1

## Onboarding-flow (detaljeret)

1. Bruger installerer app via TestFlight
2. Åbner app → møder QR-scanner
3. På Mac: `curl http://cb-m1.taile1a732.ts.net:7777/qr > qr.png && open qr.png` (eller vi viser QR direkte i terminal)
4. iPhone scanner → URL-scheme `cctalk://config?baseUrl=...&token=...` → app parser + gemmer i Keychain
5. App fetcher `/sessions`, viser pills, klar

## Server-ændringer (cctalk)

### Nyt endpoint: `GET /qr`

```js
app.get('/qr', async (c) => {
  if (!requireAuth(c)) return c.json({ error: 'unauthorized' }, 401);
  const baseUrl = `http://${c.req.header('host')}`;
  const deepLink = `cctalk://config?baseUrl=${encodeURIComponent(baseUrl)}&token=${encodeURIComponent(AUTH_TOKEN)}`;
  const png = await QRCode.toBuffer(deepLink, { width: 512 });
  return new Response(png, { headers: { 'content-type': 'image/png' } });
});
```

Dep: `npm i qrcode`

### CLI-hjælper: `scripts/show-qr.sh`
Åbner QR'en i Preview på Mac så man let kan scanne.

## Milestones (MVP)

| # | Task | Tid | Acceptkrit. |
|---|---|---|---|
| M1 | Xcode-projekt scaffolded, tom SwiftUI-app bygger | 30m | Kører i Simulator, viser "Hello cctalk" |
| M2 | QR-scanner + Keychain-persist | 45m | Scan test-QR → config gemt, overlever relaunch |
| M3 | Sessions-fetch + pill-picker | 45m | Viser live sessions, valg persister via `/target` |
| M4 | SFSpeechRecognizer + live transkript | 1h | Partial text vises mens man taler, finaliseres på stop |
| M5 | POST `/speak` + success-toast | 30m | Send → `<channel>` lander i cc-session |
| M6 | fastlane setup + første TestFlight-upload | 1.5h | App på Christians iPhone via TestFlight |
| M7 | Design-pass på baggrund af design-agent output | 1h | Alle elementer fra design brief implementeret |

**Total estimeret MVP: ~6 timer aktiv udvikling.**

## Apple App Store-overvejelser

### Fase 1 (TestFlight intern) — hvad vi bruger
- **Ingen review** — interne testere tilføjes via Apple ID, app er installérbar øjeblikkeligt
- Op til 100 interne testere pr. app
- Build udløber efter 90 dage → ny build fornyer
- Krav til Info.plist:
  - `NSMicrophoneUsageDescription`: "cctalk bruger mikrofonen til at diktere beskeder til dine aktive Claude Code sessions. Du kan f.eks. sige 'fix linter-errors i auth.ts', som sendes til den session du har valgt."
  - `NSSpeechRecognitionUsageDescription`: "cctalk bruger dansk talegenkendelse på enheden til at konvertere din stemme til tekst, der sendes til en valgt Claude Code session på din egen Mac."

### Fase 2 (TestFlight ekstern) — hvis vi senere åbner bredere
- Beta review (lettere end App Store-review)
- Kræver demo-konto hvis login → først relevant med cloud-buddy

### Fase 3 (App Store public) — ikke planlagt
- Fuld review
- Kræver cloud-buddy med demo-account

## Åbne spørgsmål

1. **Bundle ID** — bekræft `app.webhouse.cctalk`
2. **App-navn i App Store Connect** — "cctalk" / "CC Talk" / "Claude Talk"?
3. **Accent-farve** — Webhouse-blå (hex?) / Anthropic-orange / system-blå?
4. **App-ikon** — jeg får design-agent til at lave 3 forslag eller du leverer
5. **Haptics-niveau** — alt/some/off som bruger-indstilling eller fast?
6. **History persistence** — in-memory (forsvinder ved app-kill) eller Core Data / UserDefaults?
7. **Fallback når mic fejler** — vis tekstfelt til manuel indtastning?
8. **Mac-server auto-start** — skal jeg også lave launchd plist i v1?

## Næste skridt — rækkefølge

1. **Du godkender planen / redigerer** ← vi er her
2. Jeg svarer åbne spørgsmål med defaults du kan overrule
3. Spawner design-agent med brief → får UI-mockup + SwiftUI-komponenter
4. Scaffolder Xcode-projekt + fastlane
5. Implementerer M1 → M5 én ad gangen (committer per milestone)
6. Første TestFlight-upload (M6)
7. Design-pass (M7)
8. Verificering på din iPhone
9. Post-MVP: plan Fase 2-features
