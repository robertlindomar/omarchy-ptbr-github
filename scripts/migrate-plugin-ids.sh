#!/usr/bin/env bash
# Migra plugins robert.* → robertlindomar.omarchy-ptbr.*
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="robertlindomar.omarchy-ptbr"
AUTHOR="Robert Lindomar"
OLD_PREFIX="robert."
NEW_PREFIX="${NAMESPACE}."
APPLY=0
MIGRATE_REPO=1
MIGRATE_LIVE=1

COMPONENTS=(
  menu lock polkit clipboard reminders network bluetooth power weather audio
  speedtest disk-speedtest agents notifications clock
)

log() { printf '[migrate] %s\n' "$*"; }
die() { printf '[migrate] ERRO: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Uso: $0 [--dry-run] [--apply] [--repo-only] [--live-only]

Migra robert.* para ${NEW_PREFIX}* no repositório e/ou em ~/.config/omarchy.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) APPLY=0 ;;
    --apply) APPLY=1 ;;
    --repo-only) MIGRATE_LIVE=0 ;;
    --live-only) MIGRATE_REPO=0 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Argumento desconhecido: $arg" ;;
  esac
done

old_id() { printf '%s%s' "$OLD_PREFIX" "$1"; }
new_id() { printf '%s%s' "$NEW_PREFIX" "$1"; }

run() {
  if [[ $APPLY -eq 1 ]]; then
    "$@"
  else
    printf '[dry-run] %s\n' "$*"
  fi
}

backup_file() {
  local file="$1"
  [[ -f $file ]] || return 0
  local backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-ptbr/backups/migrate-$(date +%Y%m%d-%H%M%S)"
  if [[ $APPLY -eq 1 ]]; then
    mkdir -p "$backup_dir"
    cp -a "$file" "$backup_dir/"
    log "Backup: $file -> $backup_dir/"
  else
    log "backup: $file"
  fi
}

update_manifest() {
  local manifest="$1"
  local component="$2"
  local new="${NEW_PREFIX}${component}"
  if [[ ! -f $manifest ]]; then
    return 0
  fi
  if [[ $APPLY -eq 1 ]] && command -v jq >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    jq --arg id "$new" --arg author "$AUTHOR" \
      '.id = $id | .author = $author' "$manifest" > "$tmp"
    mv "$tmp" "$manifest"
  else
    run sed -i "s/\"id\": \"$(old_id "$component")\"/\"id\": \"${new}\"/" "$manifest"
    run sed -i "s/\"author\": \".*\"/\"author\": \"${AUTHOR}\"/" "$manifest"
  fi
}

rename_plugin_dir() {
  local base="$1"
  local component="$2"
  local old_dir="$base/$(old_id "$component")"
  local new_dir="$base/$(new_id "$component")"
  [[ -d $old_dir ]] || return 0
  [[ -d $new_dir ]] && die "Destino já existe: $new_dir"
  log "Renomear: $old_dir -> $new_dir"
  if [[ $APPLY -eq 1 ]]; then
    if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
      && [[ "$base" == "$ROOT/plugins" ]]; then
      git -C "$ROOT" mv "$old_dir" "$new_dir"
    else
      mv "$old_dir" "$new_dir"
    fi
  fi
  update_manifest "$new_dir/manifest.json" "$component"
}

replace_in_file() {
  local file="$1"
  local component
  [[ -f $file ]] || return 0
  if [[ $APPLY -eq 1 ]]; then
    for component in "${COMPONENTS[@]}"; do
      sed -i "s/$(old_id "$component")/$(new_id "$component")/g" "$file"
    done
  else
    if grep -qE 'robert\.(menu|lock|polkit|clipboard|reminders|network|bluetooth|power|weather|audio|speedtest|disk-speedtest|agents|notifications|clock)' "$file" 2>/dev/null; then
      log "substituir IDs em: $file"
    fi
  fi
}

migrate_text_files() {
  local dir="$1"
  local files=(
    "$dir/install.sh"
    "$dir/uninstall.sh"
    "$dir/update.sh"
    "$dir/scripts/verify-install.sh"
    "$dir/config/shell.json.example"
    "$dir/README.md"
    "$dir/NOTICE.md"
    "$dir/docs/COMPATIBILIDADE.md"
    "$dir/docs/SEGURANCA.md"
    "$dir/docs/GLOSSARIO.md"
    "$dir/docs/IMPLEMENTACAO.md"
    "$dir/docs/RELATORIO.md"
  )
  local f
  for f in "${files[@]}"; do
    replace_in_file "$f"
  done
}

migrate_shell_json() {
  local file="$1"
  [[ -f $file ]] || return 0
  backup_file "$file"
  replace_in_file "$file"
  # Corrigir centerAnchor legado
  if [[ $APPLY -eq 1 ]]; then
    sed -i \
      -e 's/"centerAnchor": "omarchy\.clock"/"centerAnchor": "robertlindomar.omarchy-ptbr.clock"/' \
      -e 's/"centerAnchor": "robert\.clock"/"centerAnchor": "robertlindomar.omarchy-ptbr.clock"/' \
      "$file"
  else
    log "ajustar centerAnchor em: $file"
  fi
}

migrate_plugins_tree() {
  local base="$1"
  local component
  for component in "${COMPONENTS[@]}"; do
    rename_plugin_dir "$base" "$component"
  done
}

enable_new_plugins() {
  command -v omarchy >/dev/null 2>&1 || return 0
  local component
  for component in "${COMPONENTS[@]}"; do
    local old new plugin_dir
    old="$(old_id "$component")"
    new="$(new_id "$component")"
    plugin_dir="$HOME/.config/omarchy/plugins/$new"
    run omarchy plugin disable "$old" 2>/dev/null || true
    run omarchy plugin enable "$new" 2>/dev/null || true
    if [[ $APPLY -eq 1 ]]; then
      omarchy plugin validate "$plugin_dir" || die "Validação falhou: $new"
    else
      log "validate: $plugin_dir"
    fi
  done
}

remove_orphan_robert_dirs() {
  local base="$1"
  local dir
  for dir in "$base"/robert.*; do
    [[ -d $dir ]] || continue
    log "Remover órfão: $dir"
    run rm -rf "$dir"
  done
}

if [[ $MIGRATE_REPO -eq 1 ]]; then
  log "=== Repositório: $ROOT ==="
  migrate_plugins_tree "$ROOT/plugins"
  migrate_text_files "$ROOT"
fi

if [[ $MIGRATE_LIVE -eq 1 ]]; then
  log "=== Instalação ativa: ~/.config/omarchy ==="
  migrate_plugins_tree "$HOME/.config/omarchy/plugins"
  migrate_shell_json "$HOME/.config/omarchy/shell.json"
  remove_orphan_robert_dirs "$HOME/.config/omarchy/plugins"
  enable_new_plugins
fi

log "Migração concluída ($([[ $APPLY -eq 1 ]] && echo apply || echo dry-run))."
