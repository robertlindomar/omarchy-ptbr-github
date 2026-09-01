#!/usr/bin/env bash
# Omarchy PT-BR — instalador idempotente
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-ptbr"
BACKUP_DIR="${STATE_DIR}/backups/$(date +%Y%m%d-%H%M%S)"
MARKER="${STATE_DIR}/installed"

PLUGINS=(
  robertlindomar.omarchy-ptbr.menu robertlindomar.omarchy-ptbr.lock robertlindomar.omarchy-ptbr.polkit robertlindomar.omarchy-ptbr.clipboard robertlindomar.omarchy-ptbr.reminders
  robertlindomar.omarchy-ptbr.network robertlindomar.omarchy-ptbr.bluetooth robertlindomar.omarchy-ptbr.power robertlindomar.omarchy-ptbr.weather robertlindomar.omarchy-ptbr.audio
  robertlindomar.omarchy-ptbr.speedtest robertlindomar.omarchy-ptbr.disk-speedtest robertlindomar.omarchy-ptbr.agents robertlindomar.omarchy-ptbr.notifications robertlindomar.omarchy-ptbr.clock robertlindomar.omarchy-ptbr.indicators
)

OFFICIAL_DISABLED=(
  omarchy.menu omarchy.lock omarchy.polkit omarchy.clipboard omarchy.reminders
  omarchy.speedtest omarchy.disk-speedtest omarchy.notifications
)

log() { printf '[omarchy-ptbr] %s\n' "$*"; }
warn() { printf '[omarchy-ptbr] AVISO: %s\n' "$*" >&2; }
die() { printf '[omarchy-ptbr] ERRO: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

usage() {
  cat <<'EOF'
Uso: ./install.sh [--dry-run]

Instala tradução pt-BR do Omarchy em ~/.config e ~/.local/bin.
Não modifica /usr/share/omarchy.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Argumento desconhecido: $arg" ;;
  esac
done

command -v omarchy >/dev/null 2>&1 || die "Omarchy não encontrado. Instale o Omarchy antes de continuar."
[[ -d /usr/share/omarchy ]] || die "/usr/share/omarchy não existe."

log "Omarchy base: $(cat /usr/share/omarchy/version 2>/dev/null || echo desconhecida)"

if [[ $DRY_RUN -eq 0 ]] && compgen -G "$HOME/.config/omarchy/plugins/robert.*" >/dev/null; then
  log "Detectados plugins robert.* legados — migrando para ${NAMESPACE:-robertlindomar.omarchy-ptbr}.*"
  "$ROOT/scripts/migrate-plugin-ids.sh" --apply --live-only
fi

if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$BACKUP_DIR" "$STATE_DIR"
fi

backup_if_exists() {
  local target="$1"
  [[ -e $target ]] || return 0
  if [[ $DRY_RUN -eq 1 ]]; then
    log "backup: $target -> $BACKUP_DIR/"
  else
    mkdir -p "$BACKUP_DIR/$(dirname "${target#/}")"
    cp -a "$target" "$BACKUP_DIR/${target#/}" 2>/dev/null || cp -a "$target" "$BACKUP_DIR/"
  fi
}

install_plugins() {
  local plugin src dst
  mkdir -p "$HOME/.config/omarchy/plugins"
  for plugin in "${PLUGINS[@]}"; do
    src="$ROOT/plugins/$plugin"
    dst="$HOME/.config/omarchy/plugins/$plugin"
    [[ -d $src ]] || die "Plugin ausente no repositório: $plugin"
    backup_if_exists "$dst"
    log "Instalando plugin $plugin"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] rsync %s -> %s\n' "$src/" "$dst/"
  else
    rsync -a --delete "$src/" "$dst/"
    omarchy plugin validate "$dst" || die "Validação falhou: $plugin"
  fi
  done
}

install_bin_overrides() {
  local file
  mkdir -p "$HOME/.local/bin"
  for file in omarchy-menu-keybindings omarchy-capture-screenshot omarchy-reminder; do
    backup_if_exists "$HOME/.local/bin/$file"
    log "Instalando override bin: $file"
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] install %s\n' "$ROOT/overrides/bin/$file"
    else
      install -m 755 "$ROOT/overrides/bin/$file" "$HOME/.local/bin/$file"
    fi
  done
}

install_omarchy_overrides() {
  mkdir -p "$HOME/.config/omarchy"
  backup_if_exists "$HOME/.config/omarchy/keybindings-labels-ptbr.awk"
  log "Instalando mapa de labels de keybindings"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] cp keybindings-labels-ptbr.awk\n'
  else
    cp "$ROOT/overrides/omarchy/keybindings-labels-ptbr.awk" "$HOME/.config/omarchy/"
  fi

  mkdir -p "$HOME/.config/omarchy/extensions"
  backup_if_exists "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
  log "Instalando traduções do menu (extensions/omarchy-menu.jsonc)"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] cp omarchy-menu.jsonc\n'
  else
    cp "$ROOT/extensions/omarchy-menu.jsonc" "$HOME/.config/omarchy/extensions/"
  fi
}

