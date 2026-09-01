#!/usr/bin/env bash
# Publica cada plugin Omarchy PT-BR em repositório GitHub individual.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
WORK_ROOT="${TMPDIR:-/tmp}/omarchy-ptbr-publish"
MAIN_REPO_URL="https://github.com/robertlindomar/omarchy-ptbr-github"
TOPICS=(omarchy omarchy-plugin pt-br portuguese translation linux quickshell)
YEAR="$(date +%Y)"

DRY_RUN=0
FILTER=""
OWNER=""

declare -a FAILURES=()
declare -a CREATED=()
declare -a UPDATED=()
declare -a RESULT_ROWS=()

log() { printf '[publish] %s\n' "$*"; }
warn() { printf '[publish] AVISO: %s\n' "$*" >&2; }
die() { printf '[publish] ERRO: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Uso: ./scripts/publish-plugins.sh [--dry-run] [slug]

Publica plugins de plugins/ em repositórios omarchy-ptbr-<slug> no GitHub.
slug = sufixo após robertlindomar.omarchy-ptbr. (ex.: weather, menu)
EOF
}

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) FILTER="$1" ;;
  esac
  shift
done

command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) não encontrado."
command -v jq >/dev/null 2>&1 || die "jq não encontrado."
command -v omarchy >/dev/null 2>&1 || die "omarchy não encontrado (necessário para validate)."

OWNER="$(gh api user --jq .login 2>/dev/null)" || die "gh não autenticado. Execute: gh auth login"
log "GITHUB_OWNER=$OWNER"

plugin_slug() {
  local dir="$1"
  basename "$dir" | sed 's/^robertlindomar\.omarchy-ptbr\.//'
}

repo_name() {
  printf 'omarchy-ptbr-%s' "$(plugin_slug "$1")"
}

friendly_name() {
  case "$(plugin_slug "$1")" in
    menu) echo "Menu" ;;
    lock) echo "Bloqueio" ;;
    polkit) echo "Polkit" ;;
    clipboard) echo "Área de transferência" ;;
    reminders) echo "Lembretes" ;;
    network) echo "Rede" ;;
    bluetooth) echo "Bluetooth" ;;
    power) echo "Energia" ;;
    weather) echo "Clima" ;;
    audio) echo "Áudio" ;;
    monitor) echo "Tela" ;;
    speedtest) echo "Teste de velocidade (rede)" ;;
    disk-speedtest) echo "Teste de velocidade (disco)" ;;
    agents) echo "Agentes" ;;
    notifications) echo "Notificações" ;;
    clock) echo "Relógio" ;;
    indicators) echo "Indicadores" ;;
    *) jq -r '.name // "Plugin"' "$1/manifest.json" ;;
  esac
}

