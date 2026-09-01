# Implementação — Omarchy PT-BR Fase 1A

> Data: 2026-08-31  
> Escopo: `robertlindomar.omarchy-ptbr.menu` (tradução) + `robertlindomar.omarchy-ptbr.lock` (clone preparado, **não ativado**)

---

## robertlindomar.omarchy-ptbr.menu

### Entry point confirmado

```json
"entryPoints": {
  "menu": "Menu-v2.qml",
  "barWidget": "BarWidget.qml"
}
```

Fonte: `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.menu/manifest.json`

### IDs duplicados

- Busca em `~/.config/omarchy/plugins/**/manifest.json`: **apenas um** `robertlindomar.omarchy-ptbr.menu`
- Backup anterior fora de `plugins/` (conforme auditoria)

### Arquivos alterados

| Arquivo | Linhas | Alteração |
|---------|--------|-----------|
| `Menu-v2.qml` | 827 | `Input`/`Select` → `Entrada`/`Selecionar` |
| `Menu-v2.qml` | 1130–1131 | diálogo uninstall |
| `Menu-v2.qml` | 1163 | fallback header `Go` → `Ir` |
| `Menu-v2.qml` | 1414 | estado vazio / sem resultados |
| `MenuModel.js` | 89 | label root `Go` → `Ir` |

**Não alterado:** `Menu.qml` (não é entry point ativo)

### Strings — antes → depois

| Inglês | Português |
|--------|-----------|
| `Nothing here yet` | `Nada por aqui ainda` |
| `No matches for "…"` | `Nenhum resultado para "…"` |
| `Input` | `Entrada` |
| `Select` | `Selecionar` |
| `Do you want to uninstall …?` | `Deseja desinstalar …?` |
| `Uninstall` | `Desinstalar` |
| `Go` | `Ir` |

### Backup

`~/Documentos/omarchy-ptbr/backups/robertlindomar.omarchy-ptbr.menu-2026-08-31-201747/`

Diffs salvos no mesmo diretório:
- `diff-menu-v2`
- (MenuModel: ver diff abaixo)

### Testes executados

| Teste | Resultado |
|-------|-----------|
| `omarchy plugin validate robertlindomar.omarchy-ptbr.menu` | OK (sem erros) |
| Entry point `Menu-v2.qml` no manifest | OK |
| IDs duplicados em `plugins/` | Nenhum |
| Strings EN remanescentes em runtime | Apenas comentário linha 249 (não visível) |
| `omarchy-shell` reload | Shell **não estava em execução** neste ambiente |
| Teste visual menu | **Pendente — usuário** (abrir menu após reload do shell) |

### Recarregar menu (manual)

```bash
# Opção segura: reiniciar só o shell Omarchy
omarchy-restart-shell

# Ou, se o shell já estiver rodando:
omarchy-shell shell reloadPlugins
```

### Checklist visual (usuário)

- [ ] Menu raiz abre com itens pt-BR
- [ ] Submenu funciona
- [ ] Busca sem resultados → `Nenhum resultado para "…"`
- [ ] Categoria vazia → `Nada por aqui ainda`
- [ ] Modo Input → placeholder `Entrada…`
- [ ] Modo Select → placeholder `Selecionar…`
- [ ] Diálogo uninstall → `Deseja desinstalar …?` / botão `Desinstalar`
- [ ] Header raiz → `Ir…` (quando aplicável)

---

## robertlindomar.omarchy-ptbr.lock

### Plugin oficial

| Campo | Valor |
|-------|-------|
| ID | `omarchy.lock` |
| Path | `/usr/share/omarchy/shell/plugins/lock/` |
| Entry point | `service=Service.qml` |
| Kind | `service` |
| Arquivos | `Service.qml`, `LockView.qml`, `manifest.json` |

### Strings user-facing encontradas (oficial)

| Arquivo | String | Categoria |
|---------|--------|-----------|
| `LockView.qml:20` | `Enter Password` | placeholder |
| `LockView.qml:189` | `Checking…` | estado autenticação |
| `Service.qml:205` | `Authentication failed (N)` | erro dinâmico |

**Não encontradas** no lock: caps lock, botões nomeados, unlock explícito (desbloqueio é Enter/senha).

### Dependências do clone

- **Imports QML:** `qs.Commons`, `qs.Ui` (shell compartilhado — não copiados)
- **LockView:** componente local no mesmo diretório
- **PAM:** `/etc/pam.d/omarchy-lock-password`, `omarchy-lock-fingerprint` (inalterados)
- **IPC:** `IpcHandler { target: "lock" }` — mantido igual ao oficial (roteamento do shell)
- **Processos externos:** `omarchy-system-wake`, `omarchy-hyprland-session-locked`, etc.
- **Sem** imagens/recursos locais adicionais

### Estratégia de clone

- Clone manual em `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.lock/`
- ID: `robertlindomar.omarchy-ptbr.lock`
- `clonedFrom: omarchy.lock`
- **Não ativado** — `omarchy.lock` continua ativo

### Arquivos clonados

```
robertlindomar.omarchy-ptbr.lock/
├── manifest.json
├── Service.qml
└── LockView.qml
```

### Traduções aplicadas

| Inglês | Português | Arquivo |
|--------|-----------|---------|
| `Enter Password` | `Digite a senha` | LockView.qml |
| `Checking…` | `Verificando…` | LockView.qml |
| `Authentication failed (N)` | `Falha na autenticação (N)` | Service.qml |

### Como o Omarchy seleciona o lock

1. Plugins `kind: service` first-party são **implicitamente habilitados** salvo entrada em `disabledPlugins[]`.
2. `_syncServices()` em `shell.qml` carrega **cada** service habilitado.
3. Lock é acionado via IPC `omarchy-shell lock lock` (target `"lock"`), **não** por ID de plugin.
4. `resolveEnabledId()` roteia summons de plugins clonados, mas o lock usa IPC fixo `"lock"`.
5. **Risco crítico:** se `omarchy.lock` e `robertlindomar.omarchy-ptbr.lock` estiverem **ambos habilitados**, dois `IpcHandler` com target `"lock"` e dois `WlSessionLock` podem conflitar.

### Ativação (NÃO executada — aguardar teste manual)

```bash
# 1. Verificar que o clone existe e valida
omarchy plugin validate ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.lock

# 2. Ativar clone (desabilita omarchy.lock automaticamente)
omarchy plugin enable robertlindomar.omarchy-ptbr.lock

# 3. Recarregar shell
omarchy-restart-shell
# ou: omarchy-shell shell reloadPlugins

# 4. Verificar estado
jq '.disabledPlugins, .plugins' ~/.config/omarchy/shell.json
# Esperado: "omarchy.lock" em disabledPlugins; robertlindomar.omarchy-ptbr.lock em plugins[]

# 5. Teste SEGURO — preview visual (não bloqueia sessão)
omarchy-shell lock preview
# Clicar para fechar ou:
omarchy-shell lock hidePreview

# 6. Teste REAL — bloqueia a sessão (só quando confiante)
omarchy-system-lock
```

### Reversão

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.lock   # restaura omarchy.lock se cloneSourceRestores
omarchy-restart-shell
```

### Riscos

| Risco | Nível | Mitigação |
|-------|-------|-----------|
| Dois locks simultâneos | **Alto** | Sempre desabilitar oficial ao ativar clone |
| Sessão inacessível após lock | Médio | Testar `preview` antes de `lock` |
| PAM incorreto | Baixo | Não alteramos configs PAM |
| IPC duplicado | Alto | Nunca manter ambos enabled |

### Testes executados

| Teste | Resultado |
|-------|-----------|
| `omarchy plugin validate robertlindomar.omarchy-ptbr.lock` | OK |
| Strings EN no clone | Nenhuma |
| Imports/caminhos relativos | OK (LockView local + qs.*) |
| Ativação | **Não executada** (por design) |
| Preview/lock runtime | **Pendente — usuário** |

---

## Integridade

| Verificação | Resultado |
|-------------|-----------|
| `/usr/share/omarchy` modificado | **NÃO** |
| IDs duplicados em `plugins/` | **Nenhum** |
| Erros QML (validate) | **Nenhum** |
| Logs do shell | Shell não estava rodando |

---

## robertlindomar.omarchy-ptbr.polkit (Fase 1B)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/polkit/` |
| ID | `omarchy.polkit` |
| Versão | `1.0.0` |
| Entry point | `service=PolkitAgent.qml` |
| Kind | `service` (`keepLoaded: true`) |

### Arquivos do oficial

| Arquivo | Função |
|---------|--------|
| `PolkitAgent.qml` | Entry point — UI do diálogo + registro DBus |
| `PolkitModel.js` | Helpers: PAM fingerprint, `authorizationLabel()` |
| `manifest.json` | Metadados |

**Sem** recursos/assets adicionais. **Sem** IPC handler separado (`IpcHandler`).

### Imports e dependências

- `qs.Commons`, `qs.Ui` (shell compartilhado)
- `Quickshell.Services.Polkit` — componente `PolkitAgent` com DBus
- `PolkitModel.js` — import local relativo
- `/etc/pam.d/polkit-1` — FileView (somente leitura)
- `omarchy-hw-laptop-closed` — Process externo

### DBus / registro

```qml
PolkitAgent {
  path: "/org/omarchy/PolkitAgent"
}
```

- **Não alterado** no clone (obrigatório para o agente registrar no sistema)
- `WlrLayershell.namespace: "omarchy-polkit"` — inalterado
- Log: `"omarchy polkit agent registered"` / warn se outro agente ativo

### Strings user-facing encontradas (oficial)

| # | String | Arquivo | Linha | Origem | Classificação |
|---|--------|---------|-------|--------|---------------|
| 1 | `Authentication is needed...` | PolkitAgent.qml | 81 | fallback QML | fixa, traduzível |
| 2 | `Enter password` | PolkitAgent.qml | 339 | placeholder UI | fixa, traduzível |
| 3 | `Checking...` | PolkitAgent.qml | 339 | estado UI | fixa, traduzível |
| 4 | `Wrong` | PolkitAgent.qml | 339 | erro UI | fixa, traduzível |
| 5 | `Authorize running '…'` | PolkitModel.js | 23 | template JS | dinâmica, traduzível |
| 6 | `flow.message` | PolkitAgent.qml | 81 | Polkit/DBus | dinâmica, preservar se não casar regex |
| 7 | `flow.inputPrompt` | PolkitAgent.qml | 82 | Polkit/DBus | sincronizada, **não exibida** na UI atual |
| 8 | `flow.supplementaryMessage` | PolkitAgent.qml | 83 | Polkit/DBus | sincronizada, **não exibida** na UI atual |

**Não encontradas** no plugin: botões Cancel/Confirm, Retry, labels de usuário/aplicação separados.

### Strings traduzidas

| Antes | Depois | Arquivo |
|-------|--------|---------|
| `Authentication is needed...` | `Autenticação necessária...` | PolkitAgent.qml:81 |
| `Enter password` | `Digite a senha` | PolkitAgent.qml:339 |
| `Checking...` | `Verificando…` | PolkitAgent.qml:339 |
| `Wrong` | `Incorreto` | PolkitAgent.qml:339 |
| `Authorize running 'X'` | `Autorizar execução de 'X'` | PolkitModel.js:23 |

### Strings dinâmicas preservadas

- Mensagens Polkit que **não** casam com o regex inglês → passam intactas (`authorizationLabel` retorna `text`)
- Regex de entrada mantido em inglês (Polkit envia mensagens em EN)
- `flow.inputPrompt`, `flow.supplementaryMessage` — inalterados (não renderizados)
- Path DBus `/org/omarchy/PolkitAgent` — inalterado
- Nomes de apps/comandos dentro de aspas na mensagem Polkit — preservados

### Clone

