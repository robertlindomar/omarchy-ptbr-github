#!/usr/bin/env bash
# Omarchy PT-BR — verificação pós-instalação
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

PLUGINS=(
  robertlindomar.omarchy-ptbr.menu robertlindomar.omarchy-ptbr.lock robertlindomar.omarchy-ptbr.polkit robertlindomar.omarchy-ptbr.clipboard robertlindomar.omarchy-ptbr.reminders
  robertlindomar.omarchy-ptbr.network robertlindomar.omarchy-ptbr.bluetooth robertlindomar.omarchy-ptbr.power robertlindomar.omarchy-ptbr.weather robertlindomar.omarchy-ptbr.audio robertlindomar.omarchy-ptbr.monitor
  robertlindomar.omarchy-ptbr.speedtest robertlindomar.omarchy-ptbr.disk-speedtest robertlindomar.omarchy-ptbr.agents robertlindomar.omarchy-ptbr.notifications robertlindomar.omarchy-ptbr.clock robertlindomar.omarchy-ptbr.indicators
)

ok() { printf '  [OK] %s\n' "$*"; }
bad() { printf '  [FALHA] %s\n' "$*"; FAIL=1; }
warn() { printf '  [AVISO] %s\n' "$*"; }

printf '=== Verificação Omarchy PT-BR ===\n\n'

[[ -d /usr/share/omarchy ]] && ok "Omarchy instalado" || bad "Omarchy não encontrado"

for plugin in "${PLUGINS[@]}"; do
  if [[ -d "$HOME/.config/omarchy/plugins/$plugin" ]]; then
    ok "Plugin presente: $plugin"
    if omarchy plugin validate "$HOME/.config/omarchy/plugins/$plugin" >/dev/null 2>&1; then
      ok "Validação: $plugin"
    else
      bad "Validação falhou: $plugin"
    fi
  else
    bad "Plugin ausente: $plugin"
  fi
done

for bin in omarchy-menu-keybindings omarchy-capture-screenshot omarchy-reminder; do
  if [[ -x "$HOME/.local/bin/$bin" ]]; then
    ok "Override bin: $bin"
  else
    bad "Override bin ausente: $bin"
  fi
done

[[ -f "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc" ]] \
  && ok "Traduções do menu" \
  || bad "extensions/omarchy-menu.jsonc ausente"

[[ -f "$HOME/.config/omarchy/keybindings-labels-ptbr.awk" ]] \
  && ok "Mapa de keybindings pt-BR" \
  || bad "keybindings-labels-ptbr.awk ausente"

if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl version >/dev/null 2>&1; then
    ok "Hyprland ativo"
  else
    warn "Hyprland não respondeu (sessão pode estar inativa)"
  fi
fi

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
  ok "PATH contém ~/.local/bin"
else
  warn "PATH pode não priorizar ~/.local/bin — verifique ~/.config/hypr/envs.lua"
fi

if [[ -f "$HOME/.config/hypr/envs.lua" ]] && grep -q 'omarchy-ptbr: PATH fix' "$HOME/.config/hypr/envs.lua"; then
  ok "Fix de PATH em envs.lua"
else
  warn "Fix de PATH não detectado em envs.lua"
fi

printf '\n'
if [[ $FAIL -eq 0 ]]; then
  printf 'Resultado: OK\n'
else
  printf 'Resultado: problemas encontrados\n'
  exit 1
fi
