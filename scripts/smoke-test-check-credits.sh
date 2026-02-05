#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF="${SUPABASE_PROJECT_REF:-nlvlwrhayrvberdyjgjx}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"
USER_EMAIL="${1:-}"
FILE_COUNT="${2:-10}"
RUN_DEDUCT="${RUN_DEDUCT:-0}"

if [[ -z "${ANON_KEY}" ]]; then
  echo "ERROR: SUPABASE_ANON_KEY is not set."
  exit 1
fi

if [[ -z "${USER_EMAIL}" ]]; then
  echo "Usage: $0 <user_email> [file_count]"
  exit 1
fi

BASE_URL="https://${PROJECT_REF}.supabase.co/functions/v1/check-credits"

echo "== check =="
curl -sS -X POST "${BASE_URL}" \
  -H "Content-Type: application/json" \
  -H "apikey: ${ANON_KEY}" \
  --data "{\"user_email\":\"${USER_EMAIL}\",\"file_count\":${FILE_COUNT},\"action\":\"check\"}" \
  -D - | cat

echo ""
if [[ "${RUN_DEDUCT}" == "1" ]]; then
  echo "== deduct =="
  curl -sS -X POST "${BASE_URL}" \
    -H "Content-Type: application/json" \
    -H "apikey: ${ANON_KEY}" \
    --data "{\"user_email\":\"${USER_EMAIL}\",\"file_count\":${FILE_COUNT},\"action\":\"deduct\"}" \
    -D - | cat
else
  echo "== deduct (skipped) =="
  echo "Set RUN_DEDUCT=1 to execute a real deduction."
fi

echo ""
echo "== balance =="
curl -sS -X POST "${BASE_URL}" \
  -H "Content-Type: application/json" \
  -H "apikey: ${ANON_KEY}" \
  --data "{\"user_email\":\"${USER_EMAIL}\",\"action\":\"balance\"}" \
  -D - | cat
