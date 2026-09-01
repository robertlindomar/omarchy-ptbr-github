#!/usr/bin/env bash
# Omarchy PT-BR — registro de compatibilidade com upstream
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/docs/COMPATIBILIDADE.md"
OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

{
  echo "# Compatibilidade Omarchy PT-BR"
  echo ""
  echo "Gerado em: $(date -Iseconds)"
  echo ""
  echo "## Versão upstream testada"
  echo ""
  echo "| Campo | Valor |"
  echo "|-------|-------|"
  echo "| Versão | \`$(cat "$OMARCHY_PATH/version" 2>/dev/null || echo desconhecida)\` |"
  echo "| Caminho | \`$OMARCHY_PATH\` |"
  echo ""
  echo "## Hashes de referência (plugins oficiais)"
  echo ""
  echo '```'
  find "$OMARCHY_PATH/shell/plugins" -name manifest.json 2>/dev/null | sort | while read -r m; do
    sha256sum "$m"
  done
  echo '```'
  echo ""
  echo "## Hashes dos clones pt-BR"
  echo ""
  echo '```'
  find "$ROOT/plugins" -name manifest.json 2>/dev/null | sort | while read -r m; do
    sha256sum "$m"
  done
  echo '```'
} > "$OUT"

echo "Atualizado: $OUT"
