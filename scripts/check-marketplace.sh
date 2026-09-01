#!/usr/bin/env bash
# Acompanha issues de submissão no Omarchy Plugin Marketplace.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA_FILE="$ROOT/marketplace/metadata.json"
RESULTS_FILE="$ROOT/marketplace/submission-results.json"
MARKETPLACE_REPO="${MARKETPLACE_REPO:-omacom/omarchy-plugin-marketplace}"
UPDATE_FILES=0
TMP_UPDATES=""

log() { printf '[check] %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Uso: ./scripts/check-marketplace.sh [--update]

Consulta estado das submissões no Marketplace.

  --update  Atualiza marketplace/submission-results.json e metadata.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update) UPDATE_FILES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
  esac
  shift
done

command -v gh >/dev/null 2>&1 || { echo "gh não encontrado" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq não encontrado" >&2; exit 1; }

[[ -f "$METADATA_FILE" ]] || { echo "metadata.json ausente." >&2; exit 1; }

TMP_UPDATES="$(mktemp)"
echo '{}' >"$TMP_UPDATES"

has_label() {
  local labels_json="$1" label="$2"
  echo "$labels_json" | jq -e --arg l "$label" 'index($l) != null' >/dev/null 2>&1
}

classify_status() {
  local state="$1" labels_json="$2" listed="$3"
  if [[ "$listed" == true ]]; then echo "LISTED"; return; fi
  if [[ "$state" == "closed" ]]; then
    if has_label "$labels_json" "listed"; then echo "LISTED"; else echo "CLOSED_REJECTED"; fi
    return
  fi
  if has_label "$labels_json" "needs-fixes"; then echo "NEEDS_FIX"; return; fi
  if has_label "$labels_json" "approved-and-verified" || has_label "$labels_json" "approved-for-listing"; then
    echo "APPROVED"; return
  fi
  if has_label "$labels_json" "validated"; then
    if has_label "$labels_json" "security-review-required"; then echo "SECURITY_REVIEW"; else echo "VALIDATED"; fi
    return
  fi
  echo "PENDING"
}

fetch_registry_ids() {
  gh api "repos/$MARKETPLACE_REPO/contents/registry.json" --jq .content 2>/dev/null \
    | base64 -d 2>/dev/null \
    | jq -r '.plugins[]?.id // empty' 2>/dev/null || true
}

declare -a REGISTRY_IDS=()
while IFS= read -r rid; do
  [[ -n "$rid" ]] && REGISTRY_IDS+=("$rid")
done < <(fetch_registry_ids)

is_listed_id() {
  local id="$1" rid
  for rid in "${REGISTRY_IDS[@]}"; do
    [[ "$rid" == "$id" ]] && return 0
  done
  return 1
}

printf '| Plugin | Issue | Validated | Security Review | Listed | Status |\n'
printf '|---|---|---|---|---|---|\n'

declare -i TOTAL=0 VALIDATED=0 PENDING=0 NEEDS_FIX=0 APPROVED=0 LISTED=0
checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mapfile -t SLUGS < <(jq -r 'keys[]' "$METADATA_FILE" | sort)

for slug in "${SLUGS[@]}"; do
  plugin_id="$(jq -r --arg s "$slug" '.[$s].plugin_id' "$METADATA_FILE")"
  issue_url="$(jq -r --arg s "$slug" '.[$s].issue // .[$s].existing_issue // ""' "$METADATA_FILE")"
  if [[ -f "$RESULTS_FILE" ]]; then
    r_issue="$(jq -r --arg s "$slug" '.[$s].issue // ""' "$RESULTS_FILE" 2>/dev/null || true)"
    [[ -n "$r_issue" && "$r_issue" != "null" ]] && issue_url="$r_issue"
  fi

  if [[ -z "$issue_url" || "$issue_url" == "null" ]]; then
    printf '| %s | — | — | — | — | PENDING |\n' "$slug"
    TOTAL=$((TOTAL + 1)); PENDING=$((PENDING + 1))
    continue
  fi

  num="${issue_url##*/}"
  data="$(gh api "repos/$MARKETPLACE_REPO/issues/$num" \
    --jq '{state: .state, labels: [.labels[].name], url: .html_url}' 2>/dev/null || echo '{}')"
  state="$(echo "$data" | jq -r '.state // "?"')"
  labels_json="$(echo "$data" | jq -c '.labels // []')"
  labels_str="$(echo "$labels_json" | jq -r 'join(", ")')"

  listed=false
  is_listed_id "$plugin_id" && listed=true

  validated="—"
  security="—"
  listed_col="—"
  has_label "$labels_json" "validated" && validated="sim" && VALIDATED=$((VALIDATED + 1))
  has_label "$labels_json" "security-review-required" && security="sim"
  [[ "$listed" == true ]] && listed_col="sim" && LISTED=$((LISTED + 1))

  status="$(classify_status "$state" "$labels_json" "$listed")"
  case "$status" in
    PENDING) PENDING=$((PENDING + 1)) ;;
    NEEDS_FIX|CLOSED_REJECTED) NEEDS_FIX=$((NEEDS_FIX + 1)) ;;
    APPROVED) APPROVED=$((APPROVED + 1)) ;;
  esac
  TOTAL=$((TOTAL + 1))

  printf '| %s | %s | %s | %s | %s | %s |\n' "$slug" "$issue_url" "$validated" "$security" "$listed_col" "$status"

  if [[ $UPDATE_FILES -eq 1 ]]; then
    entry="$(jq -n \
      --arg plugin_id "$plugin_id" \
      --arg issue "$issue_url" \
      --argjson issue_number "$num" \
      --arg state "$state" \
      --argjson labels "$labels_json" \
      --arg status_class "$status" \
      --arg checked_at "$checked_at" \
      --argjson validated "$(has_label "$labels_json" "validated" && echo true || echo false)" \
      --argjson security_review_required "$(has_label "$labels_json" "security-review-required" && echo true || echo false)" \
      --argjson listed "$listed" \
      '{
        plugin_id: $plugin_id,
        issue: $issue,
        issue_number: $issue_number,
        state: $state,
        labels: $labels,
        status: "submitted",
        status_class: $status_class,
        validated: $validated,
        security_review_required: $security_review_required,
        listed: $listed,
        checked_at: $checked_at
      }')"
    jq --arg s "$slug" --argjson e "$entry" '. + {($s): $e}' "$TMP_UPDATES" >"${TMP_UPDATES}.new"
    mv "${TMP_UPDATES}.new" "$TMP_UPDATES"
  fi