| Campo | Valor |
|-------|-------|
| Caminho | `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.polkit/` |
| ID | `robertlindomar.omarchy-ptbr.polkit` |
| `clonedFrom` | `omarchy.polkit` |

Arquivos clonados: `manifest.json`, `PolkitAgent.qml`, `PolkitModel.js`

### Segurança da ativação

| Pergunta | Resposta |
|----------|----------|
| `enable robertlindomar.omarchy-ptbr.polkit` desabilita `omarchy.polkit`? | **Sim** — `PluginRegistry.setEnabled` adiciona oficial a `disabledPlugins[]` |
| Dois agentes simultâneos? | **Risco alto** — ambos registram `path: "/org/omarchy/PolkitAgent"`; log avisa *"another agent may be running"* |
| IPC targets conflitantes? | Não há IpcHandler; conflito é no **registro DBus Polkit** |
| Risco de ficar sem autenticação? | Médio — se clone falhar ao carregar, `pkexec`/sudo gráfico pode não ter agente |
| Reversão | `omarchy plugin disable robertlindomar.omarchy-ptbr.polkit` → restaura `omarchy.polkit` via `cloneSourceRestores` |

### Ativação (não executada)

```bash
omarchy plugin validate ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.polkit
omarchy plugin enable robertlindomar.omarchy-ptbr.polkit
omarchy-restart-shell

# Verificar
jq '.disabledPlugins, .plugins' ~/.config/omarchy/shell.json
# Esperado: "omarchy.polkit" em disabledPlugins; robertlindomar.omarchy-ptbr.polkit em plugins[]
```

### Teste manual seguro (após ativar)

```bash
# Solicita autenticação gráfica reversível (só pede senha, não altera nada):
pkexec true

# Cancelar com Escape deve fechar o diálogo sem efeitos.
```

**Não existe** preview isolado do Polkit (diferente do lock).

### Rollback

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.polkit
omarchy-restart-shell
# omarchy.polkit deve voltar a disabledPlugins sem entrada (restaurado)
```

### Testes executados

| Teste | Resultado |
|-------|-----------|
| `omarchy plugin validate robertlindomar.omarchy-ptbr.polkit` | OK |
| Diff vs oficial | Apenas traduções (+ comentário em PolkitModel.js) |
| IDs duplicados | Nenhum |
| Strings EN no clone | Nenhuma |
| Ativação | **Não executada** |
| Teste visual `pkexec` | **Pendente — usuário** |

### Backup de referência

`~/Documentos/omarchy-ptbr/backups/omarchy.polkit-official-2026-08-31/`

---

## robertlindomar.omarchy-ptbr.clipboard (Fase 1C)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/clipboard/` |
| ID | `omarchy.clipboard` |
| Versão | `1.0.0` |
| Entry point | `overlay=Clipboard.qml` |
| Kind | `overlay` (`keepLoaded: true`) |

### Arquivos

| Arquivo | Função |
|---------|--------|
| `Clipboard.qml` | Entry point — overlay UI |
| `ClipboardHistory.js` | Parsing, histórico, preview labels |
| `capture.sh` | Captura wl-clipboard → JSON (**permanece no path oficial**) |
| `manifest.json` | Metadados |

**Clone não inclui `capture.sh`** — `Clipboard.qml` referencia `OMARCHY_PATH/shell/plugins/clipboard/capture.sh` (oficial, intencional).

### Strings user-facing encontradas

| # | String | Arquivo | Classificação |
|---|--------|---------|---------------|
| 1 | `Delete entire clipboard history?` | Clipboard.qml:406 | fixa |
| 2 | `Delete` | Clipboard.qml:407 | fixa (confirmText) |
| 3 | `Search clipboard…` | Clipboard.qml:439 | fixa (placeholder) |
| 4 | `Clipboard is empty` | Clipboard.qml:600 | fixa |
| 5 | `No matches for "…"` | Clipboard.qml:600 | dinâmica traduzível |
| 6 | `Image` | ClipboardHistory.js:139 | fixa (preview) |
| 7 | `Screenshot` / `Image from …` | ClipboardHistory.js:141-142 | dinâmica traduzível |
| 8 | `N files` | ClipboardHistory.js:134 | dinâmica traduzível |

**Preservadas (não traduzidas):**

- `searchableText`: `"image screenshot "` — índice de busca interno
- `captureScript`, paths, comandos `wl-paste`, `pkill`, bins `omarchy-clipboard-*`
- `WlrLayershell.namespace: "omarchy-clipboard"`
- Conteúdo real copiado pelo usuário
- `Cancel`/`Confirm` do `ConfirmDialog` compartilhado (`shell/Ui/`)

### Traduções aplicadas

| Antes | Depois |
|-------|--------|
| `Delete entire clipboard history?` | `Excluir todo o histórico da área de transferência?` |
| `Delete` | `Excluir` |
| `Search clipboard…` | `Pesquisar área de transferência…` |
| `Clipboard is empty` | `Área de transferência vazia` |
| `No matches for "…"` | `Nenhum resultado para "…"` |
| `Image` | `Imagem` |
| `Screenshot` | `Captura de tela` |
| ` from ` | ` de ` |
| `N files` | `N arquivos` |

### Comandos externos (inalterados)

| Comando | Uso |
|---------|-----|
| `wl-paste --watch … capture.sh` | Captura texto/imagem |
| `pkill -f wl-paste.*capture.sh` | Reinicia watchers no init |
| `setpriv --pdeathsig TERM wl-paste …` | Watchers com auto-kill |
| `omarchy-clipboard-paste-text` | Colar/copiar texto |
| `omarchy-clipboard-paste-file` | Colar/copiar imagem |
| `omarchy-clipboard-open` | Abrir item (Alt+Enter) |

Histórico: `~/.local/state/omarchy/clipboard-history.json`  
Imagens: `~/.local/state/omarchy/clipboard-images/`

### Segurança da ativação

| Pergunta | Resposta |
|----------|----------|
| `enable` desabilita oficial? | **Sim** — `disabledPlugins` + `plugins[]` |
| Dois overlays simultâneos? | **Risco alto** — duplicam watchers `wl-paste` no mesmo `capture.sh` |
| IPC target? | Nenhum `IpcHandler`; toggle via `shell toggle omarchy.clipboard` |
| Shortcut | `SUPER+CTRL+V` → `omarchy-shell shell toggle omarchy.clipboard` (roteado ao clone via `resolveEnabledId`) |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.clipboard` + restart shell |

### Ativação (não executada)

```bash
omarchy plugin validate ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.clipboard
omarchy plugin enable robertlindomar.omarchy-ptbr.clipboard
omarchy-restart-shell
```

### Teste visual (após ativar)

```bash
# Atalho padrão Omarchy:
# SUPER + CTRL + V

# Ou via shell:
omarchy-shell shell toggle omarchy.clipboard
```

Validar: abertura, busca, vazio, sem resultados, texto, imagem, Enter/Shift+Enter/Alt+Enter, Delete item, Shift+Delete confirmação (não confirmar limpar tudo).

### Backup de referência

`~/Documentos/omarchy-ptbr/backups/omarchy.clipboard-official-2026-08-31/`

---

## Próximo passo recomendado

1. Ativar e testar `robertlindomar.omarchy-ptbr.reminders`
2. Fase 2: painéis (network, bluetooth, etc.) ou `shell/Ui/`

---

## robertlindomar.omarchy-ptbr.reminders (Fase 1D)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/reminders/` |
| ID | `omarchy.reminders` |
| Entry point | `overlay=ReminderFlow.qml` |
| Arquivos | `ReminderFlow.qml`, `ReminderFlowModel.js`, `manifest.json` |

### Strings traduzidas (ReminderFlow.qml)

| Antes | Depois | Linha |
|-------|--------|-------|
| `Remind in minutes` | `Lembrar em minutos` | 31 |
| `Reminder message` | `Mensagem do lembrete` | 31 |
| `Invalid reminder` | `Lembrete inválido` | 77 |
| `Enter the number of minutes` | `Digite o número de minutos` | 77 |
| `...` (placeholder) | `…` | 163 |

### Strings preservadas / fora do clone

- `step: "minutes"` / `"message"` — chaves lógicas
- `omarchy-reminder` CLI — **traduzido** via override em `~/.local/bin/omarchy-reminder` (ver seção abaixo)
- Tooltips da barra — **traduzidos** via `omarchy-reminder show --json` do override
- `shell/Ui/` — não usado neste plugin

### Datas/horários

Plugin **não formata datas** — fluxo em 2 passos (minutos + mensagem). Horários em notificações vêm de `omarchy-reminder` (bin), não do clone.

### Persistência (inalterada)

- Mensagens: `$XDG_RUNTIME_DIR/omarchy-reminders/omarchy-reminder-*.message` (texto puro)
- Timers: `systemd --user` units `omarchy-reminder-{N}m-{timestamp}.timer`
- Schema **não alterado**

### Abertura / resolveEnabledId

- `omarchy-reminder -i` → `omarchy-shell shell summon omarchy.reminders` → `resolveEnabledId` → `robertlindomar.omarchy-ptbr.reminders` quando ativo
- Atalho barra: clique no indicador 󰢌 (sem lembretes → `-i`)
- Hyprland: `SUPER+CTRL+ALT+R` → `omarchy-reminder show` (lista, não overlay)

### Ativação (não executada)

```bash
omarchy plugin validate ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.reminders
omarchy plugin enable robertlindomar.omarchy-ptbr.reminders
omarchy-restart-shell
omarchy-reminder -i   # teste do overlay traduzido
```

### Rollback

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.reminders
omarchy-restart-shell
```

### Backup

`~/Documentos/omarchy-ptbr/backups/omarchy.reminders-official-2026-08-31/`

---

## omarchy-reminder user override (Fase 1E)

> Data: 2026-08-31  
> Override ativo em `~/.local/bin/omarchy-reminder`

### Script oficial

| Campo | Valor |
|-------|-------|
| Caminho | `/usr/share/omarchy/bin/omarchy-reminder` |
| Linguagem | Bash |
| Backup | `~/Documentos/omarchy-ptbr/backups/omarchy-reminder-bin-2026-08-31/omarchy-reminder` |
| Diff completo | `~/Documentos/omarchy-ptbr/backups/omarchy-reminder-bin-2026-08-31/omarchy-reminder.diff` |

### Strings user-facing encontradas (oficial)

| Contexto | String EN |
|----------|-----------|
| `show` (vazio) | `Upcoming reminders` / `No outstanding reminders` |
| `show` (corpo, com mensagem) | `$msg in Xm Ys (HH:MM)` |
| `show` (corpo, sem mensagem) | `${N}-min reminder in Xm Ys (HH:MM)` |
| `show --json` tooltip vazio | `Set Reminder` |
| `show --json` tooltip 1/N | `1 reminder` / `$count reminders` |
| `show --json` label sem mensagem | `${N}-min reminder` |
| `clear` | `All reminders have been cleared` |
| Criação (sem mensagem custom) | `Your ${N} minutes are up` |
| Criação (confirmação) | `You'll be reminded at HH:MM` |
| Criação (título sem custom) | `Reminder set for ${N} minutes` |
| Criação (título com custom) | `$msg in ${N} minutes` |
| **Timer systemd (notificação final)** | **título fixo `"Reminder"`** — linha 198 |
| `usage()` | textos de ajuda CLI |

### Origem do título `Reminder` na notificação final

**Não** é default de `omarchy-notification-send`. É string fixa embutida no `systemd-run` ao criar o lembrete:

```bash
# /usr/share/omarchy/bin/omarchy-reminder:197-198 (oficial)
systemd-run ... bash -c 'omarchy-notification-send -g 󰢌 "Reminder" "$1"; rm -f "$2"; ...' bash "$message" "$message_file"
```

