#!/usr/bin/env bash
# Garante que preview.png do monorepo vá para a raiz do repo individual gerado,
# e que artefatos temporários de preview NÃO sejam publicados.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLISH="$ROOT/scripts/publish-plugins.sh"

# 1) Contrato estático no script de publish
rg -q -- '--exclude=.preview1\.png.|exclude=.preview1\.png.' "$PUBLISH" \
  || rg -q "exclude='preview1.png'" "$PUBLISH" \
  || { echo "ERRO: publish-plugins.sh não exclui preview1.png"; exit 1; }

rg -q "exclude='preview-old.png'" "$PUBLISH" \
  || { echo "ERRO: publish-plugins.sh não exclui preview-old.png"; exit 1; }

rg -q 'preview\.png' "$PUBLISH" \
  || { echo "ERRO: publish-plugins.sh não menciona preview.png"; exit 1; }

# 2) Exercício funcional de prepare_workdir (funções reais do script)
FIXTURE_ROOT="${TMPDIR:-/tmp}/omarchy-ptbr-preview-test-$$"
cleanup() { rm -rf "$FIXTURE_ROOT"; }
trap cleanup EXIT

PLUGIN_ID="robertlindomar.omarchy-ptbr.preview-fixture"
PLUGIN_DIR="$FIXTURE_ROOT/plugins/$PLUGIN_ID"
mkdir -p "$PLUGIN_DIR"

cat >"$PLUGIN_DIR/manifest.json" <<'EOF'
{
  "schemaVersion": 1,
  "id": "robertlindomar.omarchy-ptbr.preview-fixture",
  "name": "Preview Fixture",
  "version": "0.0.0",
  "author": "test",
  "description": "fixture",
  "kinds": ["overlay"],
  "entryPoints": { "overlay": "Dummy.qml" },
  "omarchy": { "clonedFrom": "omarchy.clipboard" }
}
EOF
printf 'Item {}\n' >"$PLUGIN_DIR/Dummy.qml"

if command -v magick >/dev/null 2>&1; then
  magick -size 8x8 xc:'#112233' "$PLUGIN_DIR/preview.png"
else
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' \
    >"$PLUGIN_DIR/preview.png"
fi

echo junk >"$PLUGIN_DIR/preview1.png"
echo junk >"$PLUGIN_DIR/preview-old.png"
echo junk >"$PLUGIN_DIR/shot-full.png"
echo junk >"$PLUGIN_DIR/panel-open.png"
echo junk >"$PLUGIN_DIR/panel-base.png"
echo junk >"$PLUGIN_DIR/screenshot-tmp.png"

# Carrega só as funções auxiliares até prepare_workdir (sem executar o main)
# Isola variáveis do script real.
WORK_OUT="$FIXTURE_ROOT/work"
# shellcheck disable=SC2034
eval "$(
  awk '
    BEGIN {print "set -euo pipefail"}
    /^log\(\)/,/^}$/ {print; next}
    /^plugin_slug\(\)/,/^}$/ {print; next}
    /^repo_name\(\)/,/^}$/ {print; next}
    /^friendly_name\(\)/,/^}$/ {print; next}
    /^write_gitignore\(\)/,/^}$/ {print; next}
    /^write_license\(\)/,/^}$/ {print; next}
    /^write_readme\(\)/,/^}$/ {print; next}
    /^prepare_workdir\(\)/,/^}$/ {print; next}
  ' "$PUBLISH"
  cat <<EOF
ROOT="$FIXTURE_ROOT"
PLUGINS_DIR="$FIXTURE_ROOT/plugins"
WORK_ROOT="$WORK_OUT"
OWNER="testowner"
DRY_RUN=1
YEAR=2026
MAIN_REPO_URL="https://example.com/monorepo"
prepare_workdir "$PLUGIN_DIR"
printf '%s\n' "\$WORK_ROOT/\$(repo_name "$PLUGIN_DIR")"
EOF
)" >"$FIXTURE_ROOT/run.log" 2>&1

WORK="$(tail -1 "$FIXTURE_ROOT/run.log")"

fail=0
assert_file() {
  local path="$1" want="$2" msg="$3"
  if [[ "$want" == present && ! -f "$path" ]]; then
    echo "ERRO: $msg ($path ausente)"; fail=1
  elif [[ "$want" == absent && -f "$path" ]]; then
    echo "ERRO: $msg ($path presente)"; fail=1
  fi
}

assert_file "$WORK/preview.png" present "repo gerado deve conter ./preview.png"
assert_file "$WORK/preview1.png" absent "preview1.png não deve ser publicado"
assert_file "$WORK/preview-old.png" absent "preview-old.png não deve ser publicado"
assert_file "$WORK/shot-full.png" absent "*-full.png não deve ser publicado"
assert_file "$WORK/panel-open.png" absent "*-open.png não deve ser publicado"
assert_file "$WORK/panel-base.png" absent "*-base.png não deve ser publicado"
assert_file "$WORK/screenshot-tmp.png" absent "screenshot*.png não deve ser publicado"
assert_file "$WORK/manifest.json" present "manifest.json deve permanecer"

# Caso sem preview: não falha
rm -f "$PLUGIN_DIR/preview.png"
WORK2_ROOT="$FIXTURE_ROOT/work-noprev"
eval "$(
  awk '
    BEGIN {print "set -euo pipefail"}
    /^log\(\)/,/^}$/ {print; next}
    /^plugin_slug\(\)/,/^}$/ {print; next}
    /^repo_name\(\)/,/^}$/ {print; next}
    /^friendly_name\(\)/,/^}$/ {print; next}
    /^write_gitignore\(\)/,/^}$/ {print; next}
    /^write_license\(\)/,/^}$/ {print; next}
    /^write_readme\(\)/,/^}$/ {print; next}
    /^prepare_workdir\(\)/,/^}$/ {print; next}
  ' "$PUBLISH"
  cat <<EOF
ROOT="$FIXTURE_ROOT"
PLUGINS_DIR="$FIXTURE_ROOT/plugins"
WORK_ROOT="$WORK2_ROOT"
OWNER="testowner"
DRY_RUN=1
YEAR=2026
MAIN_REPO_URL="https://example.com/monorepo"
prepare_workdir "$PLUGIN_DIR"
printf '%s\n' "\$WORK_ROOT/\$(repo_name "$PLUGIN_DIR")"
EOF
)" >"$FIXTURE_ROOT/run2.log" 2>&1

WORK2="$(tail -1 "$FIXTURE_ROOT/run2.log")"
assert_file "$WORK2/preview.png" absent "sem preview na fonte → sem preview no repo"
assert_file "$WORK2/manifest.json" present "publicação sem preview não deve falhar"

if [[ $fail -ne 0 ]]; then
  echo "---- run.log ----"; cat "$FIXTURE_ROOT/run.log" || true
  echo "---- run2.log ----"; cat "$FIXTURE_ROOT/run2.log" || true
  exit 1
fi

echo "OK: preview.png na raiz; temporários excluídos; ausência de preview não falha."
