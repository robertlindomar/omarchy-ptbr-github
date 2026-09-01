#!/usr/bin/env bash
# Prepara e submete plugins Omarchy PT-BR ao marketplace oficial.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE_DIR="$ROOT/marketplace"
SUBMISSIONS_DIR="$MARKETPLACE_DIR/submissions"
METADATA_FILE="$MARKETPLACE_DIR/metadata.json"
RESULTS_FILE="$MARKETPLACE_DIR/submission-results.json"

# Repositório oficial (SUBMISSION.md atual; HANCORE-linux redireciona para omacom).
MARKETPLACE_REPO="${MARKETPLACE_REPO:-omacom/omarchy-plugin-marketplace}"
SUBMISSION_DOC_SHA="${SUBMISSION_DOC_SHA:-846ee8f7cade3fbd6e0e5bd917f5878a17dcb273}"

DO_SUBMIT=0
FILTER=""

declare -a READY=()
declare -a NEEDS_FIX=()
declare -a ALREADY_SUBMITTED=()
declare -a ALREADY_LISTED=()
declare -a BLOCKED=()
declare -a SUBMIT_FAILURES=()

log() { printf '[submit] %s\n' "$*" >&2; }
warn() { printf '[submit] AVISO: %s\n' "$*" >&2; }
die() { printf '[submit] ERRO: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Uso: ./scripts/submit-marketplace.sh [--dry-run] [--submit] [slug]

Prepara submissões ao Omarchy Plugin Marketplace.

  --dry-run   Prepara arquivos e mostra resumo (padrão)
  --submit    Cria issues para plugins status=ready (exige digitar SUBMIT)
  slug        Apenas omarchy-ptbr-<slug> (ex.: weather)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) ;;
    --submit) DO_SUBMIT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) FILTER="$1" ;;
  esac
  shift
done

command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) não encontrado."
command -v jq >/dev/null 2>&1 || die "jq não encontrado."

GITHUB_OWNER="$(gh api user --jq .login 2>/dev/null)" || die "gh não autenticado."

slug_from_repo() { printf '%s' "${1#omarchy-ptbr-}"; }

suggest_category() {
  case "$1" in
    agents) echo "Developer Tools" ;;
    audio|bluetooth) echo "Hardware" ;;
    clipboard|reminders) echo "Productivity" ;;
    clock|indicators|weather) echo "Widgets" ;;
    disk-speedtest|lock|network|polkit|power|speedtest) echo "System" ;;
    menu|notifications) echo "Desktop" ;;
    *) echo "Other" ;;
  esac
}

suggest_tags() {
  case "$1" in
    agents) echo "ai, quickshell" ;;
    audio) echo "media, quickshell" ;;
    bluetooth) echo "system, quickshell" ;;
    clipboard|notifications|reminders) echo "quickshell" ;;
    clock|indicators|weather) echo "bar, quickshell" ;;
    disk-speedtest|network|speedtest) echo "system, quickshell" ;;
    lock) echo "security, quickshell" ;;
    menu) echo "launcher, quickshell" ;;
    polkit) echo "security, system" ;;
    power) echo "power-management, quickshell" ;;
    *) echo "quickshell" ;;
  esac
}

