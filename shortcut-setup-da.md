# Opsætning af Genveje på iPhone (dansk iOS)

Trin-for-trin guide til at oprette genvejen "Tal til cc" når din iPhone kører på dansk.

## Før du starter

Du skal have:
- cctalk-serveren kørende på din Mac
- Tailscale installeret på både Mac og iPhone (samme konto)
- Dit MagicDNS-navn (fx `din-mac.din-tailnet.ts.net`)
- Dit `AUTH_TOKEN` fra `.env`

## Opret genvejen

1. Åbn appen **Genveje** på iPhone
2. Tryk **+** øverst til højre
3. Navngiv den **Tal til cc** (tryk på titlen øverst, vælg **Omdøb**)

## Tilføj handlinger

### Handling 1: Dikter tekst

- Søg efter **Dikter tekst** og tilføj
- Tryk på pilen **▸** for at udvide indstillinger:
  - **Sprog**: Dansk (Danmark)
  - **Stop lytning**: `Ved tryk` (anbefalet – du har fuld kontrol)
    - Alternativt `Efter kort pause` for auto-stop

### Handling 2: Hent indhold af URL

- Søg efter **Hent indhold af URL** og tilføj
- **URL**: `http://din-mac.din-tailnet.ts.net:7777/speak`
- Tryk pilen **▸** for at udvide:
  - **Metode**: POST
  - **Headere**: tilføj to headere:
    - `Authorization` = `Bearer dit-token-fra-env`
    - `Content-Type` = `application/json`
  - **Anmodningsorgan**: JSON
    - Tryk **Tilføj nyt felt** → vælg **Tekst**
    - Nøgle: `text`
    - Værdi: tryk på feltet → vælg variablen **Dikteret tekst** fra forrige trin

### Handling 3: Vis notifikation (valgfrit men rart)

- Søg efter **Vis notifikation** og tilføj
- **Titel**: `Sendt til cc`
- **Brødtekst**: vælg variablen **Dikteret tekst**

## Test genvejen

Tryk afspilningsknappen **▶** nederst. Sig noget på dansk. Tjek din Mac-terminal for:

```
[2026-04-15T...] → hej cc det her er en test
```

Hvis du får en fejl:

- **401 unauthorized** → tokenet i genvejen matcher ikke `.env`
- **Kunne ikke oprette forbindelse** → Tailscale kører ikke, eller MagicDNS-navnet er forkert
- **Timeout** → serveren kører ikke, eller port 7777 er blokeret

## Bind til Tryk bagpå

1. **Indstillinger** → **Tilgængelighed** → **Berøring** → **Tryk bagpå**
2. Vælg **Dobbelttryk** (eller **Trippeltryk**)
3. Rul ned til afsnittet **Genveje**
4. Vælg **Tal til cc**

Nu: dobbelt-tap bagsiden af telefonen, tal, tryk stop, færdig.

## Bind til Handlingsknap (iPhone 15 Pro og nyere)

1. **Indstillinger** → **Handlingsknap**
2. Swipe til **Genvej**
3. Tryk **Vælg en genvej**
4. Vælg **Tal til cc**

## Tips

- Partial transcription live kræver en rigtig SwiftUI-app (ikke Genveje). Diktering i Genveje viser kun resultatet når du trykker stop.
- Tryk bagpå virker også når telefonen er låst, hvis du tillader det under **Face ID og kode** → **Giv adgang, når låst** → slå **Tryk bagpå** til.
- Hvis serveren skal være tilgængelig uden for dit hjemmenetværk, løser Tailscale allerede det – den virker overalt.
