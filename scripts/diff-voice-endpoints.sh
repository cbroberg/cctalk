#!/usr/bin/env bash
# diff-voice-endpoints.sh — verify buddy's /api/voice/* has shape parity with cctalk's endpoints.
# Usage: bash scripts/diff-voice-endpoints.sh
# Exit 0 if all checks pass, non-zero on first mismatch.

set -uo pipefail

CCTALK_URL="http://127.0.0.1:7777"
BUDDY_URL="http://127.0.0.1:4123/api/voice"

CCTALK_TOKEN=$(grep '^AUTH_TOKEN=' "$(dirname "$0")/../.env" | cut -d= -f2-)
BUDDY_TOKEN=$(cat ~/.buddy/voice-token)

if [[ -z "$CCTALK_TOKEN" || -z "$BUDDY_TOKEN" ]]; then
  echo "FAIL: missing tokens"
  exit 2
fi

# Check both servers reachable
for url in "$CCTALK_URL/health" "$BUDDY_URL/health"; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 3 "$url")
  if [[ "$code" != "200" ]]; then
    echo "FAIL: $url returned $code"
    exit 3
  fi
done

PASS=0
FAIL=0

# Report a check outcome. Echo PASS / FAIL lines; do not exit so all checks run.
check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS  $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $name"
    echo "      expected: $expected"
    echo "      actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

# Normalize JSON by dropping dynamic fields (tokens, pids, startedAt, ports, cwd paths).
# Leaves shape for apples-to-apples diff.
normalize_sessions() {
  jq -S '[.[] | {name, displayName, hasCwd: (.cwd != null), hasPort: (.port > 0), hasPid: (.pid > 0)}]'
}

# --- 1. /health ---
cc_health=$(curl -sS "$CCTALK_URL/health" | jq -r '.ok')
bd_health=$(curl -sS "$BUDDY_URL/health" | jq -r '.ok')
check "health ok=true"       "true" "$cc_health"
check "health buddy ok=true" "true" "$bd_health"

# --- 2. /sessions shape parity (ignoring dynamic values) ---
cc_sess=$(curl -sS -H "Authorization: Bearer $CCTALK_TOKEN" "$CCTALK_URL/sessions" | normalize_sessions)
bd_sess=$(curl -sS -H "Authorization: Bearer $BUDDY_TOKEN" "$BUDDY_URL/sessions" | normalize_sessions)
if [[ "$cc_sess" == "$bd_sess" ]]; then
  echo "PASS  /sessions shape parity"
  PASS=$((PASS + 1))
else
  echo "FAIL  /sessions shape mismatch"
  diff <(echo "$cc_sess") <(echo "$bd_sess") | head -20
  FAIL=$((FAIL + 1))
fi

# --- 3. /sessions.txt line count parity ---
cc_txt=$(curl -sS -H "Authorization: Bearer $CCTALK_TOKEN" "$CCTALK_URL/sessions.txt" | wc -l | tr -d ' ')
bd_txt=$(curl -sS -H "Authorization: Bearer $BUDDY_TOKEN" "$BUDDY_URL/sessions.txt" | wc -l | tr -d ' ')
check "/sessions.txt line count" "$cc_txt" "$bd_txt"

# --- 4. /target GET shape ---
cc_get=$(curl -sS -H "Authorization: Bearer $CCTALK_TOKEN" "$CCTALK_URL/target" | jq -r 'keys_unsorted | join(",")')
bd_get=$(curl -sS -H "Authorization: Bearer $BUDDY_TOKEN" "$BUDDY_URL/target" | jq -r 'keys_unsorted | join(",")')
check "/target GET keys" "$cc_get" "$bd_get"

# --- 5. Auth errors match ---
cc_401=$(curl -sS -o /dev/null -w "%{http_code}" "$CCTALK_URL/sessions")
bd_401=$(curl -sS -o /dev/null -w "%{http_code}" "$BUDDY_URL/sessions")
check "sessions 401 no auth" "$cc_401" "$bd_401"

# --- 6. /target POST 400 on missing body ---
cc_400=$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $CCTALK_TOKEN" -H "Content-Type: application/json" "$CCTALK_URL/target" -d '{}')
bd_400=$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $BUDDY_TOKEN" -H "Content-Type: application/json" "$BUDDY_URL/target" -d '{}')
check "target POST 400 empty" "$cc_400" "$bd_400"

# --- 7. /speak 404 target_not_found ---
cc_404=$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $CCTALK_TOKEN" -H "Content-Type: application/json" "$CCTALK_URL/speak" -d '{"text":"diff-test","target":"nonexistent-xyz"}')
bd_404=$(curl -sS -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $BUDDY_TOKEN" -H "Content-Type: application/json" "$BUDDY_URL/speak" -d '{"text":"diff-test","target":"nonexistent-xyz"}')
check "speak 404 bad target" "$cc_404" "$bd_404"

# --- 8. QR deep-link scheme + params (ignore token bytes) ---
cc_qr=$(curl -sS "$CCTALK_URL/qr" | zbarimg --quiet - 2>/dev/null | sed -e 's/&token=[^&]*//' -e 's/%3A[0-9]*$//')
bd_qr=$(curl -sS "$BUDDY_URL/qr" | zbarimg --quiet - 2>/dev/null | sed -e 's/&token=[^&]*//' -e 's/%3A[0-9]*$//')
if [[ -n "$cc_qr" && "$cc_qr" == "$bd_qr" ]]; then
  echo "PASS  QR deep-link structure"
  PASS=$((PASS + 1))
else
  echo "FAIL  QR deep-link differs"
  echo "      cctalk: $cc_qr"
  echo "      buddy:  $bd_qr"
  FAIL=$((FAIL + 1))
fi

echo
echo "=== RESULT ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
