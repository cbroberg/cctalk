# cctalk

Ekstremt tynd voice-relay: iPhone dansk diktering → Hono endpoint på Mac → Claude Code (via buddy-channel).

Ingen Whisper. Ingen model-downloads. Bruger iPhones indbyggede `Speech framework` som er i top-3 globalt på dansk, kører on-device, og har nærmest nul latency.

## Arkitektur

```
iPhone Shortcut (Dictate Text, da-DK)
    │
    ▼ POST /speak (over Tailscale)
Hono server på Mac :7777
    │
    ▼ appendFile
Buddy-channel → Claude Code
```

## Setup

### 1. Installer deps

```bash
cd ~/Apps/cctalk
pnpm install
cp .env.example .env
```

Generer et token og sæt det i `.env`:

```bash
echo "AUTH_TOKEN=$(openssl rand -hex 32)" >> .env
```

Rediger `.env` og fjern den gamle placeholder-linje. Sæt også `BUDDY_CHANNEL` til stien på din faktiske buddy-integration hvis du har en – ellers bruger den `/tmp/cctalk.log` som default.

### 2. Start serveren

```bash
pnpm start
```

Du skulle se:

```
cctalk lytter på :7777
buddy-channel: /tmp/cctalk.log
```

### 3. Smoke-test lokalt

```bash
chmod +x test.sh
./test.sh
```

Hvis du ser `{"ok":true,"received":"hej cc..."}` er serveren klar.

### 4. Installer Tailscale

På Mac:

```bash
brew install --cask tailscale
```

Log ind, og installer Tailscale på iPhone fra App Store med **samme konto**.

Find dit Mac MagicDNS-navn i Tailscale-menuen (menubar) – typisk `din-mac.din-tailnet.ts.net`.

Test fra iPhone Safari: `http://din-mac.din-tailnet.ts.net:7777/health` → skal returnere `{"ok":true,"service":"cctalk"}`.

### 5. Opret iPhone Shortcut

Se [`shortcut-setup.md`](./shortcut-setup.md) for detaljeret guide.

### 6. Bind til en knap

**Back Tap** (alle nyere iPhones):
Settings → Accessibility → Touch → Back Tap → Double Tap → **Tal til cc**

**Action Button** (iPhone 15 Pro+):
Settings → Action Button → Shortcut → **Tal til cc**

## Dagligt brug

1. Dobbelt-tap bagsiden af iPhonen (eller tryk Action Button)
2. Tal dansk naturligt
3. Tryk stop (eller vent på auto-stop)
4. Teksten lander i din buddy-channel og sendes videre til cc

## Kør som baggrundsservice (valgfrit)

For at serveren starter automatisk ved login, opret en launchd plist:

```bash
cat > ~/Library/LaunchAgents/dk.webhouse.cctalk.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dk.webhouse.cctalk</string>
    <key>WorkingDirectory</key>
    <string>$HOME/Apps/cctalk</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/node</string>
        <string>server.js</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/cctalk.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/cctalk.err.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/dk.webhouse.cctalk.plist
```

## Integrering med buddy

Serveren bruger default `appendFile` til `BUDDY_CHANNEL`. Hvis din buddy bruger en named pipe, Unix socket eller noget andet, så rediger `server.js` omkring linje 45 hvor `appendFile` kaldes.

## Stack

- Node.js 20+ (ES modules)
- Hono 4 + `@hono/node-server`
- dotenv
- iPhone Shortcuts (indbygget)
- Tailscale (gratis tier)

## Licens

MIT