- **Título:** `"Reminder"` (1º argumento posicional de `omarchy-notification-send`)
- **Corpo:** `$1` = mensagem do usuário (ou default `Your N minutes are up`)
- O timer **não** reinvoca `omarchy-reminder`; executa o comando acima literalmente

**Correção no override:** `"Reminder"` → `"Lembrete"` na mesma linha do `systemd-run`.

### PATH

**Problema:** no shell interativo, `~/.local/bin` pode vir primeiro; na sessão gráfica Omarchy, `default/hypr/envs.lua` **prepende** `$OMARCHY_PATH/bin` (`/usr/share/omarchy/bin`) ao PATH — então `omarchy-reminder` sem caminho absoluto resolve para o **oficial**.

```text
# Antes da correção (processo do shell):
PATH=/usr/share/omarchy/bin:…:~/.local/bin:…
```

**Correções aplicadas:**

1. `robertlindomar.omarchy-ptbr.reminders/ReminderFlow.qml` — `reminderBin = HOME + "/.local/bin/omarchy-reminder"` (caminho absoluto ao override)
2. `~/.config/hypr/envs.lua` — reordena PATH para `~/.local/bin` antes de `$OMARCHY_PATH/bin` (indicador da barra, atalhos Hyprland)
3. `~/.config/hypr/hyprland.lua` — `require("hypr.envs")` após defaults Omarchy

Após `hyprctl reload` + `omarchy-restart-shell`:

```text
PATH=~/.local/bin:/usr/share/omarchy/bin:…
```

### Estratégia escolhida

**B — clone do script** em `~/.local/bin/omarchy-reminder` (não wrapper).

Motivo: strings de notificação (incluindo título final) são geradas **dentro** do script no momento da criação e embutidas no unit systemd. Wrapper que só traduz stdout não cobriria timers.

Lógica, argumentos, paths, units, `.message`, JSON keys e integração com `omarchy-notification-send` / `omarchy-shell` **inalterados**.

### Override criado

| Campo | Valor |
|-------|-------|
| Caminho | `~/.local/bin/omarchy-reminder` |
| Tipo | Clone traduzido (executável) |
| Recursão | N/A — não delega ao original |

### Ajuste complementar: `robertlindomar.omarchy-ptbr.reminders`

O overlay original usava `root.omarchyPath + "/bin/omarchy-reminder"` (oficial). Tentativa com `["omarchy-reminder"]` falhou na sessão gráfica porque o PATH do Hyprland prioriza `/usr/share/omarchy/bin`.

**Solução:** `property string reminderBin: Quickshell.env("HOME") + "/.local/bin/omarchy-reminder"` em `ReminderFlow.qml`.

### Traduções aplicadas

| Antes | Depois |
|-------|--------|
| `Upcoming reminders` | `Próximos lembretes` |
| `No outstanding reminders` | `Nenhum lembrete pendente` |
| `$msg in …` | `$msg em …` |
| `${N}-min reminder in …` | `Lembrete de ${N} min em …` |
| `Set Reminder` | `Criar lembrete` |
| `1 reminder` / `N reminders` | `1 lembrete` / `N lembretes` |
| `${N}-min reminder` (label JSON) | `Lembrete de ${N} min` |
| `All reminders have been cleared` | `Todos os lembretes foram removidos` |
| `Your 1 minute is up` | `Seu 1 minuto terminou` |
| `Your N minutes are up` | `Seus N minutos terminaram` |
| `You'll be reminded at HH:MM` | `Você será lembrado às HH:MM` |
| `Reminder set for N minutes` | `Lembrete definido para N minutos` |
| `$msg in N minutes` | `$msg em N minutos` / `$msg em 1 minuto` |
| **`Reminder` (título notificação final)** | **`Lembrete`** |
| `usage()` | `Uso: …` em pt-BR |

### Pluralização pt-BR

Somente na camada visual (`if ((minutes == 1))`); valor numérico do timer inalterado.

- `1 minuto` / `N minutos`
- `1 lembrete` / `N lembretes`
- `Seu 1 minuto terminou` / `Seus N minutos terminaram`

### Timers systemd

| Pergunta | Resposta |
|----------|----------|
| Comando no unit | `bash -c 'omarchy-notification-send … "Lembrete" "$1"; …'` (gerado na criação) |
| PATH ou absoluto? | Chama `omarchy-notification-send` via PATH; **não** reinvoca `omarchy-reminder` |
| Timers antigos | **Não afetados** — mantêm `"Reminder"` embutido até expirarem ou `clear` |
| Timers novos | **Afetados** — título `Lembrete` e corpo traduzido |

### JSON / indicador da barra

- `show --json`: estrutura preservada (`count`, `active`, `tooltip`, `reminders[]` com `unit`, `timer`, `minutes`, `message`, `label`, `remaining`, `remainingSeconds`, `at`, `atTime`)
- Apenas valores visuais traduzidos (`tooltip`, `label`, `remaining`)
- `Reminder.qml` da barra: **sem strings próprias**; consome JSON via PATH → **não precisa clone**

### Testes executados

| Teste | Resultado |
|-------|-----------|
| `type -a omarchy-reminder` | `~/.local/bin` primeiro ✓ |
| `omarchy-reminder 1 aaa-teste-ptbr` | Unit com `"Lembrete"` no ExecStart ✓ |
| Timer concluído (~1 min) | Unit disparou; indicador zerou ✓ |
| `show --json` | JSON válido; `tooltip: "Criar lembrete"` / `"1 lembrete"` ✓ |
| `clear` | Funciona; tooltip volta a `Criar lembrete` ✓ |
| Notificação inicial/final (GUI) | Pendente confirmação visual do usuário |

### Integridade

| Item | Modificado? |
|------|-------------|
| `/usr/share/omarchy` | **NÃO** |
| Persistência (`omarchy-reminders/`, `.message`) | **NÃO** (schema igual) |
| Timers existentes | **NÃO** (não alterados automaticamente) |

### Rollback

```bash
mv ~/.local/bin/omarchy-reminder ~/.local/bin/omarchy-reminder.disabled
hash -r   # se hashing estiver habilitado no shell
type -a omarchy-reminder   # deve voltar para /usr/share/omarchy/bin/…
```

Reverter `robertlindomar.omarchy-ptbr.reminders/ReminderFlow.qml` para caminho absoluto apenas se quiser desativar o override mas manter o clone do overlay.

### Diff exato (resumo)

Ver arquivo completo em `backups/omarchy-reminder-bin-2026-08-31/omarchy-reminder.diff`. Trecho crítico do título final:

```diff
-systemd-run ... bash -c 'omarchy-notification-send -g 󰢌 "Reminder" "$1"; rm -f "$2"; ...'
+systemd-run ... bash -c 'omarchy-notification-send -g 󰢌 "Lembrete" "$1"; rm -f "$2"; ...'
```

### Status

- **Pronto** para uso (override + ajuste do overlay)
- **Pendência:** confirmação visual das notificações GUI (`aaa em 1 minuto` / título `Lembrete` + corpo `aaa`)
- Timers criados **antes** do override continuam com título `Reminder` até expirarem

---

## robertlindomar.omarchy-ptbr.network (Fase 2A)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/network/` |
| ID | `omarchy.network` |
| Versão | `1.0.0` |
| Entry point | `barWidget` → `Panel.qml` |
| Tipo | `bar-widget` (ícone na barra + painel popup) |
| Arquivos | `manifest.json`, `Panel.qml`, `Model.js` |
| Backup | `~/Documentos/omarchy-ptbr/backups/omarchy.network-official-2026-08-31/` |
| Diffs | `Model.diff`, `Panel.diff` no backup |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **Wi-Fi / NM** | `Quickshell.Networking` com `NetworkBackendType.NetworkManager` |
| **DBus** | Via backend Quickshell (`Networking.devices`, `WifiDevice`, `WifiNetwork`) — **não alterado** |
| **Comandos externos** | `omarchy-network-status --verbose`, `omarchy-dns`, `omarchy-network-band`, `nmcli` (enterprise via script em `Model.js`) |
| **IPC** | `IpcHandler` target `omarchy.network` (open/close/toggle/toggleNetwork/showQr/speedTest) |
| **Polling** | `detailsPoll` 1,5s; `bandPoll` 4s; scanners Wi-Fi via `scannerEnabled` — **inalterado** |
| **Timers** | `scanRestart`, `scanDone`, `actionTimeout` (30s), `connectionPhraseTimer`, `failureTimer` — **inalterados** |

### Strings — classificação

**Total user-facing encontrado:** ~59

#### A — fixas traduzidas (~52)

Frases de conexão (7), toggle Wi-Fi (2), timeouts (3), tooltips hero (2), títulos hero (4), `NÃO CONECTADO` (2), métricas (10), banda `AUTOMÁTICO` + tooltips (4), `PROVEDOR DNS` (1), tooltips DNS (4), `ESCANEANDO WI-FI…` (1), seções Wi-Fi (2), estados de linha (6), esquecer rede (1), rede oculta (1), senha/identidade (5), erros NM mapeados (6), ping timeout (1).

#### B — dinâmicas traduzíveis

- `BANDA WI-FI: ${band}GHZ` — só rótulo fixo traduzido
- `heroSsid.title + " (" + detail + ")"` — SSID/velocidade preservados
- `failureReason` via `Model.networkFailureReason()` — enum interno preservado, label traduzido

#### C — externas preservadas

SSID, IP, gateway, iface, sinal numérico, nomes de conexão, saída de `omarchy-network-status`, `omarchy-dns`, erros NM não mapeados.

#### D — lógica interna (não traduzido)

`kind` (`wifi`/`ethernet`/`disconnected`), `actionKind`, `dnsProviders` IDs (`DHCP`/`Cloudflare`/`Google`/`Custom`), `WifiSecurityType`, `ConnectionFailReason`, keys de `parseKeyValue`, `enterpriseConnectScript`, payload speedtest (`Wi-Fi`/`Ethernet` como fallback de display).

### Traduções principais

| Inglês | Português |
|--------|-----------|
| `Turn Wi-Fi on/off` | `Ativar/Desativar Wi-Fi` |
| `KNOWN NETWORKS` / `OTHER NETWORKS` | `REDES CONHECIDAS` / `OUTRAS REDES` |
| `Connecting…` / `Connected` / `Disconnecting…` | `Conectando…` / `Conectado` / `Desconectando…` |
| `Forget network` | `Esquecer rede` |
| `Wrong password` | `Senha incorreta` |
| `DNS PROVIDER` | `PROVEDOR DNS` |
| `Custom` (rótulo) | `Personalizado` (ID `Custom` preservado) |
| `WI-FI BAND` | `BANDA WI-FI` |
| `SCANNING WI-FI…` | `ESCANEANDO WI-FI…` |
| (+ demais — ver diffs) | |

### `shell/Ui/` pendente

O painel usa `qs.Ui` (`KeyboardPanel`, `PanelKeyCatcher`, `Button`, etc.) sem textos `Cancel`/`Confirm` visíveis neste plugin. **Nenhuma string adicional pendente** do `shell/Ui/` nesta fase.

### Wi-Fi

- Toggle, lista, senha, estados, scanning — traduzidos na UI
- SSID, BSSID, security flags, signal, connection ID — **preservados**
- Enterprise: placeholder `Identidade (usuario@dominio)` + `Senha`

### Ethernet

- **Existe** no mesmo painel (`kind === "ethernet"`, título `Ethernet`, velocidade via `headerDetail`)
- Labels de métricas traduzidos; IP/gateway/velocidade reais preservados

### VPN

- **Não existe** neste plugin. Sem pendências nesta fase.

### Barra

