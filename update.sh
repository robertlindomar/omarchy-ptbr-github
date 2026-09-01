#!/usr/bin/env bash
# Omarchy PT-BR — relatório pós-atualização do Omarchy upstream
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${ROOT}/docs/UPDATE-REPORT-$(date +%Y%m%d-%H%M%S).md"

log() { printf '%s\n' "$*"; }

[[ -d /usr/share/omarchy ]] || { log "ERRO: Omarchy não instalado"; exit 1; }

log "# Relatório de atualização Omarchy PT-BR" > "$REPORT"
log "" >> "$REPORT"
log "Data: $(date -Iseconds)" >> "$REPORT"
log "Omarchy: $(cat /usr/share/omarchy/version 2>/dev/null || echo desconhecida)" >> "$REPORT"
log "" >> "$REPORT"

compare_plugin() {
  local clone_id="$1"
  local official_id="$2"
  local clone_dir="$HOME/.config/omarchy/plugins/$clone_id"
  local official_dir="/usr/share/omarchy/shell/plugins"

  # localizar diretório oficial por manifest id
  local official_path
  official_path="$(find "$official_dir" -name manifest.json -print0 2>/dev/null | xargs -0 grep -l "\"id\": \"$official_id\"" 2>/dev/null | head -1 || true)"
  [[ -n $official_path ]] || official_path="$(find /usr/share/omarchy/shell/plugins -type d -name "${official_id#omarchy.}" 2>/dev/null | head -1)"

  log "## $clone_id (oficial: $official_id)" >> "$REPORT"
  if [[ ! -d $clone_dir ]]; then
    log "- Clone não instalado" >> "$REPORT"
    log "" >> "$REPORT"
    return
  fi
  if [[ -z $official_path || ! -e $official_path ]]; then
    log "- Caminho oficial não encontrado automaticamente" >> "$REPORT"
    log "" >> "$REPORT"
    return
  fi
  official_path="$(dirname "$official_path")"

  log '```' >> "$REPORT"
  diff -ruN "$official_path" "$clone_dir" \
    | rg -v '^(Only in|Binary files)' \
    | head -200 >> "$REPORT" || true
  log '```' >> "$REPORT"
  log "" >> "$REPORT"
}

while IFS=$'\t' read -r clone official; do
  [[ -z $clone ]] && continue
  compare_plugin "$clone" "$official"
done <<'MAP'
robert.menu	omarchy.menu
robert.lock	omarchy.lock
robert.polkit	omarchy.polkit
robert.clipboard	omarchy.clipboard
robert.reminders	omarchy.reminders
robert.network	omarchy.network
robert.bluetooth	omarchy.bluetooth
robert.power	omarchy.power
robert.weather	omarchy.weather
robert.audio	omarchy.audio
robert.speedtest	omarchy.speedtest
robert.disk-speedtest	omarchy.disk-speedtest
robert.agents	omarchy.agents
robert.notifications	omarchy.notifications
robert.clock	omarchy.clock
MAP

log "Relatório salvo em: $REPORT"
log "Revise conflitos manualmente antes de sobrescrever traduções."
