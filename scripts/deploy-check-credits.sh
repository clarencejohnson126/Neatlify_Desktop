#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_REF="${1:-nlvlwrhayrvberdyjgjx}"

if ! command -v supabase >/dev/null 2>&1; then
  echo "ERROR: supabase CLI not found. Install it first."
  exit 1
fi

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "ERROR: SUPABASE_ACCESS_TOKEN is not set."
  echo "Run 'supabase login' or export SUPABASE_ACCESS_TOKEN, then retry."
  exit 1
fi

echo "Deploying check-credits to project: ${PROJECT_REF}"
supabase functions deploy check-credits \
  --project-ref "${PROJECT_REF}" \
  --no-verify-jwt \
  --workdir "${ROOT_DIR}"

echo "Done."