| Item | Detalhe |
|------|---------|
| Indicador | **Mesmo plugin** — `Panel.qml` contém `BarIconButton` + popup |
| Strings próprias | Ícone derivado de `Model.connectionIcon()` (sem texto) |
| Clone separado? | **Não** — `robertlindomar.omarchy-ptbr.network` substitui `omarchy.network` inteiro |
| Abertura | `SUPER+CTRL+W` → `omarchy-shell shell toggle omarchy.network` → `resolveEnabledId` → `robertlindomar.omarchy-ptbr.network` quando ativo; clique no ícone 󰤨/󰈀 na barra |

### Clone

| Campo | Valor |
|-------|-------|
| Caminho | `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.network/` |
| ID | `robertlindomar.omarchy-ptbr.network` |
| `clonedFrom` | `omarchy.network` |
| Arquivos | `manifest.json`, `Panel.qml`, `Model.js` |
| Alterações | metadata + strings visuais + `dnsProviderLabel`/`dnsProviderTooltip` |

### Segurança

| Pergunta | Resposta |
|----------|----------|
| Risco oficial + clone | **Baixo** — `plugin enable` desabilita `omarchy.network` via `clonedFrom` |
| DBus/listeners duplicados | **Não** — uma instância ativa |
| Polling duplicado | **Não** |
| Ativação | `omarchy plugin enable robertlindomar.omarchy-ptbr.network` + `omarchy-restart-shell` |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.network` + `omarchy-restart-shell` |

### Testes

| Teste | Status |
|-------|--------|
| `omarchy plugin validate` | ✓ passou |
| QML/JS/imports | ✓ estrutura idêntica ao oficial |
| IDs duplicados | ✓ apenas `robertlindomar.omarchy-ptbr.network` em plugins/ |
| Teste visual | **Pendente** (manual) |
| Abrir painel | `SUPER+CTRL+W` ou clique no ícone de rede na barra |

### Teste manual sugerido

1. Ativar clone e reiniciar shell
2. Abrir painel — conferir título, métricas, DNS, banda
3. Rede Wi-Fi conectada — estado `Conectado`, SSID real intacto
4. Lista de redes — seções `REDES CONHECIDAS` / `OUTRAS REDES`
5. Rede protegida — ícone de cadeado (sem alterar senha salva)
6. **Não** executar `Esquecer rede` automaticamente
7. Para testar conexão/desconexão — usar rede de teste, não desconectar a rede atual

### Integridade

| Item | Modificado? |
|------|-------------|
| `/usr/share/omarchy` | **NÃO** |
| NetworkManager | **NÃO** |
| Conexões salvas | **NÃO** |

### Status

- **Pronto para ativar** após validação visual
- **Não ativado** nesta execução
- **Pendência:** teste manual do painel em uso real

---

## robertlindomar.omarchy-ptbr.bluetooth (Fase 2B)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/bluetooth/` |
| ID | `omarchy.bluetooth` |
| Versão | `1.0.0` |
| Entry point | `barWidget` → `Panel.qml` |
| Arquivos | `manifest.json`, `Panel.qml`, `Model.js` |
| Backup | `~/Documentos/omarchy-ptbr/backups/omarchy.bluetooth-official-2026-08-31/` |
| Diffs | `Model.diff`, `Panel.diff` |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **BlueZ** | `Quickshell.Bluetooth` (`Bluetooth.defaultAdapter`, `Bluetooth.devices`) |
| **DBus** | Via Quickshell — adapter `enabled`, `discovering`, device `connect`/`disconnect` — **não alterado** |
| **Comandos externos** | `omarchy-bluetooth-device` (connect/disconnect/pair/forget), `omarchy-bluetooth-power` (on/off via rfkill) |
| **Pipewire** | `Quickshell.Services.Pipewire` para troca de sink de áudio após conexão — **inalterado** |
| **IPC** | `IpcHandler` target `omarchy.bluetooth` |
| **Polling/timers** | `discoveryRetry`, `discoveryStop`, `pendingTimeout` (20s), `audioSwitchTimer`, `phraseTimer` — **inalterados** |
| **Pairing agent** | **Não neste plugin** — sem UI de PIN/passkey; pairing via `omarchy-bluetooth-device pair` + BlueZ |

### Strings — classificação (~34)

#### A — fixas traduzidas (~32)

Frases animadas (8), `Sem adaptador`/`Desligado`, toggle (2), seções `CONECTADOS`/`PAREADOS`/`DISPONÍVEIS`, estados vazios (3), tooltips de ação (3), status de linha (4), `Esquecer`, fallback `Dispositivo`, título `Bluetooth` mantido.

#### B — dinâmicas

- Bateria: `NN%` — valor numérico preservado
- Nome do dispositivo via `deviceLabel()` — preservado

#### C — externas preservadas

Nomes/alias de dispositivos BlueZ, endereços MAC, saída de comandos do sistema.

#### D — interna (não traduzido)

`pendingActions` (`connecting`/`disconnecting`/`forgetting`), `focusSection`, `sectionName`, `devState`, comandos `omarchy-bluetooth-device`, propriedades BlueZ.

### Pairing / PIN

- **Implementação:** `connectDevice()` chama `pair` ou `connect` via `omarchy-bluetooth-device`
- **PIN/passkey:** **não há diálogo neste plugin** — provavelmente BlueZ/agent do sistema ou outro componente
- **Risco de agent duplicado:** **não** — plugin não registra Agent1

### Barra

- Indicador integrado em `Panel.qml` (`BarIconButton` + popup)
- Sem texto próprio — só ícones 󰂲/󰂱/󰂯
- **Clone separado?** Não
- Abertura: `SUPER+CTRL+B` ou clique no ícone; clique direito = toggle Bluetooth

### Traduções principais

| Inglês | Português |
|--------|-----------|
| `Turn Bluetooth on/off` | `Ativar/Desativar Bluetooth` |
| `CONNECTED` / `PAIRED` / `AVAILABLE` | `CONECTADOS` / `PAREADOS` / `DISPONÍVEIS` |
| `Connect` / `Disconnect` / `Pair` | `Conectar` / `Desconectar` / `Parear` |
| `Connecting…` / `Disconnecting…` / `Forgetting…` | `Conectando…` / `Desconectando…` / `Esquecendo…` |
| `Forget` | `Esquecer` |
| `Scanning for devices…` | `Procurando dispositivos…` |
| `Turn Bluetooth on to scan` | `Ative o Bluetooth para procurar dispositivos` |
| `No Bluetooth adapter` | `Nenhum adaptador Bluetooth` |
| `Device` (fallback) | `Dispositivo` |

### `shell/Ui/` pendente

Usa `KeyboardPanel`, `PanelKeyCatcher`, `ToggleSwitch` — sem `Cancel`/`Confirm` visíveis neste painel.

### Segurança

| Pergunta | Resposta |
|----------|----------|
| Risco oficial + clone | **Baixo** — `clonedFrom` desabilita oficial |
| DBus watchers duplicados | **Não** |
| Pairing agent duplicado | **Não** |
| Ativação | `omarchy plugin enable robertlindomar.omarchy-ptbr.bluetooth` + `omarchy-restart-shell` |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.bluetooth` + `omarchy-restart-shell` |

### Testes

| Teste | Status |
|-------|--------|
| `omarchy plugin validate` | ✓ passou |
| QML/JS/imports | ✓ |
| IDs duplicados | ✓ |
| Teste visual | **Pendente** (manual) |
| Atalho | `SUPER+CTRL+B` |

### Teste manual sugerido

1. Ativar clone e reiniciar shell
2. Abrir painel — hero `Bluetooth` + status animado
3. Dispositivos conectados em `CONECTADOS`
4. Pareados em `PAREADOS`, descobertos em `DISPONÍVEIS`
5. Bateria em `%` se disponível
6. **Não** esquecer/desconectar dispositivos automaticamente
7. Pairing opcional: usar dispositivo de teste escolhido pelo usuário

### Integridade

| Item | Modificado? |
|------|-------------|
| `/usr/share/omarchy` | **NÃO** |
| BlueZ | **NÃO** |
| Dispositivos removidos/desconectados | **NÃO** |

### Status

- **Pronto para ativar** após validação visual
- **Não ativado** nesta execução

---

## robertlindomar.omarchy-ptbr.power (Fase 2C)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/power/` |
| ID | `omarchy.power` |
| Versão | `1.0.0` |
| Entry point | `barWidget` → `Panel.qml` |
| Arquivos | `manifest.json`, `Panel.qml`, `Model.js` |
| Backup | `~/Documentos/omarchy-ptbr/backups/omarchy.power-official-2026-08-31/` |
| Diffs | `Model.diff`, `Panel.diff` |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **UPower** | `Quickshell.Services.UPower` — `UPower.displayDevice`, `UPower.onBattery`, `UPowerDeviceState` |
| **DBus** | Via Quickshell UPower — **não alterado** |
| **power-profiles-daemon** | `omarchy-powerprofiles-list`, `omarchy-powerprofiles-set` |
| **Comandos externos** | `omarchy-battery-status --shell`, `omarchy-system-stats` (carregado, não exibido na UI atual) |
| **Polling** | Timer 5s enquanto painel aberto — **inalterado** |
| **IPC** | `toggle`, `togglePercentage` |

### Strings (~32)

#### A — fixas traduzidas

Frases animadas carregando (9) + bateria (9), `Totalmente carregada`, título `Bateria`, labels de stats (8), `PERFIL DE ENERGIA`, perfis visuais (3).

#### B — dinâmicas

- Percentual `NN%` — valor preservado
- Tempo `2h 30m` / `45m` — formato compacto de `omarchy-battery-status` (preservado)
- Taxa `X.XW`, capacidade `XWh` — unidades preservadas

#### C — externas preservadas

Saída tabular de `omarchy-battery-status`, IDs de perfil (`power-saver`, `balanced`, `performance`).

#### D — interna

`UPowerDeviceState`, `activeProfile`, `setProfile(profile)` com ID original, keys `percentage`/`rate`/`time`/`threshold`.

### Perfis de energia

| ID interno | Label visual |
|------------|--------------|
| `power-saver` | Economia |
| `balanced` | Equilibrado |
| `performance` | Desempenho |

Comando `omarchy-powerprofiles-set ac|battery <id>` usa IDs originais.

### Bateria — estados (`modeLabel`)

| Inglês | Português |
|--------|-----------|
| `Threshold` | Limite de carga |
| `On battery` | Na bateria |
| `Fully charged` | Totalmente carregada |
| `Charging` | Carregando |
| `Holding` | Em espera |
| `Discharging` (label) | Descarregando |

### Ações do sistema

**Não existem** neste painel (sem Suspend/Shutdown/Restart/Logout). Apenas perfis de energia e stats.

### Barra

- Indicador integrado em `Panel.qml` (ícone bateria + opcional `%`)
- Clique esquerdo = painel; clique direito = toggle percentual
- Abertura: `SUPER+CTRL+P` ou clique no ícone

### Segurança