maintainer_notes() {
  local cloned="$1"
  cat <<EOF
Tradução pt-BR não oficial derivada do plugin upstream \`${cloned}\`. Requer Omarchy com Quickshell. Ao habilitar este clone, o plugin oficial correspondente é desabilitado automaticamente pelo Omarchy.
EOF
}

discover_repos() {
  gh repo list "$GITHUB_OWNER" --limit 200 --json name,isPrivate \
    | jq -r '.[] | select(.name | startswith("omarchy-ptbr-")) | select(.name != "omarchy-ptbr-github") | select(.isPrivate == false) | .name' \
    | sort
}

fetch_manifest() {
  gh api "repos/$GITHUB_OWNER/$1/contents/manifest.json" --jq .content 2>/dev/null | base64 -d
}

fetch_readme() {
  gh api "repos/$GITHUB_OWNER/$1/readme" --jq .content 2>/dev/null | base64 -d
}

list_root_files() {
  gh api "repos/$GITHUB_OWNER/$1/contents" --jq '.[].name' 2>/dev/null
}

check_readme_install() { printf '%s' "$1" | rg -qi 'instala|install|omarchy plugin'; }
check_readme_remove() { printf '%s' "$1" | rg -qi 'remov|desinstal|uninstall|removal'; }
check_deps_documented() { printf '%s' "$1" | rg -qi 'depend|requisit|requirement|omarchy|quickshell|licen'; }

preview_info() {
  local files="$1"
  local f
  f="$(printf '%s\n' "$files" | rg -o '^preview\.(png|jpg|jpeg|webp|avif)$' | head -1 || true)"
  if [[ -n "$f" ]]; then printf '%s' "$f"; else printf 'none'; fi
}

search_existing_submission() {
  local repo_url="$1" plugin_id="$2" plugin_name="$3" hits
  for q in "$repo_url" "$plugin_id" "[Plugin]: $plugin_name"; do
    hits="$(gh search issues "$q" --repo "$MARKETPLACE_REPO" --limit 3 --json url 2>/dev/null || echo '[]')"
    if [[ "$(echo "$hits" | jq 'length')" -gt 0 ]]; then
      echo "$hits" | jq -r '.[0].url'
      return 0
    fi
  done
  return 1
}

is_listed_in_registry() {
  local plugin_id="$1" registry
  registry="$(gh api "repos/$MARKETPLACE_REPO/contents/registry.json" --jq .content 2>/dev/null | base64 -d 2>/dev/null || echo '{}')"
  echo "$registry" | jq -e --arg id "$plugin_id" '.plugins[]? | select(.id == $id)' >/dev/null 2>&1
}

cb() { [[ "$1" == "true" ]] && printf '[x]' || printf '[ ]'; }

write_submission_body() {
  local repo_url="$1" category="$2" tags="$3" cloned="$4" outfile="$5"
  local c_public="$6" c_license="$7" c_own="$8" c_overwrite="$9" c_review="${10}"
  cat >"$outfile" <<EOF
### Repository URL

${repo_url}

### Category

${category}

### Tags

${tags}

### Suggest a missing tag

_No response_

### Maintainer notes

$(maintainer_notes "$cloned")

### Submission checklist

- $(cb "$c_public") The repository is public and contains installation and removal instructions.
- $(cb "$c_license") I have documented the plugin license and any external dependencies.
- $(cb "$c_own") I confirm that I own or have permission to submit this plugin and its preview assets.
- $(cb "$c_overwrite") The plugin does not overwrite user configuration without explicit consent.
- $(cb "$c_review") I understand that approval is for listing and is not a security review.
EOF
}

process_plugin() {
  local repo="$1"
  local slug repo_url manifest plugin_id plugin_name version author description cloned
  local files readme category tags preview
  local has_license install_ok remove_ok deps_ok
  local status existing_issue checklist_issues=()

  slug="$(slug_from_repo "$repo")"
  repo_url="https://github.com/$GITHUB_OWNER/$repo"

  manifest="$(fetch_manifest "$repo")" || { BLOCKED+=("$slug: manifest inacessível"); return 1; }
  [[ -n "$manifest" ]] || { BLOCKED+=("$slug: manifest vazio"); return 1; }

  plugin_id="$(echo "$manifest" | jq -r '.id')"
  plugin_name="$(echo "$manifest" | jq -r '.name')"
  version="$(echo "$manifest" | jq -r '.version // ""')"
  author="$(echo "$manifest" | jq -r '.author // ""')"
  description="$(echo "$manifest" | jq -r '.description // ""')"
  cloned="$(echo "$manifest" | jq -r '.omarchy.clonedFrom // ""')"

  files="$(list_root_files "$repo")"
  readme="$(fetch_readme "$repo")"
  category="$(suggest_category "$slug")"
  tags="$(suggest_tags "$slug")"
  preview="$(preview_info "$files")"

  has_license=false
  install_ok=false
  remove_ok=false
  deps_ok=false
  printf '%s\n' "$files" | rg -q '^LICENSE$' && has_license=true
  check_readme_install "$readme" && install_ok=true
  check_readme_remove "$readme" && remove_ok=true
  check_deps_documented "$readme" && deps_ok=true

  local public_ok=true
  local checklist_public="false" checklist_license="false"
  if $public_ok && [[ "$install_ok" == true ]] && [[ "$remove_ok" == true ]]; then checklist_public="true"; fi
  if [[ "$has_license" == true ]] && [[ "$deps_ok" == true ]]; then checklist_license="true"; fi

  [[ "$install_ok" == false ]] && checklist_issues+=("README sem instruções de instalação")
  [[ "$remove_ok" == false ]] && checklist_issues+=("README sem instruções de remoção/desinstalação")
  [[ "$has_license" == false ]] && checklist_issues+=("LICENSE ausente na raiz")
  [[ "$deps_ok" == false ]] && checklist_issues+=("dependências externas não documentadas no README")
  [[ "$plugin_id" != "${plugin_id,,}" ]] && checklist_issues+=("ID não está em lowercase")
  [[ "$plugin_id" == omarchy.* ]] && checklist_issues+=("ID usa namespace reservado omarchy.*")

  mkdir -p "$SUBMISSIONS_DIR"
  write_submission_body "$repo_url" "$category" "$tags" "$cloned" "$SUBMISSIONS_DIR/$slug.md" \
    "$checklist_public" "$checklist_license" "false" "true" "true"

  status="ready"
  existing_issue=""
  if is_listed_in_registry "$plugin_id"; then
    status="already-listed"
    ALREADY_LISTED+=("$slug")
  elif existing_issue="$(search_existing_submission "$repo_url" "$plugin_id" "$plugin_name" 2>/dev/null || true)" && [[ -n "$existing_issue" ]]; then
    status="already-submitted"
    ALREADY_SUBMITTED+=("$slug -> $existing_issue")
  elif ((${#checklist_issues[@]})); then
    status="needs-fix"
    NEEDS_FIX+=("$slug: ${checklist_issues[*]}")
  else
    READY+=("$slug")
  fi

  log "=== $plugin_name ($slug) -> $status ==="

  jq -n \
    --arg repository "$repo_url" \
    --arg plugin_id "$plugin_id" \
    --arg name "$plugin_name" \
    --arg version "$version" \
    --arg author "$author" \
    --arg description "$description" \
    --arg cloned_from "$cloned" \
    --arg category "$category" \
    --arg tags "$tags" \
    --arg preview "$preview" \
    --arg status "$status" \
    --arg title "[Plugin]: $plugin_name" \
    --arg submission_file "marketplace/submissions/$slug.md" \
    --arg existing_issue "${existing_issue:-}" \
    --arg checklist_public "$checklist_public" \
    --arg checklist_license "$checklist_license" \
    --arg checklist_install "$([[ "$install_ok" == true ]] && echo true || echo false)" \
    --arg checklist_remove "$([[ "$remove_ok" == true ]] && echo true || echo false)" \
    --arg checklist_deps "$([[ "$deps_ok" == true ]] && echo true || echo false)" \
    --arg issues "$(IFS='; '; echo "${checklist_issues[*]:-}")" \
    '{
      repository: $repository,
      plugin_id: $plugin_id,
      name: $name,
      version: $version,
      author: $author,
      description: $description,
      cloned_from: $cloned_from,
      category: $category,
      tags: ($tags | split(", ") | map(select(length > 0))),
      preview: $preview,
      status: $status,
      issue_title: $title,
      submission_file: $submission_file,
      existing_issue: (if $existing_issue == "" then null else $existing_issue end),
      checklist: {
        public_repo_with_install_remove: ($checklist_public == "true"),
        license_and_dependencies: ($checklist_license == "true"),
        install_instructions: ($checklist_install == "true"),
        removal_instructions: ($checklist_remove == "true"),
        dependencies_documented: ($checklist_deps == "true"),
        ownership_requires_owner_confirmation: true
      },
      issues: (if $issues == "" then [] else ($issues | split("; ")) end)
    }'
}

prepare_all() {
  mkdir -p "$SUBMISSIONS_DIR"
  [[ -f "$RESULTS_FILE" ]] || echo '{}' >"$RESULTS_FILE"

  log "GITHUB_OWNER=$GITHUB_OWNER"
  log "MARKETPLACE_REPO=$MARKETPLACE_REPO"
  log "SUBMISSION.md blob SHA: $SUBMISSION_DOC_SHA"

  mapfile -t REPOS < <(discover_repos)
  log "Plugins descobertos: ${#REPOS[@]}"
  echo '{}' >"$METADATA_FILE"

  local repo slug entry tmp
  for repo in "${REPOS[@]}"; do
    slug="$(slug_from_repo "$repo")"
    [[ -n "$FILTER" && "$slug" != "$FILTER" ]] && continue
    entry="$(process_plugin "$repo")" || continue
    tmp="$(mktemp)"
    jq --arg s "$slug" --argjson e "$entry" '. + {($s): $e}' "$METADATA_FILE" >"$tmp" || { warn "Falha ao gravar metadata para $slug"; rm -f "$tmp"; continue; }
    mv "$tmp" "$METADATA_FILE"
  done

  log ""
  log "========== RESUMO =========="
  printf '| Plugin | ID | Categoria | Tags | Preview | Status |\n'
  printf '|---|---|---|---|---|---|\n'
  jq -r 'to_entries[] | "| \(.key) | \(.value.plugin_id) | \(.value.category) | \(.value.tags | join(", ")) | \(.value.preview) | \(.value.status) |"' "$METADATA_FILE"
}

submit_all() {
  [[ -f "$METADATA_FILE" ]] || die "Execute primeiro: ./scripts/submit-marketplace.sh --dry-run"

  printf '\nATENÇÃO: criar issues em %s\n' "$MARKETPLACE_REPO"
  printf 'Digite exatamente SUBMIT para confirmar: '
  local confirm
  read -r confirm
  [[ "$confirm" == "SUBMIT" ]] || die "Cancelado (esperado: SUBMIT)"

  mapfile -t SLUGS < <(jq -r 'to_entries[] | select(.value.status == "ready") | .key' "$METADATA_FILE")
  ((${#SLUGS[@]})) || die "Nenhum plugin com status ready."

  local slug meta title body_file repo_url plugin_id issue_url tmp
  for slug in "${SLUGS[@]}"; do
    meta="$(jq -r --arg s "$slug" '.[$s]' "$METADATA_FILE")"
    repo_url="$(echo "$meta" | jq -r .repository)"
    plugin_id="$(echo "$meta" | jq -r .plugin_id)"
    title="$(echo "$meta" | jq -r .issue_title)"
    body_file="$ROOT/$(echo "$meta" | jq -r .submission_file)"

    if is_listed_in_registry "$plugin_id"; then
      warn "$slug já listado — pulando"
      continue
    fi
    if search_existing_submission "$repo_url" "$plugin_id" "$(echo "$meta" | jq -r .name)" >/dev/null 2>&1; then
      warn "$slug já tem issue — pulando"
      continue
    fi

    log "Criando: $title"
    issue_url="$(gh issue create --repo "$MARKETPLACE_REPO" --title "$title" --body-file "$body_file")"
    log "  -> $issue_url"

    tmp="$(mktemp)"
    jq --arg s "$slug" --arg url "$issue_url" \
      '.[$s] = {issue: $url, status: "submitted", submitted_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))}' \
      "$RESULTS_FILE" >"$tmp" && mv "$tmp" "$RESULTS_FILE"
    sleep 2
  done
}

if [[ $DO_SUBMIT -eq 1 ]]; then
  submit_all
else
  prepare_all
fi
