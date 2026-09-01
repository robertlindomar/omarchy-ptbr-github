#!/usr/bin/env bash
# Omarchy PT-BR — desinstalador
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-ptbr"
BACKUP_ROOT="${STATE_DIR}/backups"

PLUGINS=(
  robertlindomar.omarchy-ptbr.menu robertlindomar.omarchy-ptbr.lock robertlindomar.omarchy-ptbr.polkit robertlindomar.omarchy-ptbr.clipboard robertlindomar.omarchy-ptbr.reminders
  robertlindomar.omarchy-ptbr.network robertlindomar.omarchy-ptbr.bluetooth robertlindomar.omarchy-ptbr.power robertlindomar.omarchy-ptbr.weather robertlindomar.omarchy-ptbr.audio
  robertlindomar.omarchy-ptbr.speedtest robertlindomar.omarchy-ptbr.disk-speedtest robertlindomar.omarchy-ptbr.agents robertlindomar.omarchy-ptbr.notifications robertlindomar.omarchy-ptbr.clock robertlindomar.omarchy-ptbr.indicators
)

OFFICIAL=(
  omarchy.menu omarchy.lock omarchy.polkit omarchy.clipboard omarchy.reminders
  omarchy.speedtest omarchy.disk-speedtest omarchy.notifications omarchy.clock
  omarchy.network omarchy.bluetooth omarchy.power omarchy.weather omarchy.audio omarchy.agents
)

log() { printf '[omarchy-ptbr] %s\n' "$*"; }

latest_backup() {
  [[ -d $BACKUP_ROOT ]] || return 1
  ls -1dt "$BACKUP_ROOT"/* 2>/dev/null | head -1
}

restore_from_backup() {
  local backup="$1"
  local rel="$2"
  local src="$backup/$rel"
  [[ -e $src ]] || return 0
  mkdir -p "$(dirname "$rel")"
  cp -a "$src" "$rel"
  log "Restaurado: $rel"
}

log "Desabilitando clones pt-BR"
for plugin in "${PLUGINS[@]}"; do
  omarchy plugin disable "$plugin" 2>/dev/null || true
done

log "Reabilitando plugins oficiais (quando existirem)"
for plugin in "${OFFICIAL[@]}"; do
  omarchy plugin enable "$plugin" 2>/dev/null || true
done

log "Removendo diretórios de plugins pt-BR"
for plugin in "${PLUGINS[@]}"; do
  rm -rf "$HOME/.config/omarchy/plugins/$plugin"
done

log "Removendo overrides em ~/.local/bin"
for file in omarchy-menu-keybindings omarchy-capture-screenshot omarchy-reminder; do
  rm -f "$HOME/.local/bin/$file"
done

log "Removendo arquivos de configuração do projeto"
rm -f "$HOME/.config/omarchy/keybindings-labels-ptbr.awk"
rm -f "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
rm -f "${STATE_DIR}/installed"

if backup="$(latest_backup)"; then
  log "Tentando restaurar do backup mais recente: $backup"
  restore_from_backup "$backup" "home/$(whoami)/.config/omarchy/shell.json" || true
  restore_from_backup "$backup" ".config/omarchy/shell.json" || true
  restore_from_backup "$backup" "config/omarchy/shell.json" || true
fi

hyprctl reload >/dev/null 2>&1 || true
command -v omarchy-restart-shell >/dev/null && omarchy-restart-shell || true

log "Desinstalação concluída. Revise ~/.config/omarchy/shell.json e ~/.config/hypr/envs.lua manualmente se necessário."