| Pergunta | Resposta |
|----------|----------|
| Risco oficial + clone | **Baixo** |
| DBus/polling duplicado | **Não** |
| Ativação | `omarchy plugin enable robertlindomar.omarchy-ptbr.power` + `omarchy-restart-shell` |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.power` + `omarchy-restart-shell` |

### Teste manual

1. Ativar clone e reiniciar shell
2. `SUPER+CTRL+P` — hero `Bateria`, status, barra de progresso
3. Stats: capacidade, ciclos, tempo, taxa
4. Perfis: `Economia` / `Equilibrado` / `Desempenho`
5. **Não** alterar perfil automaticamente — para testar: clicar perfil e voltar ao anterior manualmente
6. Clique direito no ícone da barra — toggle `%`

### Integridade

| Item | Modificado? |
|------|-------------|
| `/usr/share/omarchy` | **NÃO** |
| UPower | **NÃO** |
| Perfil de energia | **NÃO** (até ativação manual) |
| Máquina suspensa/reiniciada | **NÃO** |

### Status

- **Pronto para ativar** após validação visual
- **Não ativado** nesta execução
- **Pendência:** tempo em formato `Xh Ym` permanece do script oficial (fase futura se quiser `X h Y min`)

---

## robertlindomar.omarchy-ptbr.weather (Fase 2D)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Correção do manifest (2026-08-31)

O clone foi copiado do oficial **sem** ajustar o `manifest.json`. O arquivo ficou com `id: omarchy.weather` e **sem** bloco `omarchy.clonedFrom`, o que fazia o validate falhar:

```text
omarchy-plugin-validate: plugin id 'omarchy.weather' uses the reserved omarchy.* namespace
```

| Item | Antes (incorreto) | Depois (corrigido) |
|------|-------------------|---------------------|
| `id` | `omarchy.weather` | `robertlindomar.omarchy-ptbr.weather` |
| `omarchy.clonedFrom` | *(ausente)* | `omarchy.weather` |
| Demais campos | preservados | preservados |

- **Backup do manifest incorreto:** `~/Documentos/omarchy-ptbr/backups/robertlindomar.omarchy-ptbr.weather-manifest-before-fix-2026-08-31-215402.json`
- **Padrão usado:** igual a `robertlindomar.omarchy-ptbr.lock`, `robertlindomar.omarchy-ptbr.network`, etc. — bloco `"omarchy": { "clonedFrom": "…" }` no final do JSON
- **Validate após correção:** OK (sem erro de namespace reservado)
- **`resolveEnabledId`:** com `clonedFrom: omarchy.weather`, chamadas ao ID oficial são roteadas para `robertlindomar.omarchy-ptbr.weather` quando o clone estiver habilitado (`PluginRegistry.qml`)

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/weather/` |
| ID | `omarchy.weather` |
| Versão | `1.0.0` |
| Entry point | `barWidget` → `BarWidget.qml` (carrega `Panel.qml`) |
| Arquivos | `manifest.json`, `BarWidget.qml`, `Panel.qml`, `Model.js` |
| Backup | `~/Documentos/omarchy-ptbr/backups/omarchy.weather-official-2026-08-31/` |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **wttr.in** | `https://wttr.in/{query}?format=j1` — condições + previsão |
| **Open-Meteo** | forecast + current (`api.open-meteo.com/v1/forecast`) |
| **Geocoding** | `geocoding-api.open-meteo.com` (`language=en` no parâmetro — **preservado**) |
| **Localização** | `~/.local/state/omarchy/settings/weather.json` via `omarchy-weather-location` |
| **Cache** | `report` / `dailyForecastReport` em memória (stale on failure) |
| **Polling** | `refreshTimer` (default 15 min) + retry timers — **inalterado** |
| **Barra** | `label` = ícone emoji (sem texto de condição) |

### Strings user-facing reais (~12)

O painel **não exibe** labels textuais de condição (`Clear`, `Rain`, etc.) — apenas ícones.

| Inglês | Português | Onde |
|--------|-----------|------|
| `Search city` | `Buscar cidade` | placeholder |
| `FEELS` | `SENS.` | stat label |
| `WIND` | `VENTO` | stat label |
| `HUMID` | `UMID.` | stat label |
| `Fetching forecast…` | `Buscando previsão…` | loading |
| Dias (fallback) | `Domingo`…`Sábado` | `Model.dayName` fallback |

**Dias na UI:** `Model.dayName()` com nomes em pt-BR (`Domingo`…`Sábado`). O `Panel.qml` oficial passava `Qt.formatDate(date, "dddd")`, que no shell Omarchy costuma sair em inglês (`TUESDAY`, etc.); o clone remove esse formatter e usa só o array pt-BR do `Model.js`.

### Condições meteorológicas

- **origem:** códigos numéricos (wttr `weatherCode`, Open-Meteo `weather_code`) → **ícones** via `iconForCode` / `iconForOpenMeteoCode`
- **labels textuais:** **não existem** no plugin — nada a mapear
- **códigos preservados:** sim

### Datas / Hoje / Amanhã

- Sem labels `Today`/`Tomorrow` — previsão usa nome do dia
- Sem formatter manual de data além de `yyyy-MM-dd` para lógica

### Unidades

- °C/°F, km/h, mph, % — **preservadas** (`shouldUseImperial` inalterado)
- **Nenhuma unidade convertida**

### Fora do clone (pendência)

- `omarchy-weather-status` (notificação clique direito na barra): ainda em inglês (`Temp`, `Wind`, `Weather unavailable`)
- `settingsForm: weatherSettings` — formulário de settings do shell (não neste diretório)

### Barra

- `BarWidget.qml`: ícone + temp opcional; tooltip suprimido
- **Clone separado?** Não — `robertlindomar.omarchy-ptbr.weather` substitui widget inteiro
- Abertura: clique no ícone; `SUPER+CTRL+ALT+W` → notificação; meio = refresh

### Segurança

| Pergunta | Resposta |
|----------|----------|
| Risco oficial + clone | **Baixo** |
| Requests duplicadas | **Não** (uma instância) |
| Ativação | `omarchy plugin enable robertlindomar.omarchy-ptbr.weather` + `omarchy-restart-shell` |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.weather` + `omarchy-restart-shell` |

### Teste manual

1. Ativar clone e reiniciar shell
2. Abrir painel — ícone, temperatura, `SENS.`/`VENTO`/`UMID.`
3. Previsão — dias da semana (verificar locale pt-BR)
4. Editar localização — `Buscar cidade` (não salvar mudança destrutiva sem intenção)
5. Clique direito na barra — notificação ainda em inglês (script externo)

### Integridade

| Item | Modificado? |
|------|-------------|
| `/usr/share/omarchy` | **NÃO** |
| API/endpoints | **NÃO** |
| Localização | **NÃO** |
| Unidades | **NÃO** |

### Status

- **Manifest corrigido** e `omarchy plugin validate` OK (2026-08-31)
- **Pronto para ativação manual** após teste visual
- **Não ativado** nesta execução

---

## robertlindomar.omarchy-ptbr.audio (Fase 2E)

> Data: 2026-08-31  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/audio/` |
| ID | `omarchy.audio` |
| Versão | `1.0.0` |
| Entry point | `barWidget` → `Panel.qml` (ícone na barra + painel popup) |
| Kinds | `bar-widget` |
| Arquivos | `manifest.json`, `Panel.qml`, `Model.js` |
| Backup | `~/Documentos/omarchy-ptbr/backups/omarchy.audio-official-2026-08-31-215818/` |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **PipeWire** | `Quickshell.Services.Pipewire` — `Pipewire.nodes`, `defaultAudioSink`, `defaultAudioSource` |
| **Volume/mute** | `node.audio.volume` / `node.audio.muted` direto no PwNode |
| **Troca de dispositivo** | `Pipewire.preferredDefaultAudioSink/Source` + `omarchy-audio-output-set-default` / `omarchy-audio-input-set-default` |
| **Sink físico** | `omarchy-audio-output-sink` (resolve tuning/EasyEffects → hardware) |
| **Disponibilidade** | `omarchy-audio-sink-availability` (timer 5s com painel aberto) |
| **Streams/apps** | nodes `isStream` + MPRIS (`Quickshell.Services.Mpris`) para labels |
| **Peak input** | `PwNodePeakMonitor` no source default |
| **OSD volume** | `bar.shell.summon("omarchy.osd", …)` — plugin separado, só ícone + % |
| **Polling** | timers 5s (availability), 15s (volume sink), 75ms (snapshot debounce) — **inalterado** |

### Strings user-facing (~22 traduzidas)

| Inglês | Português | Arquivo | Class. |
|--------|-----------|---------|--------|
| `Audio` | `Áudio` | Panel.qml:754 | A |
| `Mute` / `Unmute` | `Silenciar` / `Ativar som` | Panel.qml:177 (tooltip) | A |
| `OUTPUT` | `SAÍDA` | Panel.qml:796 | A |
| `INPUT` | `ENTRADA` | Panel.qml:883 | A |
| `SOURCES` | `APLICATIVOS` | Panel.qml:986 | A |
| `Muted` | `Silenciado` | Model.js | A |
| `Silenced` | `Silêncio` | Model.js | A |
| `Concert hall` | `Salão de concertos` | Model.js | A |
| `Party mode` | `Modo festa` | Model.js | A |
| `Cranked up` | `No talo` | Model.js | A |
| `Steady groove` | `Ritmo estável` | Model.js | A |
| `Easy listening` | `Som suave` | Model.js | A |
| `Murmur` | `Murmúrio` | Model.js | A |
| `Whisper` | `Sussurro` | Model.js | A |
| `Unknown` | `Desconhecido` | Model.js | A |
| `Stream` | `Aplicativo` | Model.js (fallback) | A |
| `Microphone` (normalização) | `Microfone` | Model.js | A |

**Preservados (C):** nomes de dispositivos PipeWire (`Speaker`, `HDMI 3`, `Digital Microphone`, etc.), nomes de apps (Firefox, Spotify), `%`, ícones.

**Internos (D):** `focusSection` (`output`/`input`/`streams`/`header`), media.class, comandos `omarchy-audio-*`, regex de detecção (`headphone`, `hdmi`, `built-in audio`).

### Profiles / portas

Não há UI de seleção de profile/porta no painel — apenas lista de sinks/sources.

### Barra

- **Implementação:** integrada em `Panel.qml` (`BarIconButton` + `KeyboardPanel`)
- **Strings próprias:** nenhuma além do ícone de volume
- **Interação:** esq = abrir painel · dir = mute all · scroll = volume + OSD · meio = abrir painel
- **Clone separado?** Não

### OSD

- **Plugin:** `omarchy.osd` (separado)
- **Strings:** nenhuma user-facing (só ícone + número %)
- **Fase própria?** Não necessária para volume OSD

### Pendências (fora do clone)

- `omarchy.microphone` — widget separado na barra (não clonado)
- `shell/Ui/` — `PanelSlider`, `ToggleSwitch`, etc. (sem strings EN visíveis no audio)
- Nomes de hardware vindos do PipeWire permanecem em inglês (ex.: `Speaker`, `Stereo Microphone`)

### Segurança

