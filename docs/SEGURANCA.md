# Auditoria de segurança — Omarchy PT-BR (publicação)

> Gerado na preparação do repositório público.

## Escopo

Varredura em `plugins/`, `overrides/`, `extensions/`, scripts e configs.

## Padrões procurados

- API keys (`sk-`, `ghp_`, `github_pat_`)
- `Bearer`, `Authorization`, `password=`, `secret=`, `api_key`
- Paths pessoais (`/home/robert`)
- SSIDs, MACs, IPs privados específicos

## Resultado

| Item | Status |
|------|--------|
| Segredos/tokens | **Não encontrados** nos artefatos publicados |
| `bindings.lua` pessoal | **Excluído** (atalhos são configuração do usuário) |
| Backups `.bak` / histórico | **Excluídos** |
| `extensions/omarchy-menu.jsonc` | Apenas labels pt-BR (sem credenciais) |
| `robertlindomar.omarchy-ptbr.agents/README.md` | Menciona `FIREWORKS_API_KEY` como **documentação upstream** — não contém valores |

## Arquivos excluídos da publicação

- `~/Documentos/omarchy-ptbr/backups/**`
- `~/.config/omarchy/extensions/*.bak.jsonc`
- `~/.config/hypr/bindings.lua` (overrides pessoais de teclas)
- `shell.json` com dados pessoais (usar `config/shell.json.example` genérico)

## Recomendações antes do push

1. Revisar `git diff` final
2. Não commitar `.env` ou state local
3. Após clonar em outra máquina, rodar `./install.sh --dry-run` primeiro
