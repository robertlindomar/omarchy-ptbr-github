# Auditoria de preparação para publicação — 07/11/2026

## Resultado

Integridade da centralização confirmada. As correções desta rodada foram revisadas por Reid e Thay. Nenhum push, instalação ou alteração na configuração ativa foi executado.

O HEAD do GitHub principal foi consultado: `c97c5727e77a07df498d90486f9fda68c5695a4e`, igual ao repositório atualizado usado como referência. Isso não verifica os HEADs dos repositórios individuais nem o selo atual de cada plugin.

## SUPER + SPACE

O atalho ativo abre `robertlindomar.omarchy-ptbr.launcher-plus`. O código desse plugin já está no GitHub principal. O atalho é configuração separada: agora está documentado no README e em `config/launcher-plus.bindings.lua.example`. O exemplo requer aplicação manual; o instalador nativo preserva atalhos existentes.

## Integridade e validações executadas

- Comparação SHA-256 da cópia central contra todos os arquivos instalados, exceto metadados Git: nenhuma perda ou diferença antes das correções. Foram adicionadas 16 imagens de apresentação.
- Conferência do conteúdo de 667 arquivos nos dois backups compactados contra suas origens: nenhuma divergência.
- 32 manifests aprovados por `omarchy plugin validate`; 41 scripts aprovados por `bash -n`. Os dois manifests afetados foram revalidados após restauração.
- Migração nativa: 3 testes aprovados.
- Launcher Plus PT-BR: 22 testes Python e duas suítes JavaScript aprovados.
- HODL: testes de modelo aprovados. Central de notificações: fixtures de armazenamento aprovadas.
- Gerenciador: plugin-state, update-helper e verification-status aprovados. O último teste foi atualizado para o helper atual de catálogo, com rede simulada e limite de 32 MiB.
- Teste Quickshell desacoplado aprovado em runtime isolado em /tmp com tema Qt genérico. A primeira tentativa falhou por limitações de runtime/DBus/display do sandbox. Não foi uma conferência visual da interface.
- Fixture de empacotamento: seleção de 24 clones, exclusão de terceiros, .git e backups, filtro por slug e preservação byte a byte de README e LICENSE aprovados.

## Correções realizadas

1. Restaurados `Panel.qml` e `SecurityBounds.js` de speedtest e disk-speedtest, idênticos ao repositório atualizado: a instalação local continha versões sem limites/watchdog. A revisão do diff não encontrou customizações perdidas nessa restauração.
2. Publicador individual restrito a `robertlindomar.omarchy-ptbr.*`; preserva README e LICENSE existentes e exclui backups, caches e metadados Git.
3. Adicionados exemplo de atalho e documentação; ampliadas exclusões de arquivos locais no .gitignore.

## Limites e preparação do commit

A pasta central contém 32 plugins para trabalho local. O publicador individual seleciona somente os 24 clones PT-BR; isso não confirma que todos os 24 sejam apropriados para republicar agora, pois inclui clones legados substituídos pelo PT-BR nativo. Não houve auditoria geral de todo o código ou de todos os serviços externos.

Existem seis repositórios .git aninhados nos outros oito plugins. Nenhum dos 24 clones PT-BR possui .git aninhado. Para o monorepo, preparar uma cópia limpa dos arquivos selecionados, preservando o histórico do repositório principal e excluindo .git aninhados, backups e dados locais. Não adicionar indiscriminadamente toda a pasta central ao índice.

A raiz central preserva os plugins instalados e ainda não é um repositório Git. O commit publicável é preparado separadamente com o histórico do GitHub, sem sobrescrever essas personalizações locais. Também não houve teste visual, instalação real, testes reais de autenticação, remoção de aplicativos ou operações externas.

O selo Verified do marketplace não é obtido por esta auditoria: exige o fluxo oficial sobre o commit publicado.

## Seleção final após revisão de publicação

A revisão rejeitou a publicação em bloco das diferenças instaladas: o painel de áudio filtra dispositivos por identificadores pessoais; clipboard, clock, lock e power retiram proteções existentes; menu perde suporte a itens desabilitados. Esses arquivos permanecem locais e NÃO integram o commit. `agents/assets/cursor.svg` e `clipboard/capture.sh`, adicionais da instalação local, também não integram esta atualização.

A seleção publicável parte do HEAD principal e inclui somente: `.gitignore`, `README.md`, `config/launcher-plus.bindings.lua.example`, `scripts/publish-plugins.sh`, `plugins/robertlindomar.omarchy-ptbr.plugin-manager/tests/verification-status-test.sh` e este relatório. Os demais plugins continuam nas versões já publicadas. As personalizações exigem reconciliação própria antes de eventual distribuição.