| Pergunta | Resposta |
|----------|----------|
| Risco oficial + clone | **Baixo** |
| Watchers/subscriptions duplicados | **Não** (uma instância) |
| PipeWire alterado | **Não** |
| Ativação | `omarchy plugin enable robertlindomar.omarchy-ptbr.audio` + `omarchy-restart-shell` |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.audio` + `omarchy-restart-shell` |

### Teste manual (após ativação)

1. `SUPER+CTRL+A` ou clique no ícone de volume
2. Hero: `Áudio`, mood (`SALÃO DE CONCERTOS`, etc.), toggle `Silenciar`/`Ativar som`
3. `SAÍDA` — slider, `%`, lista de dispositivos (nomes preservados)
4. `ENTRADA` — slider, medidor, microfones
5. `APLICATIVOS` — se houver streams ativos
6. Scroll na barra — OSD com %
7. Opcional: ajustar slider e devolver; mute/unmute manual

### Integridade

| Item | Modificado? |
|------|-------------|
| `/usr/share/omarchy` | **NÃO** |
| PipeWire / WirePlumber | **NÃO** |
| Dispositivo padrão | **NÃO** |
| Volume | **NÃO** |

### Status

- **Manifest conferido no disco:** `id=robertlindomar.omarchy-ptbr.audio`, `clonedFrom=omarchy.audio`
- **`omarchy plugin validate`:** OK
- **Pronto para ativação manual**
- **Não ativado** nesta execução

---

## shell/Ui pt-BR (Fase 3A)

> Data: 2026-08-31  
> Investigação concluída; **lote 1 implementado nos clones consumidores** (não override global)

### Arquitetura

| Campo | Valor |
|-------|-------|
| Diretório oficial | `/usr/share/omarchy/shell/Ui/` |
| Import URI | `qs.Ui` |
| qmldir | `shell/Ui/qmldir` — módulo `qs.Ui`, 31 tipos |
| Resolution | Quickshell `-p "$OMARCHY_PATH/shell"` → `import qs.Ui` resolve para `shell/Ui/` |
| Override de usuário nativo | **Não** — Omarchy não expõe path alternativo; `shell.toml` do usuário só tem `[font]` |

**Importante:** override parcial do módulo `qs.Ui` (copiar só 1–2 QML) **quebra** tipos não copiados (`Panel`, `KeyboardPanel`, etc.). Override global exige espelhar os **31 arquivos** + `qmldir` e apontar `OMARCHY_PATH` para checkout custom (`omarchy dev link`) — alto custo de manutenção.

### Inventário `shell/Ui/`

- **32 arquivos QML** + `qmldir` (sem JS)
- **Componentes com strings default:** 4 (`ConfirmDialog`, `SearchableDropdown`, `MultiSelect`, `SpeedTestOverlay`)
- **Total strings user-facing em defaults:** **11**

| Arquivo | Strings default | Class. |
|---------|-----------------|--------|
| `ConfirmDialog.qml` | `Cancel`, `Confirm` | A |
| `SearchableDropdown.qml` | `Search...`, `No matches` | A |
| `MultiSelect.qml` | `Search...`, `No options`, `None selected` | A |
| `SpeedTestOverlay.qml` | `Measure again`, `Run Again` | A |

Demais componentes (`Panel`, `TextField`, `Dropdown`, `Button`, etc.) — **sem** strings fixas; textos vêm dos consumidores.

### Componentes críticos

#### ConfirmDialog

- **strings:** `cancelText` (default `Cancel`), `confirmText` (default `Confirm`), `message` (vazio — caller define)
- **consumers oficiais:** `clipboard/Clipboard.qml`, `menu/Menu.qml`
- **clones:** `robertlindomar.omarchy-ptbr.clipboard`, `robertlindomar.omarchy-ptbr.menu` (`Menu-v2.qml`)
- **risco:** **ALTO** se override global; **BAIXO** via properties no caller
- **estratégia:** passar `cancelText`/`confirmText` nos clones (**lote 1 aplicado**)

#### SearchableDropdown

- **strings:** `placeholderText` (`Search...`), `emptyText` (`No matches`)
- **consumers oficiais:** apenas `dev-gallery/GalleryPanel.qml` (demo)
- **clones:** nenhum usa
- **risco:** baixo (não afeta painéis de produção hoje)
- **estratégia:** properties `placeholderText`/`emptyText` quando algum clone passar a usar; ou override global futuro

### Consumidores `import qs.Ui`

**~45 arquivos** no shell oficial (bar, todos os painéis, clipboard, menu, lock, polkit, osd, etc.).

**Clones atuais que importam `qs.Ui`:** `robertlindomar.omarchy-ptbr.menu`, `robertlindomar.omarchy-ptbr.lock`, `robertlindomar.omarchy-ptbr.polkit`, `robertlindomar.omarchy-ptbr.clipboard`, `robertlindomar.omarchy-ptbr.reminders`, `robertlindomar.omarchy-ptbr.network`, `robertlindomar.omarchy-ptbr.bluetooth`, `robertlindomar.omarchy-ptbr.power`, `robertlindomar.omarchy-ptbr.weather`, `robertlindomar.omarchy-ptbr.audio`.

Benefício imediato do lote 1: **clipboard** e **menu** (ConfirmDialog).

### Estratégias avaliadas

| Estratégia | Viável? | Risco | Manutenção |
|------------|---------|-------|------------|
| A — override módulo `qs.Ui` | Só com cópia completa (31+ arquivos) + `omarchy dev link` | **Alto** | Alta a cada update |
| B — properties nos clones consumidores | **Sim** | **Baixo** | Mínima |
| C — componentes paralelos (`RobertConfirmDialog`) | Sim, mas duplica lógica | Médio | Média |
| D — patch pós-update automatizado | Possível | Médio | Média |

**Escolhida:** **B** (properties nos clones) para lote 1; override global **adiado** até haver checkout espelhado versionado.

### Implementação lote 1 (2026-08-31)

| Arquivo | Alteração |
|---------|-----------|
| `robertlindomar.omarchy-ptbr.clipboard/Clipboard.qml` | `cancelText: "Cancelar"` |
| `robertlindomar.omarchy-ptbr.menu/Menu-v2.qml` | `cancelText: "Cancelar"` |

**Backup:** `~/Documentos/omarchy-ptbr/backups/shell-ui-2026-08-31-220459/`

### Rollback lote 1

```bash
cp ~/Documentos/omarchy-ptbr/backups/shell-ui-2026-08-31-220459/robertlindomar.omarchy-ptbr.clipboard-Clipboard.qml.bak \
   ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.clipboard/Clipboard.qml
cp ~/Documentos/omarchy-ptbr/backups/shell-ui-2026-08-31-220459/robertlindomar.omarchy-ptbr.menu-Menu-v2.qml.bak \
   ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.menu/Menu-v2.qml
omarchy-restart-shell
```

### Updates

```bash
~/Documentos/omarchy-ptbr/omarchy-ptbr-audit.sh ui-strings
~/Documentos/omarchy-ptbr/omarchy-ptbr-audit.sh snapshot
diff -ru ~/Documentos/omarchy-ptbr/backups/shell-ui-*/omarchy-Ui-official-snapshot \
         /usr/share/omarchy/shell/Ui
```

### Testes pendentes (manual)

1. **Clipboard** — limpar histórico → `Cancelar` / `Excluir`
2. **Menu** — desinstalar app → `Cancelar` / `Desinstalar`
3. **Network/Bluetooth/Power/Audio** — sem SearchableDropdown; placeholders já nos clones
4. **Lock** — preview apenas

### Status

- Override global `qs.Ui`: **não implementado** (arriscado)
- Lote 1 consumidor: **implementado**
- Pronto para teste visual após `omarchy-restart-shell`

---

## shell/Ui pt-BR (Fase 3A)

> Data: 2026-08-31  
> Investigação concluída; **lote 1 implementado nos clones consumidores** (não override global)

### Arquitetura

| Campo | Valor |
|-------|-------|
| Diretório oficial | `/usr/share/omarchy/shell/Ui/` |
| Import URI | `qs.Ui` |
| qmldir | `shell/Ui/qmldir` — módulo `qs.Ui`, 31 tipos |
| Resolution | Quickshell `-p "$OMARCHY_PATH/shell"` → `import qs.Ui` resolve para `shell/Ui/` |
| Override de usuário nativo | **Não** — Omarchy não expõe path alternativo; `shell.toml` do usuário só tem `[font]` |

**Importante:** override parcial do módulo `qs.Ui` (copiar só 1–2 QML) **quebra** tipos não copiados (`Panel`, `KeyboardPanel`, etc.). Override global exige espelhar os **31 arquivos** + `qmldir` e apontar `OMARCHY_PATH` para checkout custom (`omarchy dev link`) — alto custo de manutenção.

### Inventário `shell/Ui/`

- **32 arquivos QML** + `qmldir` (sem JS)
- **Componentes com strings default:** 4 (`ConfirmDialog`, `SearchableDropdown`, `MultiSelect`, `SpeedTestOverlay`)
- **Total strings user-facing em defaults:** **11**

| Arquivo | Strings default | Class. |
|---------|-----------------|--------|
| `ConfirmDialog.qml` | `Cancel`, `Confirm` | A |
| `SearchableDropdown.qml` | `Search...`, `No matches` | A |
| `MultiSelect.qml` | `Search...`, `No options`, `None selected` | A |
| `SpeedTestOverlay.qml` | `Measure again`, `Run Again` | A |

Demais componentes (`Panel`, `TextField`, `Dropdown`, `Button`, etc.) — **sem** strings fixas; textos vêm dos consumidores.

### Componentes críticos

#### ConfirmDialog

- **strings:** `cancelText` (default `Cancel`), `confirmText` (default `Confirm`), `message` (vazio — caller define)
- **consumers oficiais:** `clipboard/Clipboard.qml`, `menu/Menu.qml`
- **clones:** `robertlindomar.omarchy-ptbr.clipboard`, `robertlindomar.omarchy-ptbr.menu` (`Menu-v2.qml`)
- **risco:** **ALTO** se override global; **BAIXO** via properties no caller
- **estratégia:** passar `cancelText`/`confirmText` nos clones (**lote 1 aplicado**)

#### SearchableDropdown

- **strings:** `placeholderText` (`Search...`), `emptyText` (`No matches`)
- **consumers oficiais:** apenas `dev-gallery/GalleryPanel.qml` (demo)
- **clones:** nenhum usa
- **risco:** baixo (não afeta painéis de produção hoje)
- **estratégia:** properties `placeholderText`/`emptyText` quando algum clone passar a usar; ou override global futuro

### Consumidores `import qs.Ui`

**~45 arquivos** no shell oficial (bar, todos os painéis, clipboard, menu, lock, polkit, osd, etc.).

**Clones atuais que importam `qs.Ui`:** `robertlindomar.omarchy-ptbr.menu`, `robertlindomar.omarchy-ptbr.lock`, `robertlindomar.omarchy-ptbr.polkit`, `robertlindomar.omarchy-ptbr.clipboard`, `robertlindomar.omarchy-ptbr.reminders`, `robertlindomar.omarchy-ptbr.network`, `robertlindomar.omarchy-ptbr.bluetooth`, `robertlindomar.omarchy-ptbr.power`, `robertlindomar.omarchy-ptbr.weather`, `robertlindomar.omarchy-ptbr.audio`.

Benefício imediato do lote 1: **clipboard** e **menu** (ConfirmDialog).

### Estratégias avaliadas

| Estratégia | Viável? | Risco | Manutenção |
|------------|---------|-------|------------|
| A — override módulo `qs.Ui` | Só com cópia completa (31+ arquivos) + `omarchy dev link` | **Alto** | Alta a cada update |
| B — properties nos clones consumidores | **Sim** | **Baixo** | Mínima |
| C — componentes paralelos (`RobertConfirmDialog`) | Sim, mas duplica lógica | Médio | Média |
| D — patch pós-update automatizado | Possível | Médio | Média |

**Escolhida:** **B** (properties nos clones) para lote 1; override global **adiado** até haver checkout espelhado versionado.

### Implementação lote 1 (2026-08-31)

| Arquivo | Alteração |
|---------|-----------|
| `robertlindomar.omarchy-ptbr.clipboard/Clipboard.qml` | `cancelText: "Cancelar"` |
| `robertlindomar.omarchy-ptbr.menu/Menu-v2.qml` | `cancelText: "Cancelar"` |

**Backup:** `~/Documentos/omarchy-ptbr/backups/shell-ui-2026-08-31-220459/`

### Rollback lote 1

```bash
cp ~/Documentos/omarchy-ptbr/backups/shell-ui-2026-08-31-220459/robertlindomar.omarchy-ptbr.clipboard-Clipboard.qml.bak \
   ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.clipboard/Clipboard.qml
cp ~/Documentos/omarchy-ptbr/backups/shell-ui-2026-08-31-220459/robertlindomar.omarchy-ptbr.menu-Menu-v2.qml.bak \
   ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.menu/Menu-v2.qml
omarchy-restart-shell
```

### Updates

```bash
~/Documentos/omarchy-ptbr/omarchy-ptbr-audit.sh ui-strings   # strings default atuais
~/Documentos/omarchy-ptbr/omarchy-ptbr-audit.sh snapshot       # após omarchy update
diff -ru ~/Documentos/omarchy-ptbr/backups/shell-ui-*/omarchy-Ui-official-snapshot \
         /usr/share/omarchy/shell/Ui