done

log ""
log "TOTAL: $TOTAL"
log "VALIDATED: $VALIDATED"
log "PENDING: $PENDING"
log "NEEDS FIX: $NEEDS_FIX"
log "APPROVED: $APPROVED"
log "LISTED: $LISTED"

if [[ $UPDATE_FILES -eq 1 ]]; then
  jq -n \
    --arg checked_at "$checked_at" \
    --arg marketplace_repo "$MARKETPLACE_REPO" \
    --argjson plugins "$(cat "$TMP_UPDATES")" \
    '{checked_at: $checked_at, marketplace_repo: $marketplace_repo} + $plugins' \
    >"$RESULTS_FILE"

  jq --slurpfile updates "$TMP_UPDATES" --arg checked_at "$checked_at" '
    reduce ($updates[0] | keys[]) as $s (.;
      .[$s] |= (. + $updates[0][$s] + {
        status: "already-submitted",
        existing_issue: $updates[0][$s].issue,
        issue: $updates[0][$s].issue,
        issue_number: $updates[0][$s].issue_number,
        state: $updates[0][$s].state,
        labels: $updates[0][$s].labels,
        status_class: $updates[0][$s].status_class,
        validated: $updates[0][$s].validated,
        security_review_required: $updates[0][$s].security_review_required,
        listed: $updates[0][$s].listed,
        checked_at: $checked_at
      })
    )' "$METADATA_FILE" >"${METADATA_FILE}.new"
  mv "${METADATA_FILE}.new" "$METADATA_FILE"
  log "Arquivos atualizados: $RESULTS_FILE e $METADATA_FILE"
fi

rm -f "$TMP_UPDATES"
log ""
log "Nota: validated + security-review-required não implica listagem; aguardar mantenedores."
