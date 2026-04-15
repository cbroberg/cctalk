#!/usr/bin/env bash
# Lokal smoke-test af cctalk serveren
set -e

source .env

echo "→ Health check"
curl -sS http://localhost:${PORT}/health
echo

echo "→ Unauthorized (forventet 401)"
curl -sS -X POST http://localhost:${PORT}/speak \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}'
echo

echo "→ Authorized speak"
curl -sS -X POST http://localhost:${PORT}/speak \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"text":"hej cc, det her er en test fra curl"}'
echo

echo "→ Sidste linjer i buddy-channel:"
tail -n 3 "${BUDDY_CHANNEL}"
