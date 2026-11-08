# PT-BR nativo no Omarchy 4.5

O modo recomendado usa os plugins oficiais atualizados e o catálogo PT-BR do
próprio Omarchy. Não modifica `/usr/share/omarchy`. O idioma da shell muda ao vivo;
o locale global do sistema e o idioma de aplicativos já abertos não são alterados.

## Ordem de execução e resultado

1. Idioma, Elsewhen e demais componentes oficiais: PT-BR ativado.
   Veja a [prévia e a origem do relógio mundial Elsewhen](ELSEWHEN-PTBR.md).
2. Relógio e indicadores: migrados, preservando formato, posição e itens fixados.
3. Áudio, Bluetooth, rede, energia, clima, monitor, testes de velocidade e lembretes: migrados.
4. Clipboard, polkit e menu: migrados para as implementações oficiais atuais.
5. Terceiros: OmaClock, gerenciador, aplicativos/favoritos e hyprmoncfg revisados;
   HODL e Launcher Plus incluídos no repo com tradução e licenças preservadas.
6. Notificações e bloqueio: migrados; a central foi adaptada ao armazenamento
   Notifications 2.0 antes de trocar o daemon.
7. Agentes: migrado para a versão oficial com todos os novos provedores.
   A preferência do clone de ocultar Cursor é mantida; escolha explícita do usuário prevalece.

Os clones nativos antigos ficam no disco, desabilitados, para comparação. O estado
pessoal de favoritos, agentes, carteiras e histórico continua nas mesmas pastas;
não é distribuído neste repositório. Não são habilitados serviços externos novos
nem configuradas contas de terceiros.

## Instalação e verificação

```bash
./install.sh --dry-run
./install.sh
./scripts/verify-install.sh
```

Quando existe o catálogo `/usr/share/omarchy/default/i18n/pt-BR/shell.json`, o
instalador escolhe o modo nativo automaticamente. `--native` o exige; `--legacy`
é reservado à implementação antiga, anterior à tradução nativa.

Ao aplicar, o instalador reinicia a shell para liberar os serviços antigos e
recarrega o Hyprland. O modo nativo atualiza sete plugins comunitários e mapeia referências existentes
para seus clones PT-BR. Preserva todas as seções da barra e suas configurações.
Redireciona apenas os IDs dos plugins nos atalhos existentes; não impõe um novo
atalho de launcher. Os clones disponíveis mas sem referência não são ativados.

Os overrides legados de capturas, atalhos, lembretes e uso de agentes só são
arquivados se seus bytes forem idênticos à cópia deste repo e houver comando
oficial correspondente. O coletor antigo exclusivo de Cursor também é arquivado.
Overrides personalizados diferentes são preservados e informados no relatório.

Para uma migração parcial, sem instalar os plugins comunitários:

```bash
python3 scripts/migrate-native.py --plugins clock indicators       # simulação
python3 scripts/migrate-native.py --plugins clock indicators --apply
```

Sem `--apply`, os scripts Python não gravam. Sem `--plugins`, migrate-native.py
seleciona apenas o idioma. `--all-reviewed` inclui os 17 plugins nativos revisados;
`--retire-overrides` habilita o arquivamento dos comandos legados conhecidos.

## Backups e reversão

A instalação comunitária guarda cópias dos plugins, shell.json e bindings.lua em
`~/.local/state/omarchy-ptbr/backups/native-<timestamp>/` (respeita XDG_STATE_HOME).
O script nativo cria `shell.json.bak.<timestamp>` e `language.bak.<timestamp>` ao
lado dos arquivos originais. `.absent` registra que o arquivo ainda não existia.
Os overrides arquivados permanecem como `<comando>.bak.<timestamp>` na mesma pasta.

Para reverter, restaure as cópias do lote correspondente, incluindo os plugins e
bindings.lua quando houver alteração. Se language tinha marcador `.absent`, remova
apenas o arquivo language criado pela migração. Recarregue plugins e Hyprland.
A escrita de cada configuração é atômica; a instalação completa não é transacional.

O `uninstall.sh` antigo é específico do modo legado e não deve ser usado como
reversor da migração nativa; use os backups descritos acima.

## Validação e limites

Foram verificados os manifests, sintaxe dos scripts, preservação da configuração,
idempotência, favoritos/carteiras e o fluxo de armazenamento da central com fixtures.
A central suporta arquivos legados e arrays live/history, evita duplicatas e mantém
exclusões sem modificar as fontes oficiais. Um envio real confirmou a entrada no histórico.

Os painéis de Elsewhen, Agentes, central e launcher foram conferidos visualmente.
Bloqueio/autenticação, pagamentos, instalações e remoções de aplicativos não foram
acionados como testes. Os textos de notícias, nomes de aplicativos, cidades e
mensagens de serviços externos continuam no idioma da fonte. As traduções oficiais
são mantidas pelo Omarchy; sugestões de redação devem ser feitas no catálogo upstream.

O catálogo do gerenciador cresceu além do antigo limite de 8 MiB. O helper novo
baixa de HTTPS com limite de 32 MiB e prazo de 25 segundos, e entrega ao QML
apenas os metadados dos selos (cerca de 2 MiB na verificação desta rodada).