install_hypr_envs() {
  local target="$HOME/.config/hypr/envs.lua"
  local marker='# omarchy-ptbr: PATH fix'
  if [[ -f $target ]] && grep -qF "$marker" "$target" 2>/dev/null; then
    log "envs.lua já contém fix de PATH (omarchy-ptbr)"
    return 0
  fi
  backup_if_exists "$target"
  log "Aplicando fix de PATH em ~/.config/hypr/envs.lua"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] append envs.lua.example\n'
    return 0
  fi
  if [[ ! -f $target ]]; then
    cp "$ROOT/overrides/hypr/envs.lua.example" "$target"
    return 0
  fi
  {
    echo ""
    echo "$marker"
    tail -n +2 "$ROOT/overrides/hypr/envs.lua.example"
  } >> "$target"
}

merge_shell_json() {
  local target="$HOME/.config/omarchy/shell.json"
  local example="$ROOT/config/shell.json.example"
  [[ -f $example ]] || { warn "shell.json.example ausente; pulando merge da barra"; return 0; }
  command -v jq >/dev/null 2>&1 || { warn "jq não encontrado; configure shell.json manualmente (ver config/shell.json.example)"; return 0; }

  backup_if_exists "$target"
  log "Mesclando configuração da barra/shell.json"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] jq merge shell.json\n'
    return 0
  fi

  if [[ ! -f $target ]]; then
    cp "$example" "$target"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  jq -s '
    .[0] as $user | .[1] as $ptbr |
    $user
    | .bar.centerAnchor = $ptbr.bar.centerAnchor
    | .bar.layout = $ptbr.bar.layout
    | .plugins = (
        ($user.plugins // []) + ($ptbr.plugins // [])
        | unique_by(.id)
      )
    | .disabledPlugins = (
        (( $user.disabledPlugins // [] ) + ($ptbr.disabledPlugins // [])) | unique
      )
    | .cloneSourceRestores = (
        (( $user.cloneSourceRestores // [] ) + ($ptbr.cloneSourceRestores // [])) | unique
      )
  ' "$target" "$example" > "$tmp"
  mv "$tmp" "$target"
}

enable_plugins() {
  local plugin
  for plugin in "${PLUGINS[@]}"; do
    log "Habilitando $plugin"
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] omarchy plugin enable %s\n' "$plugin"
    else
      omarchy plugin enable "$plugin" 2>/dev/null || true
    fi
  done
}

reload_services() {
  log "Recarregando Hyprland (se disponível)"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] hyprctl reload\n'
    printf '[dry-run] omarchy-restart-shell\n'
    return 0
  fi
  hyprctl reload >/dev/null 2>&1 || true
  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/omarchy/keybindings-"*.records 2>/dev/null || true
  if command -v omarchy-restart-shell >/dev/null 2>&1; then
    omarchy-restart-shell || true
  elif command -v omarchy >/dev/null 2>&1; then
    omarchy restart shell || true
  fi
}

install_plugins
install_bin_overrides
install_omarchy_overrides
install_hypr_envs
merge_shell_json
enable_plugins

if [[ $DRY_RUN -eq 0 ]]; then
  date -Iseconds > "$MARKER"
  printf '%s\n' "$(cat /usr/share/omarchy/version 2>/dev/null || echo unknown)" > "${STATE_DIR}/omarchy-version"
fi

reload_services

log "Instalação concluída."
log "Backup em: $BACKUP_DIR"
log "Execute: ./scripts/verify-install.sh"