```

### Testes pendentes (manual)

1. **Clipboard** — limpar histórico → `Cancelar` / `Excluir`
2. **Menu** — desinstalar app → `Cancelar` / `Desinstalar`
3. **Network/Bluetooth/Power/Audio** — sem SearchableDropdown; placeholders já nos clones
4. **Lock** — preview apenas

### Status

- Override global `qs.Ui`: **não implementado** (arriscado)
- Lote 1 consumidor: **implementado**
- Pronto para teste visual após `omarchy-restart-shell`

---

## robertlindomar.omarchy-ptbr.speedtest (Fase 3B)

> Data: 2026-09-01  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/speedtest/` |
| ID | `omarchy.speedtest` |
| Kind | `panel` (summoned overlay) |
| Entry point | `panel` → `Panel.qml` |
| Backup | `~/Documentos/omarchy-ptbr/backups/speedtest-official-2026-09-01-002404/` |

### Arquitetura

- **Ferramenta:** `omarchy-network-speedtest [down|up]` — fast.com + `curl` + contadores de interface
- **UI:** `SpeedTestOverlay` — clone usa `SpeedTestOverlayPtbr.qml` local (botão `Run Again` hardcoded no oficial)

### Strings traduzidas

| Inglês | Português |
|--------|-----------|
| `Run Again` | `Testar novamente` |
| `Measure again via fast.com` | `Medir novamente via fast.com` |
| `Speed test failed` | `Teste de velocidade falhou` |

**Preservados:** `DOWNLOAD`, `UPLOAD`, `Mbps`, erros do script

### Disk speedtest

- Concluído em **Fase 3C** — ver `robertlindomar.omarchy-ptbr.disk-speedtest` abaixo

### Ativação

```bash
omarchy plugin enable robertlindomar.omarchy-ptbr.speedtest && omarchy-restart-shell
omarchy-shell shell summon omarchy.speedtest
```

### Status

- Validate OK · manifest conferido · **não ativado**

---

## robertlindomar.omarchy-ptbr.disk-speedtest (Fase 3C)

