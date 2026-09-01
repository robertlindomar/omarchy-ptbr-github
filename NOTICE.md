# Aviso legal — Omarchy PT-BR

## Upstream

- **Omarchy** — componentes oficiais em `/usr/share/omarchy`
- Manifests de plugins oficiais indicam licença **MIT** (ex.: `omarchy.agents`, `omarchy.disk-speedtest`)
- Versão de referência deste repositório: ver `docs/COMPATIBILIDADE.md`

## Este repositório

- Contém **traduções pt-BR** e **clones** (`robert.*`) derivados dos plugins oficiais
- As traduções são mudanças de texto/UX; lógica, IPC e comandos são preservados
- **Não** inclui cópia completa do Omarchy — requer instalação oficial prévia

## Redistribuição

Ao publicar clones derivados:

1. Mantenha o bloco `omarchy.clonedFrom` em cada `manifest.json`
2. Preserve avisos de copyright MIT do upstream quando aplicável
3. Deixe claro que é tradução **não oficial**

## Licença recomendada (pendente de revisão)

Antes de adicionar `LICENSE` na raiz, confirme a licença global do projeto Omarchy com os mantenedores.

**Sugestão provisória:** MIT para scripts/instalador próprios; traduções nos clones sob mesma licença do upstream + este NOTICE.

## Dados excluídos da publicação

- Backups pessoais (`omarchy-ptbr/backups/`)
- `bindings.lua` pessoal (atalhos customizados)
- Arquivos `.bak` de extensões
- Históricos, logs e credenciais
