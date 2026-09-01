#!/usr/bin/env bash
# Acompanha issues de submissão no Omarchy Plugin Marketplace.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA_FILE="$ROOT/marketplace/metadata.json"
RESULTS_FILE="$ROOT/marketplace/submission-results.json"
MARKETPLACE_REPO="${MARKETPLACE_REPO:-omacom/omarchy-plugin-marketplace}"

log() { printf '[check] %s\n' "$*"; }

command -v gh >/dev/null 2>&1 || { echo "gh não encontrado" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq não encontrado" >&2; exit 1; }

[[ -f "$METADATA_FILE" ]] || { echo "metadata.json ausente. Execute submit-marketplace.sh --dry-run primeiro." >&2; exit 1; }

printf '| Plugin | Issue | Estado | Labels |\n'
printf '|---|---|---|---|\n'

mapfile -t SLUGS < <(jq -r 'keys[]' "$METADATA_FILE" | sort)

for slug in "${SLUGS[@]}"; do
  issue_url=""
  if [[ -f "$RESULTS_FILE" ]]; then
    issue_url="$(jq -r --arg s "$slug" '.[$s].issue // ""' "$RESULTS_FILE" 2>/dev/null || true)"
  fi

  if [[ -z "$issue_url" ]]; then
    plugin_id="$(jq -r --arg s "$slug" '.[$s].plugin_id' "$METADATA_FILE")"
    repo_url="$(jq -r --arg s "$slug" '.[$s].repository' "$METADATA_FILE")"
    issue_url="$(gh search issues "$repo_url" --repo "$MARKETPLACE_REPO" --limit 1 --json url --jq '.[0].url' 2>/dev/null || true)"
    if [[ -z "$issue_url" || "$issue_url" == "null" ]]; then
      issue_url="$(gh search issues "$plugin_id" --repo "$MARKETPLACE_REPO" --limit 1 --json url --jq '.[0].url' 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$issue_url" || "$issue_url" == "null" ]]; then
    printf '| %s | — | não enviado | — |\n' "$slug"
    continue
  fi

  num="${issue_url##*/}"
  data="$(gh api "repos/$MARKETPLACE_REPO/issues/$num" --jq '{state: .state, labels: [.labels[].name]}' 2>/dev/null || echo '{}')"
  state="$(echo "$data" | jq -r '.state // "?"')"
  labels="$(echo "$data" | jq -r '.labels | join(", ")')"
  printf '| %s | %s | %s | %s |\n' "$slug" "$issue_url" "$state" "$labels"
done

log ""
log "Labels comuns: submission, validated, needs-fixes, security-review-required, listed"
log "Nota: aprovação/listagem não implica revisão de segurança completa."