> Data: 2026-09-01  
> Clone preparado e traduzido; **não ativado** · benchmark **não executado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/disk-speedtest/` |
| ID | `omarchy.disk-speedtest` |
| Kind | `panel` (summoned overlay) |
| Entry point | `panel` → `Panel.qml` |
| Backup | `~/Documentos/omarchy-ptbr/backups/disk-speedtest-official-2026-09-01-003013/` |

### Benchmark (`omarchy-disk-speedtest`)

| Item | Detalhe |
|------|---------|
| **Ferramenta** | `dd` com `oflag=direct` / `iflag=direct` (4 workers paralelos) |
| **Diretório** | `$XDG_CACHE_HOME/omarchy` (default `~/.cache/omarchy`) — **não** `/dev/*` |
| **Arquivos temp** | `mktemp` em `/dev/shm/omarchy-disk-speedtest-XXXXXX.src` + `disk-speedtest-XXXXXX.dat` no cache |
| **Tamanho** | 256 MB × 4 arquivos (~1 GB durante teste) |
| **Espaço mínimo** | **2048 MB** livres (`parallel × file_mb × 2`) |
| **Fases** | read 8s → write 8s |
| **Cleanup** | `trap cleanup EXIT` — remove temps automaticamente |
| **Risco** | Baixo — sem escrita em dispositivo bruto |

### SpeedTestOverlay

- Mesma estratégia do `robertlindomar.omarchy-ptbr.speedtest`: `SpeedTestOverlayPtbr.qml` duplicado (sem infra compartilhada)
- Oficial `shell/Ui/` **não modificado**

### Strings traduzidas

| Inglês | Português |
|--------|-----------|
| `READ` / `WRITE` | `LEITURA` / `GRAVAÇÃO` |
| `Measure again` | `Medir novamente` |
| `Run Again` | `Testar novamente` (overlay local) |
| `Disk speed test failed` | `Teste de velocidade do disco falhou` |

**Preservados:** `MB/s`, nome do disco, erros stderr

### Abertura

- `omarchy-shell shell summon omarchy.disk-speedtest`
- Menu: `trigger.tests.disk-speedtest`

### Verificar cleanup (após teste manual)

```bash
ls ~/.cache/omarchy/disk-speedtest-* 2>/dev/null
ls /dev/shm/omarchy-disk-speedtest-* 2>/dev/null
```

### Ativação

```bash
omarchy plugin enable robertlindomar.omarchy-ptbr.disk-speedtest && omarchy-restart-shell
omarchy-shell shell summon omarchy.disk-speedtest
```

### Status

- Validate OK · manifest conferido · **não ativado**

---

## robertlindomar.omarchy-ptbr.agents (Fase 3D)

> Data: 2026-09-01  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/agents/` |
| ID | `omarchy.agents` |
| Versão | `1.0.0` |
| Entry point | `barWidget` → `Panel.qml` |
| Kinds | `bar-widget` |
| Arquivos | `manifest.json`, `Panel.qml`, `Main.qml`, `Agent.qml`, `README.md`, `assets/*.svg` |
| Backup | `~/Documentos/omarchy-ptbr/backups/agents-official-2026-09-01-003603/` |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **Função** | Painel de **uso/limites** de assinaturas de IA — **não é chat** nem launcher principal |
| **Dados** | JSON em `~/.local/state/omarchy/agents/usage/*.json` |
| **Atualização** | `omarchy-agent-usage-update` (timer + refresh manual) |
| **Collectors** | `omarchy-agent-usage-claude`, `-codex`, `-fireworks` |
| **Providers** | Claude Code (Anthropic OAuth), Codex (app-server RPC), Fireworks (billing API) |
| **Main.qml** | Descobre registros, dispara update, agregação sync opcional |
| **Agent.qml** | FileView por registro JSON |
| **Panel.qml** | Bar icon + popup dashboard |
| **IPC** | `omarchy-shell omarchy.agents <open\|close\|toggle\|refresh\|next>` |
| **Barra** | Esquerdo = painel · direito = `omarchy-agent --pick` · meio = próximo provider |
| **Visibilidade** | Widget oculto se nenhum provider com dados |

### Fluxo UI → dados

```
BarIconButton → Panel (KeyboardPanel)
  → Main (enabledProviders)
    → Agent[] (FileView *.json)
    → Process: omarchy-agent-usage-update [--force|--limits-only] [--except id]
      → omarchy-agent-usage-{claude,codex,fireworks}
        → APIs locais / endpoints (Anthropic, Codex RPC, Fireworks billing)
```

### Comandos externos (preservados)

| Comando | Uso |
|---------|-----|
| `omarchy-agent-usage-update` | Regenera registros de uso |
| `find` | Lista `*.json` no diretório de uso |
| `mkdir`, `bash` | Sync de snapshots entre máquinas |
| `omarchy-agent --pick` | Clique direito na barra (menu de agente) |

### Strings user-facing (~35 no QML/manifest)

| Classificação | Exemplos | Tratamento |
|---------------|----------|------------|
| **A — fixa** | `BALANCE`, `LIMITS`, estado vazio, `Prepaid credits` | Traduzido |
| **B — template** | `Resets in …`, `Merged from N device(s)`, `… spent of … funded` | Traduzido preservando variáveis |
| **B — mapeamento** | `Monthly/Weekly/Session/Limit`, `Today`, dias abreviados | Traduzido |
| **C — externo** | `usageStatusText`, `authHelpText`, `tierLabel`, labels de limite da API, nomes de provider | **Preservado** (vem dos collectors) |
| **C — modelos** | IDs → `friendlyModelName()` (GPT, DeepSeek intactos) | Formatação preservada; só `Unknown` → `Desconhecido` |
| **D — interno** | `moduleName`, `ipcTarget`, `syncMode` Off/On, provider IDs, comandos | **Inalterado** |

### Traduções aplicadas

| Inglês | Português |
|--------|-----------|
| Agents (manifest) | Agentes |
| No AI coding subscriptions found… | Nenhuma assinatura de codificação com IA encontrada… |
| BALANCE / LIMITS / TOKENS BY DAY / TOKENS BY MODEL | SALDO / LIMITES / TOKENS POR DIA / TOKENS POR MODELO |
| Prepaid credits | Créditos pré-pagos |
| Subscription | Assinatura |
| Today | Hoje |
| Sun–Sat | Dom–Sáb |
| Resets in | Reinicia em |
| now | agora |
| spent of / funded / estimated | gastos de / financiados / estimado |
| Merged from N device(s) | Mesclado de N dispositivo(s) |
| In / out / cache read / write (tooltip) | Entrada / saída / cache leitura / gravação |
| sessions (tooltip) | sessões |
| Usage sync mkdir/scan failed | Falha ao criar/ler pasta de sincronização de uso |
| Unknown (modelo) | Desconhecido |
| Schema labels (manifest) | pt-BR |

**Preservados:** `prompts`, `tokens`, nomes Claude Code/Codex/Fireworks, enum `Off`/`On`, `category: AI`, erros de collectors/API, stderr.

### Prompts funcionais

- **Nenhum prompt de agente** neste plugin — apenas exibição de métricas.
- Collectors em `/usr/share/omarchy/bin/omarchy-agent-usage-*` **não modificados**.

### Estados

- Sem máquina de estados UI (`idle`/`running`/etc.) — painel somente leitura.
- `retryAdvised`, `ready`, scopes — campos JSON internos, inalterados.

### Chat/UI

- **Chat:** não existe.
- Controles: teclado `h`/`l` trocar provider, `j`/`k` scroll, `r`/Enter refresh, Esc fechar.
- Histórico: gráficos de tokens por dia/modelo (dados JSON, não traduzidos).

### Barra

| Item | Detalhe |
|------|---------|
| Indicador | Glyphs `󱚣`; `active` quando limite ≥ 90% ou saldo ≤ 10% |
| Tooltip | Nenhum texto dedicado |
| Clone separado? | Não — `robertlindomar.omarchy-ptbr.agents` substitui widget inteiro |

### `shell/Ui/`

- Importa `qs.Ui` para `Panel`, `BarIconButton`, etc.
- **Sem** overrides de `ConfirmDialog`/`SearchableDropdown` necessários.
- Oficial `shell/Ui/` **não modificado**.

### Clone

| Campo | Valor |
|-------|-------|
| Caminho | `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.agents/` |
| ID | `robertlindomar.omarchy-ptbr.agents` |
| clonedFrom | `omarchy.agents` |
| Manifest conferido | Sim (`jq` + validate OK) |
| Arquivos alterados | `manifest.json`, `Panel.qml`, `Main.qml` |
| Inalterados | `Agent.qml`, `assets/`, `README.md` |
| `moduleName` / `ipcTarget` | `omarchy.agents` (oficial, preservado) |

### Segurança

| Pergunta | Resposta |
|----------|----------|
| Prompts internos alterados? | **Não** |
| Providers/modelos/API keys alterados? | **Não** |
| Comandos/args alterados? | **Não** |
| Rollback | `omarchy plugin disable robertlindomar.omarchy-ptbr.agents` + `omarchy-restart-shell` |

### Testes

```bash
# Validar (já OK)
omarchy plugin validate ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.agents

# Ativar (manual)
omarchy plugin enable robertlindomar.omarchy-ptbr.agents && omarchy-restart-shell

# Abrir painel (se widget visível na barra)
omarchy-shell omarchy.agents toggle

# IPC alternativo
omarchy-shell omarchy.agents open
```

**Teste visual sem API:** se já houver registros em `~/.local/state/omarchy/agents/usage/`, abrir painel e conferir seções/traduções. Se widget oculto (sem uso), estado vazio só aparece se houver providers habilitados sem dados — normalmente widget some da barra.

**Teste opcional de execução:** clique direito no ícone → `omarchy-agent --pick` (abre menu de agente; requer agente configurado).

**Refresh manual:** tecla `r` ou Enter dentro do painel (dispara `omarchy-agent-usage-update` — pode contatar APIs se credenciais existirem; não executar automaticamente na validação).

### Status

- Validate OK · manifest conferido · **não ativado**
- `/usr/share/omarchy` modificado: **NÃO**
- Configuração de IA modificada: **NÃO**
- Chamada externa realizada: **NÃO**

---

## robertlindomar.omarchy-ptbr.notifications (Fase 4A)

> Data: 2026-09-01  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/notifications/` |
| ID | `omarchy.notifications` |
| Kind | `service` (`keepLoaded: true`) |
| Entry point | `service` → `Service.qml` |
| Arquivos | `manifest.json`, `Service.qml`, `NotificationLogic.js`, `components/NotificationCard.qml` |
| Backup | `~/Documentos/omarchy-ptbr/backups/notifications-calendar-2026-09-01-004424/notifications/` |

### Arquitetura

| Componente | Detalhe |
|------------|---------|
| **Função** | Daemon FreeDesktop de notificações + popups toast + DND + histórico em disco |
| **UI** | Popups no canto superior direito (`PanelWindow` overlay); **sem painel central separado** |
| **Histórico** | `showHistory` reexibe últimos 10 toasts do diretório `history/` |
| **Card** | `NotificationCard.qml` — exibe `summary`/`body` do app (conteúdo externo) |
| **IPC** | `omarchy-shell notifications <toggleDnd\|showHistory\|clear\|dismissAll\|…>` |
| **Estado** | `~/.local/state/omarchy/notifications.json` (DND) + `notifications/*.json` |

### Strings Omarchy (traduzidas)

| Inglês | Português | Arquivo |
|--------|-----------|---------|
| `No recent notifications` | `Nenhuma notificação recente` | `Service.qml` (placeholder de histórico vazio) |

### Conteúdo externo preservado

- `summary`, `body`, `app`/`appName`, ícones — vindos de apps/CLI
- `NotificationCard.qml` **inalterado** (só renderiza dados recebidos)
- Sem tempo relativo na UI (propriedade `timestamp` existe mas **não é exibida**)

### Fora do clone (pendências visíveis)

| Item | Onde | Strings |
|------|------|---------|
| DND tooltips | `bar/indicators/Dnd.qml` (`omarchy.bar`) | `Allow Notifications` / `Silence Notifications` |
| Settings Indicators | `bar/widgets/Indicators.manifest.json` | `Do not disturb` |
| Menu trigger | `omarchy-menu.jsonc` (override usuário) | `Notifications` |
| Toasts do sistema | `omarchy-notification-send`, apps | conteúdo do remetente |

### Bar indicator

- Indicador DND: `󰂛` em `Dnd.qml` (widget Indicators da barra) — **não** faz parte do plugin notifications
- Sem badge de contagem; sem tooltip no toast

### Clone

| Campo | Valor |
|-------|-------|
| Caminho | `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.notifications/` |
| clonedFrom | `omarchy.notifications` |
| Alterações | `manifest.json`, `Service.qml` (1 string) |

### Teste manual

```bash
omarchy plugin enable robertlindomar.omarchy-ptbr.notifications && omarchy-restart-shell
notify-send "Teste" "Corpo da notificação"   # conteúdo permanece como enviado
omarchy-shell notifications showHistory       # se vazio: toast "Nenhuma notificação recente"
```

---

## robertlindomar.omarchy-ptbr.clock (Fase 4A)

> Data: 2026-09-01  
> Clone preparado e traduzido; **não ativado**

### Plugin oficial

| Campo | Valor |
|-------|-------|
| Diretório | `/usr/share/omarchy/shell/plugins/panels/clock/` |
| ID | `omarchy.clock` |
| Entry point | `barWidget` → `BarWidget.qml` → `Panel.qml` (calendário) |
| Arquivos | `manifest.json`, `BarWidget.qml`, `Panel.qml`, `Model.js` |
| Backup | `~/Documentos/omarchy-ptbr/backups/notifications-calendar-2026-09-01-004424/clock/` |

### Por que estava em inglês

O oficial força `Qt.locale("en_US")` em `Panel.qml` (comentário: *"The interface is English throughout"*). Dias da semana, mês e tooltips vinham desse locale fixo — **não** do locale da sessão.

### Locale efetivo (clone)

- `Panel.qml`: `Qt.locale("pt_BR")` para dias/meses/tooltips
- `BarWidget.qml`: `dateLocale: Qt.locale("pt_BR")` em `formatDateTime` do rótulo da barra
- `Model.js`: chaves internas `sunday`…`saturday` **preservadas** (persistência em `shell.json`)

### Strings traduzidas

| Inglês | Português |
|--------|-----------|
| Back to today | Voltar para hoje |
| BORN | NASC. |
| LIVE TO | VIVER ATÉ |
| LIFE | VIDA |
| Memento Mori | Memento mori |
| Start weeks on … | Iniciar semanas na … |
| Previous month | Mês anterior |
| Next month | Próximo mês |
| year (placeholder) | ano |
| Clock (manifest) | Relógio |

### Formato de data (visual)

| Antes | Depois |
|-------|--------|
| `MMMM d` (hero) | `d 'de' MMMM` → ex. `1 de setembro` |
| `MMMM yyyy` (nav) | `MMMM 'de' yyyy` → ex. `SETEMBRO DE 2026` |
| Dias abreviados | via `pt_BR` ShortFormat → SEG, TER… |

### Eventos

- **Sem integração de agenda** — apenas grade mensal + barras de progresso do ano/vida
- Nenhum título/descrição de evento externo

### Clone

| Campo | Valor |
|-------|-------|
| Caminho | `~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.clock/` |
| clonedFrom | `omarchy.clock` |
| Alterações | `manifest.json`, `Panel.qml`, `BarWidget.qml` |
| `moduleName` / `ipcTarget` | `omarchy.clock` (preservado) |

### Teste manual

```bash
omarchy plugin enable robertlindomar.omarchy-ptbr.clock && omarchy-restart-shell
# Clicar no relógio na barra → calendário
# Conferir: hero, dias da semana, mês, tooltips, rótulo da barra
# Teclas: [ ] mês, { } ano, t hoje, w alternar início da semana
omarchy-shell omarchy.clock toggle
```

### Rollback

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.notifications robertlindomar.omarchy-ptbr.clock && omarchy-restart-shell
```

---

## Keybindings pt-BR (Fase 4B)

> Data: 2026-09-01  
> Override de usuário aplicado; **sem plugin clone**

### Origem

| Item | Detalhe |
|------|---------|
| **UI** | Menu de seleção (`omarchy-menu-select` → `omarchy.menu`) |
| **Script** | `/usr/share/omarchy/bin/omarchy-menu-keybindings` |
| **Descrições** | Campo `description` em `o.bind()` nos Lua em `/usr/share/omarchy/default/hypr/bindings/*.lua`, lidos via `hyprctl binds` |
| **Parser** | Bash + awk no script acima (`dynamic_bindings` → `parse_binding_records` → `prioritize_entries`) |
| **Overrides usuário** | `~/.config/hypr/bindings.lua` (já tinha labels PT em alguns atalhos) |

### Pipeline

```text
default/hypr/bindings/*.lua + ~/.config/hypr/bindings.lua
  → hyprland.lua (hl.bind / o.bind)
  → hyprctl binds (description EN no runtime)
  → omarchy-menu-keybindings (parse + prioridade)
  → keybindings-labels-ptbr.awk (tradução visual)
  → omarchy-menu-select "Pesquisar atalhos..."
```

### Estratégia (A — override de usuário)

| Arquivo | Função |
|---------|--------|
| `~/.local/bin/omarchy-menu-keybindings` | Cópia do oficial + hook `translate_binding_labels` + prompt PT |
| `~/.config/omarchy/keybindings-labels-ptbr.awk` | Mapa EN→PT (exatos + padrões workspace N) |

- **Sem** alterar Hyprland/Lua oficial
- **Sem** bindings duplicados
- **Sem** mudar teclas/comandos/dispatchers
- Cache invalidado via versão `v12-ptbr`

### Backup

`~/Documentos/omarchy-ptbr/backups/keybindings-2026-09-01-010418/`

### Rollback

```bash
rm -f ~/.local/bin/omarchy-menu-keybindings
rm -f ~/.cache/omarchy/keybindings-*.records
# PATH volta a usar /usr/share/omarchy/bin/omarchy-menu-keybindings
```

### Teste manual

```bash
omarchy-menu-keybindings --print | head    # lista em PT
SUPER+K                                    # abrir painel "Pesquisar atalhos..."
```

---

## Keybindings — sincronização com overrides (Fase 4B.1)

> Data: 2026-09-01  
> Correção funcional: painel SUPER+K reflete bindings ativos do Hyprland

### Causa

| Item | Detalhe |
|------|---------|
| **Fonte da lista** | `hyprctl binds` (runtime Hyprland) — já era a fonte correta |
| **Problema 1** | Cache em `~/.cache/omarchy/keybindings-*.records` podia servir snapshot antigo; chave não incluía `bindings.lua` |
| **Problema 2** | Scan Lua auxiliar (`build_lua_bind_cache`) ignorava `hl.unbind` — metadados de dispatch podiam referenciar binds removidos |
| **Problema 3** | Abertura interativa (SUPER+K) reutilizava cache em vez de reler o runtime |

### Pipeline (inalterado na origem, reforçado na frescura)

```text
hyprctl binds (runtime efetivo)
  → dynamic_bindings
  → dedupe_runtime_bindings
  → parse → prioridade → tradução pt-BR
  → omarchy-menu-select
```

Overrides em `~/.config/hypr/bindings.lua` entram via `hyprctl reload` → `hyprctl binds` reflete `hl.unbind` + `o.bind` pessoais.

### Estratégia (A — estado runtime)

- **SUPER+K (interativo):** sempre `output_binding_records_uncached` — lê `hyprctl binds` ao abrir
- **`--print`:** cache permitido, invalidado por hash de `hyprctl binds` + fingerprint dos `.lua` em `~/.config/hypr/`
- **Scan Lua:** `hl.unbind` remove slots do cache auxiliar (dispatch de binds `__lua`)
- **Sem** redefinir bindings Hyprland só para traduzir/exibir

### Arquivos alterados

| Arquivo | Mudança |
|---------|---------|
| `~/.local/bin/omarchy-menu-keybindings` | `hl.unbind` no scan; fingerprint config; cache v13; SUPER+K sem cache; submap no CSV; dedupe runtime |
| `~/Documentos/omarchy-ptbr/IMPLEMENTACAO.md` | esta seção |

### Precedência Hyprland

```text
/usr/share/omarchy/default/hypr/bindings/*.lua
  → ~/.config/hypr/hyprland.lua (require default.hypr.omarchy)
  → ~/.config/hypr/bindings.lua (hl.unbind + o.bind — vence)
  → hyprctl binds (estado efetivo exibido no painel)
```

### Testes validados

| Caso | Esperado | Resultado |
|------|----------|-----------|
| Default não alterado (ex. SUPER+J) | Aparece traduzido | OK |
| Override (SUPER+D → Menu do Omarchy) | Só versão pessoal | OK |
| Substituído (SUPER+SPACE, SUPER+W) | Ausente do painel | OK |
| Novo/remapeado (SUPER+R flutuante) | Aparece com label PT | OK |

### Rollback

```bash
cp ~/Documentos/omarchy-ptbr/backups/keybindings-sync-2026-09-01-011638/omarchy-menu-keybindings ~/.local/bin/
rm -f ~/.cache/omarchy/keybindings-*.records
```