discover_plugins() {
  local dir slug
  for dir in "$PLUGINS_DIR"/*/; do
    [[ -f "$dir/manifest.json" ]] || continue
    slug="$(plugin_slug "$dir")"
    [[ -n "$FILTER" && "$slug" != "$FILTER" ]] && continue
    printf '%s\n' "$dir"
  done
}

scan_secrets() {
  local dir="$1"
  local hits
  hits="$(rg -n --hidden -S \
    --glob '!.gitignore' \
    --glob '!LICENSE' \
    --glob '!README.md' \
    -e 'sk-[A-Za-z0-9]{20,}' \
    -e 'ghp_[A-Za-z0-9]{20,}' \
    -e 'github_pat_[A-Za-z0-9_]{20,}' \
    -e 'Bearer [A-Za-z0-9._-]{30,}' \
    -e '(?i)(api[_-]?key|apikey)\s*[:=]\s*["\x27][A-Za-z0-9_-]{16,}["\x27]' \
    -e '(?i)(secret|token|password|passwd)\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]' \
    -e '/home/robert' \
    "$dir" 2>/dev/null || true)"
  if [[ -n "$hits" ]]; then
    printf '%s\n' "$hits"
    return 1
  fi
  return 0
}

write_gitignore() {
  cat >"$1/.gitignore" <<'EOF'
*.bak
*.tmp
*.log
*~
.DS_Store
.env
.env.*
.cache/
backups/
secrets/
EOF
}

write_license() {
  cat >"$1/LICENSE" <<EOF
MIT License

Copyright (c) ${YEAR} Robert Lindomar and Omarchy PT-BR contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

This plugin is a pt-BR translation derived from Omarchy upstream components.
Original Omarchy plugin code remains subject to its upstream license and
copyright. See manifest.json ("omarchy.clonedFrom") for the source plugin id.
This is an unofficial community translation — not affiliated with Omarchy.
EOF
}

write_readme() {
  local work="$1" plugin_dir="$2"
  local id name cloned desc friendly kinds entry
  id="$(jq -r '.id' "$plugin_dir/manifest.json")"
  name="$(jq -r '.name' "$plugin_dir/manifest.json")"
  cloned="$(jq -r '.omarchy.clonedFrom // "n/a"' "$plugin_dir/manifest.json")"
  desc="$(jq -r '.description // ""' "$plugin_dir/manifest.json")"
  friendly="$(friendly_name "$plugin_dir")"
  kinds="$(jq -r '.kinds | join(", ")' "$plugin_dir/manifest.json")"
  entry="$(jq -r '[.entryPoints[]?] | join(", ")' "$plugin_dir/manifest.json")"
  local repo slug
  slug="$(plugin_slug "$plugin_dir")"
  repo="$(repo_name "$plugin_dir")"

  cat >"$work/README.md" <<EOF
# Omarchy PT-BR — ${friendly}

Tradução para português brasileiro do plugin \`${cloned}\` do Omarchy.

**ID do clone:** \`${id}\`

## O que é traduzido

- Textos e tooltips da interface em pt-BR
- Descrições do manifest quando aplicável
- ${desc}

Tipos: ${kinds}. Entry points: ${entry:-n/a}.

## Instalação

### Pelo Omarchy (recomendado)

1. Clone este repositório em \`~/.config/omarchy/plugins/${id}/\`
2. Valide: \`omarchy plugin validate ~/.config/omarchy/plugins/${id}\`
3. Habilite: \`omarchy plugin enable ${id}\`
4. Reinicie o shell: \`omarchy-restart-shell\`

Ou use o instalador do monorepo principal (inclui todos os plugins):

\`\`\`bash
git clone ${MAIN_REPO_URL}.git
cd omarchy-ptbr-github
./install.sh
\`\`\`

### Manual

\`\`\`bash
git clone https://github.com/${OWNER}/${repo}.git ~/.config/omarchy/plugins/${id}
omarchy plugin validate ~/.config/omarchy/plugins/${id}
omarchy plugin enable ${id}
omarchy-restart-shell
\`\`\`

## Remoção

\`\`\`bash
omarchy plugin disable ${id}
rm -rf ~/.config/omarchy/plugins/${id}
omarchy-restart-shell
\`\`\`

Para remover todos os plugins pt-BR de uma vez, use o desinstalador do monorepo:

\`\`\`bash
cd omarchy-ptbr-github
./uninstall.sh
\`\`\`

## Licença e dependências

- **Licença:** MIT (ver \`LICENSE\`). Obra derivada do plugin upstream \`${cloned}\`.
- **Requisitos:** Omarchy instalado, Hyprland em execução, Quickshell (incluído no Omarchy).
- **Dependências externas:** nenhuma além do stack Omarchy/Quickshell.

## Origem

Plugin baseado em: \`${cloned}\`

Projeto principal: ${MAIN_REPO_URL}

## Aviso

Projeto comunitário e **não oficial**. Não modifique \`/usr/share/omarchy\`.

## Problemas / traduções faltando

Abra uma issue em ${MAIN_REPO_URL}/issues ou neste repositório.
EOF
}

prepare_workdir() {
  local plugin_dir="$1"
  local slug repo work
  slug="$(plugin_slug "$plugin_dir")"
  repo="$(repo_name "$plugin_dir")"
  work="$WORK_ROOT/$repo"

  rm -rf "$work"
  mkdir -p "$work"

  rsync -a \
    --exclude='*.bak' --exclude='*.tmp' --exclude='*.log' \
    --exclude='.env' --exclude='.env.*' --exclude='README.md' \
    "$plugin_dir/" "$work/"

  write_gitignore "$work"
  write_license "$work"
  write_readme "$work" "$plugin_dir"
}

validate_plugin() {
  local work="$1"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "validate: $work (dry-run skip)"
    return 0
  fi
  omarchy plugin validate "$work"
}

repo_exists() {
  gh repo view "$OWNER/$1" >/dev/null 2>&1
}

repo_is_ours() {
  local repo="$1" desc
  desc="$(gh repo view "$OWNER/$repo" --json description --jq .description 2>/dev/null || echo "")"
  [[ "$desc" == *"Tradução pt-BR"* || "$desc" == *"Omarchy"* ]]
}

publish_one() {
  local plugin_dir="$1"
  local slug repo work id cloned friendly
  slug="$(plugin_slug "$plugin_dir")"
  repo="$(repo_name "$plugin_dir")"
  work="$WORK_ROOT/$repo"
  id="$(jq -r '.id' "$plugin_dir/manifest.json")"
  cloned="$(jq -r '.omarchy.clonedFrom // "n/a"' "$plugin_dir/manifest.json")"
  friendly="$(friendly_name "$plugin_dir")"

  log "=== $friendly ($id) -> $OWNER/$repo ==="

  if ! scan_secrets "$plugin_dir"; then
    FAILURES+=("$slug: possível segredo/dado pessoal no plugin fonte")
    RESULT_ROWS+=("$friendly|$id|$repo|SKIP|NÃO|segredo")
    return 1
  fi

  prepare_workdir "$plugin_dir"

  if ! scan_secrets "$work"; then
    FAILURES+=("$slug: possível segredo na área preparada")
    RESULT_ROWS+=("$friendly|$id|$repo|SKIP|NÃO|segredo")
    return 1
  fi

  if ! validate_plugin "$work"; then
    FAILURES+=("$slug: omarchy plugin validate falhou")
    RESULT_ROWS+=("$friendly|$id|$repo|FALHA|NÃO|validate")
    return 1
  fi

  if repo_exists "$repo"; then
    if ! repo_is_ours "$repo"; then
      FAILURES+=("$slug: repositório $repo existe mas não parece deste projeto — ignorado")
      RESULT_ROWS+=("$friendly|$id|$repo|SKIP|NÃO|conflito remoto")
      return 1
    fi
    log "Repositório existente — sincronizando $repo"
    local clone_dir="$WORK_ROOT/${repo}-git"
    rm -rf "$clone_dir"
    if [[ $DRY_RUN -eq 1 ]]; then
      log "[dry-run] git clone + sync + push $repo"
      UPDATED+=("https://github.com/$OWNER/$repo")
      RESULT_ROWS+=("$friendly|$id|$repo|OK|SIM (dry-run)|atualizado")
      return 0
    fi
    git clone "https://github.com/$OWNER/$repo.git" "$clone_dir"
    rsync -a --delete \
      --exclude='.git' \
      "$work/" "$clone_dir/"
    (
      cd "$clone_dir"
      git add -A
      if git diff --cached --quiet; then
        log "Sem mudanças em $repo"
      else
        git commit -m "chore: sincroniza tradução pt-BR do monorepo"
        git push origin main
      fi
    )
    gh repo edit "$OWNER/$repo" \
      --description "Tradução pt-BR do plugin ${friendly} para Omarchy 🇧🇷" \
      --add-topic omarchy --add-topic omarchy-plugin --add-topic pt-br \
      --add-topic portuguese --add-topic translation --add-topic linux --add-topic quickshell 2>/dev/null || true
    UPDATED+=("https://github.com/$OWNER/$repo")
    RESULT_ROWS+=("$friendly|$id|$repo|OK|SIM|atualizado")
    return 0
  fi

  log "Criando repositório $repo"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] git init + gh repo create $repo"
    CREATED+=("https://github.com/$OWNER/$repo")
    RESULT_ROWS+=("$friendly|$id|$repo|OK|SIM (dry-run)|criado")
    return 0
  fi

  (
    cd "$work"
    git init -q
    git branch -M main
    git add -A
    git commit -q -m "feat: tradução pt-BR do plugin ${slug}"
    gh repo create "$OWNER/$repo" \
      --public \
      --source=. \
      --remote=origin \
      --description "Tradução pt-BR do plugin ${friendly} para Omarchy 🇧🇷" \
      --push
  )
  gh repo edit "$OWNER/$repo" \
    --add-topic omarchy --add-topic omarchy-plugin --add-topic pt-br \
    --add-topic portuguese --add-topic translation --add-topic linux --add-topic quickshell 2>/dev/null || true

  CREATED+=("https://github.com/$OWNER/$repo")
  RESULT_ROWS+=("$friendly|$id|$repo|OK|SIM|criado")
}

mkdir -p "$WORK_ROOT"

mapfile -t PLUGIN_DIRS < <(discover_plugins)
[[ ${#PLUGIN_DIRS[@]} -gt 0 ]] || die "Nenhum plugin encontrado."

log "Plugins a publicar: ${#PLUGIN_DIRS[@]}"

for plugin_dir in "${PLUGIN_DIRS[@]}"; do
  publish_one "$plugin_dir" || true
done

log ""
log "========== RESUMO =========="
printf '| Plugin | ID | Repo | Validate | Publicado |\n'
printf '|---|---|---|---|---|\n'
for row in "${RESULT_ROWS[@]}"; do
  IFS='|' read -r a b c d e <<<"$row"
  printf '| %s | %s | %s | %s | %s |\n' "$a" "$b" "$c" "$d" "$e"
done

if ((${#CREATED[@]})); then
  log ""
  log "Criados:"
  printf '  %s\n' "${CREATED[@]}"
fi
if ((${#UPDATED[@]})); then
  log ""
  log "Atualizados:"
  printf '  %s\n' "${UPDATED[@]}"
fi
if ((${#FAILURES[@]})); then
  log ""
  warn "Falhas:"
  printf '  - %s\n' "${FAILURES[@]}"
  exit 1
fi
