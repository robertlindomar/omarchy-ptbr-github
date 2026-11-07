# Migração gradual para o PT-BR nativo

O Omarchy 4.5 lê `~/.config/omarchy/language` e observa mudanças em tempo real.
`pt-BR` seleciona o catálogo oficial `default/i18n/pt-BR/shell.json`; textos
ausentes usam o inglês como fallback. Isso configura o idioma da shell,
sem alterar o locale global do sistema.

1. **Idioma e plugins já oficiais:** começar só pelo idioma, conferir Elsewhen,
   workspaces, tray, teclado e demais componentes que já usam os IDs oficiais.
2. **Widgets simples:** migrar clock e indicators. Conferir formato do relógio,
   calendário, posição central e indicadores fixados.
3. **Painéis simples:** audio, bluetooth, network, power, weather e monitor.
   Conferir cada painel e suas ações. Esse é o limite do primeiro lote.
   Speedtest, disk-speedtest e reminders ficam para uma rodada posterior,
   embora o script já aceite esses nomes.
4. **Clipboard, polkit e menu:** revisar os clones e suas diferenças funcionais
   antes de trocar os IDs. Estes não são aceitos pelo script.
5. **Terceiros:** Omaclock, launcher, notification-center, HODL e outros precisam
   de seus próprios catálogos `i18n/pt-BR.json` e `Commons.Translations`.
   Ativar o idioma não traduz automaticamente textos fixos desses plugins.
6. **Notifications e lock:** comparar comportamento e integrações, testar
   notificações e o bloqueio antes de migrar; fora do script.
7. **Agents:** deixar por último, devido às integrações e customizações do clone.
   Comparar recursos e testar todos os fluxos antes de substituir.

## Uso

Na pasta que contém o script:

```bash
# Apenas prévia do idioma; nunca grava por padrão
python3 migrate-native.py

# Prévia do primeiro lote completo
python3 migrate-native.py --plugins clock indicators audio bluetooth network power weather monitor

# Aplicar só o idioma
python3 migrate-native.py --apply

# Aplicar um grupo pequeno depois de conferir a prévia
python3 migrate-native.py --plugins clock indicators --apply
```

`--plugins` aceita nomes separados por espaços ou vírgulas. Sem nomes, nenhuma
substituição de plugin acontece. Outros IDs são rejeitados. `--config-dir` e
`--omarchy-path` permitem validar uma cópia de configuração ou outra instalação.

O script confirma a existência do catálogo PT-BR e dos manifests oficiais.
Troca somente IDs selecionados em `plugins`, `bar.layout` e `centerAnchor`;
mantém as outras propriedades de cada item, inclusive formatos e cidades.
Remove os originais selecionados de `disabledPlugins`, acrescenta seus clones
nessa lista e remove esses clones de `cloneSourceRestores`. Os arquivos dos
clones continuam disponíveis para comparação e retorno.

Antes de gravar, cria backups dos dois arquivos com o mesmo timestamp UTC.
Se `language` não existia, um arquivo `.absent` registra essa condição.
As gravações individuais usam arquivo temporário e substituição atômica;
os dois arquivos não formam uma transação única. Para reverter, restaurar os
dois backups correspondentes, ou apagar `language` quando havia `.absent`.
O JSON pode ganhar nova indentação; suas propriedades e valores são preservados.

Após cada grupo, conferir visualmente barra e painéis, incluindo traduções
ausentes e diferenças funcionais dos clones. `shell.json` recarrega ao salvar;
não há reinício automático no script.
