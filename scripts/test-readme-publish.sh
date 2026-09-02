#!/usr/bin/env bash
# Falha se o template de README do publish-plugins.sh reintroduz fluxo inseguro.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLISH="$ROOT/scripts/publish-plugins.sh"

rg -n 'omarchy-ptbr-github\.git' "$PUBLISH" && {
  echo "ERRO: publish-plugins.sh ainda referencia clone do monorepo." >&2
  exit 1
}

rg -n '\./install\.sh' "$PUBLISH" && {
  echo "ERRO: publish-plugins.sh ainda referencia ./install.sh." >&2
  exit 1
}

if ! rg -q 'omarchy plugin add' "$PUBLISH"; then
  echo "ERRO: publish-plugins.sh não documenta omarchy plugin add." >&2
  exit 1
fi

echo "OK: template publish-plugins.sh sem fluxo inseguro de monorepo."
