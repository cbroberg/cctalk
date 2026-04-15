# iPhone Shortcut opsætning

Step-by-step guide til at oprette "Tal til cc" shortcut'en.

## Før du starter

Du skal have:
- cctalk serveren kørende på din Mac
- Tailscale installeret på både Mac og iPhone (samme konto)
- Dit MagicDNS-navn (fx `din-mac.din-tailnet.ts.net`)
- Dit `AUTH_TOKEN` fra `.env`

## Opret shortcut'en

1. Åbn **Shortcuts**-appen på iPhone
2. Tryk **+** øverst til højre
3. Navngiv den **Tal til cc** (tryk på titlen øverst)

## Tilføj actions

### Action 1: Dictate Text

- Søg efter "Dictate Text" og tilføj
- Tryk på pilen for at udvide options:
  - **Language**: Danish
  - **Stop Listening**: `On Tap` (anbefalet – du har fuld kontrol)
    - Alternativt `After Short Pause` for auto-stop

### Action 2: Get Contents of URL

- Søg efter "Get Contents of URL" og tilføj
- **URL**: `http://din-mac.din-tailnet.ts.net:7777/speak`
- Tryk pilen for at udvide:
  - **Method**: POST
  - **Headers**: tilføj to headers:
    - `Authorization` = `Bearer dit-token-fra-env`
    - `Content-Type` = `application/json`
  - **Request Body**: JSON
    - Tryk "Add new field"
    - Key: `text`
    - Type: Text
    - Value: tryk på feltet → vælg variablen **Dictated Text** fra forrige step

### Action 3: Show Notification (valgfrit men rart)

- Søg efter "Show Notification" og tilføj
- **Title**: `Sendt til cc`
- **Body**: vælg variablen **Dictated Text**

## Test shortcut'en

Tryk play-knappen nederst. Sig noget på dansk. Tjek din Mac-terminal for:

```
[2026-04-14T...] → hej cc det her er en test
```

Hvis du får en fejl:

- **401 unauthorized** → token i Shortcut matcher ikke `.env`
- **Could not connect** → Tailscale kører ikke, eller MagicDNS-navnet er forkert
- **Timeout** → serveren kører ikke, eller port 7777 er blokeret

## Bind til Back Tap

1. **Settings** → **Accessibility** → **Touch** → **Back Tap**
2. Vælg **Double Tap** (eller Triple Tap)
3. Scroll ned til sektionen **Shortcuts**
4. Vælg **Tal til cc**

Nu: dobbelt-tap bagsiden af telefonen, tal, tryk stop, færdig.

## Bind til Action Button (iPhone 15 Pro+)

1. **Settings** → **Action Button**
2. Swipe til **Shortcut**
3. Tryk **Choose a Shortcut**
4. Vælg **Tal til cc**

## Tips

- Hvis du vil have partial transcription live, kræver det en rigtig SwiftUI-app (ikke Shortcuts). Shortcut-dikteringen viser kun resultatet når du trykker stop.
- Back Tap virker også når telefonen er låst hvis du tillader det under Face ID & Passcode → Allow Access When Locked.
- Hvis serveren skal være tilgængelig uden for dit hjemmenetværk, er Tailscale allerede løsningen – den virker overalt.
