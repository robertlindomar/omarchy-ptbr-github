# Auditoria de tradução pt-BR — Omarchy

> **Etapa:** inspeção, catalogação e planejamento apenas. Nenhuma tradução aplicada.  
> **Data:** 2026-08-31  
> **Artefatos:** `inventory.json`, `GLOSSARIO.md`, `omarchy-ptbr-audit.sh`

---

## 1. Resumo executivo

| Métrica | Valor |
|---------|-------|
| Plugins oficiais (manifest.json) | **29** |
| Bar widgets (`.manifest.json`) | **8** |
| **Total de módulos com ID** | **37** |
| Clone pessoal | **1** (`robert.menu`) |
| IDs duplicados em `plugins/` | **0** (backup movido para fora) |
| Plugins com strings user-facing | **~25** |
| Strings traduzíveis (estimativa) | **~350–450** |
| Já parcialmente pt-BR | **menu** (~320 labels via extensions + clone) |
| i18n nativo (`qsTr`, locale) | **Não existe** |

### Estado atual do menu

| Componente | Estado |
|------------|--------|
| Labels do menu (`omarchy-menu.jsonc`) | ✅ ~320 overrides pt-BR |
| `omarchy.menu` oficial | ❌ disabled |
| `robert.menu` (clone) | ✅ enabled — entry point **`Menu-v2.qml`** |
| UI chrome do menu (6 strings) | ❌ ainda em inglês |
| Patch `MenuModel.js` (merge) | ✅ no clone |

---

## 2. Inventário de plugins

### 2.1 Plugins oficiais (`/usr/share/omarchy/shell/plugins/`)

| ID | Diretório | Entry point real | Estado |
|----|-----------|------------------|--------|
| omarchy.agents | agents/ | barWidget=Panel.qml | enabled |
| omarchy.audio | panels/audio/ | barWidget=Panel.qml | enabled |
| omarchy.background | background/ | service=Background.qml | enabled |
| omarchy.bar | bar/ | bar=Bar.qml | enabled |
| omarchy.battery | services/battery/ | service=Service.qml | enabled |
| omarchy.bluetooth | panels/bluetooth/ | barWidget=Panel.qml | enabled |
| omarchy.clipboard | clipboard/ | overlay=Clipboard.qml | enabled |
| omarchy.clock | panels/clock/ | barWidget=BarWidget.qml | enabled |
| omarchy.dev-gallery | dev-gallery/ | panel=GalleryPanel.qml | enabled |
| omarchy.disk-speedtest | panels/disk-speedtest/ | panel=Panel.qml | enabled |
| omarchy.dropbox | panels/dropbox/ | barWidget=Panel.qml | enabled |
| omarchy.emojis | emojis/ | overlay=Emojis.qml | enabled |
| omarchy.idle | services/idle/ | service=Service.qml | enabled |
| omarchy.image-picker | image-picker/ | overlay=ImagePicker.qml | enabled |
| omarchy.lock | lock/ | service=Service.qml | enabled |
| omarchy.media | services/media/ | service=Service.qml; barWidget=BarWidget.qml | enabled |
| omarchy.menu | menu/ | menu=**Menu.qml**; barWidget=BarWidget.qml | **disabled** |
| omarchy.monitor | panels/monitor/ | barWidget=Panel.qml | enabled |
| omarchy.network | panels/network/ | barWidget=Panel.qml | enabled |
| omarchy.nightlight | services/nightlight/ | service=Service.qml | enabled |
| omarchy.notifications | notifications/ | service=Service.qml | enabled |
| omarchy.osd | osd/ | panel=Osd.qml | enabled |
| omarchy.polkit | polkit/ | service=PolkitAgent.qml | enabled |
| omarchy.power | panels/power/ | barWidget=Panel.qml | enabled |
| omarchy.reminders | reminders/ | overlay=ReminderFlow.qml | enabled |
| omarchy.speedtest | panels/speedtest/ | panel=Panel.qml | enabled |
| omarchy.tailscale | panels/tailscale/ | barWidget=Panel.qml | enabled |
| omarchy.weather | panels/weather/ | barWidget=BarWidget.qml | enabled |
| omarchy.wifiqr | panels/wifiqr/ | panel=Panel.qml | enabled |

### 2.2 Bar widgets (sub-módulos do `omarchy.bar`)

| ID | Arquivo | Strings EN |
|----|---------|------------|
| omarchy.active-window | ActiveWindow.qml | poucas |
| omarchy.indicators | Indicators.qml | via indicators/*.qml |
| omarchy.keyboard-layout | KeyboardLayout.qml | layout names (dinâmico) |
| omarchy.microphone | Microphone.qml | 3 tooltips |
| omarchy.spacer | Spacer.qml | 0 |
| omarchy.system-update | SystemUpdate.qml | 1 tooltip |
| omarchy.tray | Tray.qml | ~6 |
| omarchy.workspaces | Workspaces.qml | 0 |

**Indicadores** (`bar/indicators/`): Dictation, Dnd, NightLight, Reminder, ScreenRecording, StayAwake — ~12 tooltips fixos.

### 2.3 Clone pessoal

| ID | Path | clonedFrom | Entry points | Estado |
|----|------|------------|--------------|--------|
| robert.menu | ~/.config/omarchy/plugins/robert.menu/ | omarchy.menu | menu=**Menu-v2.qml**; barWidget=BarWidget.qml | enabled |

**Arquivos:** Menu-v2.qml, Menu.qml (cópia), MenuModel.js (patched), BarWidget.qml, manifest.json

**Sem ID duplicado** em `plugins/` (backup movido para `~/Documentos/`).

---

## 3. Mecanismo de override descoberto

| Mecanismo | Caminho | Cobre | Estratégia |
|-----------|---------|-------|------------|
| Extensions menu JSONC | `~/.config/omarchy/extensions/omarchy-menu.jsonc` | Labels do menu | ✅ override (FEITO) |
| Default menu | `/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc` | Base do merge | somente leitura |
| shell.json | `~/.config/omarchy/shell.json` | bar layout, disabledPlugins | config |
| Plugin clone | `~/.config/omarchy/plugins/<id>/` | QML/JS inteiro | clone / clone-patch |
| Themes | `~/.config/omarchy/themes/` | cores, não texto | N/A |
| qsTr / i18n | — | — | **inexistente** |

**Regra:** override/config > clone com patch mínimo > upstream. **Nunca** editar `/usr/share/omarchy`.

---

## 4. UI compartilhada (impacto transversal)

`/usr/share/omarchy/shell/Ui/` — usada por múltiplos plugins:

| Arquivo | Strings EN | Plugins afetados |
|---------|------------|------------------|
| ConfirmDialog.qml | Cancel, Confirm | menu, clipboard, network, etc. |
| SearchableDropdown.qml | Search..., No matches | vários painéis |
| MultiSelect.qml | Search..., No options, Loading… | configurações |
| SpeedTestOverlay.qml | Run Again, Measure again | speedtest, disk-speedtest |

**Estratégia:** clone do `omarchy.bar` ou fork de `Ui/` no clone do plugin consumidor — **risco alto** (propagação inconsistente). Ideal: um clone “omarchy.ui-ptbr” referenciado por todos (requer upstream ou convenção local).

---

## 5. Relatório por plugin (prioritários)

### robert.menu — PRIORIDADE 1

- **PATH:** `~/.config/omarchy/plugins/robert.menu/`
- **ENTRY:** `Menu-v2.qml`
- **TEXTOS:** ~320 labels pt-BR (extensions) + **6 UI chrome EN**
- **Exemplos EN restantes:** "Nothing here yet", "No matches for…", "Input"/"Select", "Do you want to uninstall…?", "Uninstall", "Go" (root label em MenuModel.js)
- **ESTRATÉGIA:** clone-patch (já existe)
- **RISCO:** médio (merge/race já corrigidos)
- **RECOMENDAÇÃO:** traduzir agora (6 strings)

### omarchy.lock — PRIORIDADE 1

- **ENTRY:** Service.qml → LockView.qml
- **TEXTOS:** ~9 — "Enter Password", "Checking…", "Authentication failed (N)"
- **ESTRATÉGIA:** clone
- **RISCO:** baixo-médio (PAM/auth)
- **RECOMENDAÇÃO:** traduzir agora

### omarchy.polkit — PRIORIDADE 1

- **TEXTOS:** ~5 — "Enter password", "Checking...", "Wrong", "Authentication is needed...", dinâmico "Authorize running '…'"
- **ESTRATÉGIA:** clone + patch PolkitModel.js (dinâmico)
- **RISCO:** médio
- **RECOMENDAÇÃO:** traduzir agora

### omarchy.clipboard — PRIORIDADE 1

- **TEXTOS:** ~10 — placeholders, confirmações, empty state
- **ESTRATÉGIA:** clone (usa ConfirmDialog)
- **RISCO:** baixo
- **RECOMENDAÇÃO:** traduzir agora

### omarchy.reminders — PRIORIDADE 1

- **TEXTOS:** ~4 — "Remind in minutes", "Reminder message", notificações de erro
- **ESTRATÉGIA:** clone
- **RISCO:** baixo
- **RECOMENDAÇÃO:** traduzir agora

### omarchy.network — PRIORIDADE 2

- **TEXTOS:** ~59 (maior painel)
- **ESTRATÉGIA:** clone
- **RISCO:** médio (estados dinâmicos: Connecting…, Forget network)
- **RECOMENDAÇÃO:** traduzir depois (fase 2)

### omarchy.bluetooth — PRIORIDADE 2

- **TEXTOS:** ~34
- **ESTRATÉGIA:** clone
- **RISCO:** médio

### omarchy.power — PRIORIDADE 2

- **TEXTOS:** ~32 (inclui frases de humor da bateria)
- **ESTRATÉGIA:** clone
- **RISCO:** médio

### omarchy.weather / omarchy.audio / omarchy.monitor — PRIORIDADE 2

- **TEXTOS:** 19–26 cada
- **ESTRATÉGIA:** clone
- **RISCO:** médio (dias da semana em JS no weather)

### omarchy.bar + indicators — PRIORIDADE 2

- **TEXTOS:** ~15 tooltips + Tray UI
- **ESTRATÉGIA:** clone bar + indicators
- **RISCO:** médio

### omarchy.dev-gallery — PRIORIDADE 5

- **TEXTOS:** ~128 (sandbox de componentes)
- **RECOMENDAÇÃO:** não traduzir (dev-only)

### Plugins sem strings visíveis relevantes

omarchy.background, omarchy.battery, omarchy.idle, omarchy.nightlight, omarchy.notifications (texto vem do SO), omarchy.osd (ícones), omarchy.spacer, omarchy.workspaces, omarchy.image-picker

---

## 6. Textos fora de `plugins/`

| Local | Conteúdo | Traduzível? |
|-------|----------|-------------|
| `shell/Ui/` | Diálogos, dropdowns | Sim — alto impacto |
| `default/omarchy/omarchy-menu.jsonc` | Labels default EN | Override já feito |
| `default/sddm/omarchy/Main.qml` | Login SDDM | Pouco texto (imagens) |
| `default/plymouth/` | Boot splash | Script, baixa prioridade |
| `bin/omarchy-*` | Mensagens CLI | Médio — fora do shell visual |
| `default/hypr/` | Bindings | Nomes de apps, não traduzir |

---

## 7. Strings duplicadas (glossário unificado)

| String EN | Ocorrências | Tradução proposta |
|-----------|-------------|-------------------|
| Cancel | ConfirmDialog, vários | Cancelar |
| Confirm | ConfirmDialog | Confirmar |
| Search... | MultiSelect, SearchableDropdown | Pesquisar… |
| No matches | SearchableDropdown, menu | Nenhum resultado |
| Delete | clipboard, etc. | Excluir |
| Loading… | MultiSelect | Carregando… |
| Checking… | lock, polkit | Verificando… |
| Enter Password / Enter password | lock, polkit | Digite a senha |
| Run Again | SpeedTestOverlay | Executar novamente |

Ver `GLOSSARIO.md` completo.

---

## 8. Índice global (prioridade)

| Plugin | Strings | pt-BR | EN | Estratégia | Risco | Prioridade |
|--------|---------|-------|-----|------------|-------|------------|
| robert.menu | ~326 | parcial | 6 UI | clone-patch | médio | **1** |
| omarchy.lock | ~9 | não | sim | clone | baixo-médio | **1** |
| omarchy.polkit | ~5 | não | sim | clone | médio | **1** |
| omarchy.clipboard | ~10 | não | sim | clone | baixo | **1** |
| omarchy.reminders | ~4 | não | sim | clone | baixo | **1** |
| shell/Ui | ~10 | não | sim | clone-transitive | alto | **1** |
| omarchy.network | ~59 | não | sim | clone | médio | **2** |
| omarchy.bluetooth | ~34 | não | sim | clone | médio | **2** |
| omarchy.power | ~32 | não | sim | clone | médio | **2** |
| omarchy.weather | ~19 | não | sim | clone | médio | **2** |
| omarchy.audio | ~26 | não | sim | clone | médio | **2** |
| omarchy.bar/indicators | ~15 | não | sim | clone | médio | **2** |
| omarchy.agents | ~6 | não | sim | clone | baixo | **3** |
| omarchy.dev-gallery | ~128 | não | sim | clone | baixo | **5** |

---

## 9. Arquivos a clonar vs não clonar

### Clonar (tradução visual)

- `robert.menu` — ✅ já clonado; só patch UI
- `omarchy.lock`, `omarchy.polkit`, `omarchy.clipboard`, `omarchy.reminders`
- Painéis: network, bluetooth, power, weather, audio, monitor, tailscale, clock, dropbox
- `omarchy.bar` (Tray + tooltips) — opcional fase 2
- Considerar fork local de `shell/Ui/` ou clone por plugin consumidor

### NÃO clonar

- `omarchy.menu` — substituído por `robert.menu`
- `omarchy.background`, `omarchy.battery`, `omarchy.idle`, `omarchy.nightlight`
- `omarchy.dev-gallery` — dev only
- `omarchy.notifications` — texto vem de apps externas
- `omarchy.osd`, `omarchy.spacer`, `omarchy.workspaces`

---

## 10. Detecção pós-update

Script: `~/Documentos/omarchy-ptbr/omarchy-ptbr-audit.sh`

```bash
# Após cada omarchy update:
./omarchy-ptbr-audit.sh snapshot

# Comparar com snapshot anterior:
./omarchy-ptbr-audit.sh diff

# Listar clones e entry points:
./omarchy-ptbr-audit.sh clones
```

Detecta: novos/removidos manifests, mudanças em strings QML/JS, hash do menu default.

**Manual adicional:**
```bash
git diff --no-index /path/to/snapshot-old/strings-qml-js.txt /path/to/snapshot-new/strings-qml-js.txt
diff -ru ~/.config/omarchy/plugins/robert.menu /usr/share/omarchy/shell/plugins/menu
```

---

## 11. ROADMAP proposto

### FASE 1 — Baixo risco, alto impacto imediato
1. Finalizar 6 strings UI em `robert.menu` (Menu-v2.qml + MenuModel.js "Go")
2. Clonar e traduzir: lock, polkit, clipboard, reminders
3. Definir glossário final (decisões pendentes em GLOSSARIO.md)

### FASE 2 — Plugins visuais principais
4. Clonar painéis: network, bluetooth, power, weather, audio
5. Clonar bar indicators + Tray tooltips
6. Avaliar fork de `shell/Ui/` (ConfirmDialog, SearchableDropdown)

### FASE 3 — Dialogs e notificações
7. SpeedTestOverlay, disk-speedtest, agents panel
8. Mensagens dinâmicas (polkit authorize, network states)

### FASE 4 — Textos dinâmicos e edge cases
9. Weather (dias da semana), power (frases humor)
10. bin/omarchy-* CLI (opcional)

### FASE 5 — Auditoria pós-update
11. Rodar `omarchy-ptbr-audit.sh snapshot` + `diff`
12. Reconciliar clones desatualizados com `omarchy plugin clone` + reaplicar patches
13. Verificar entry points em manifest.json após cada update

---

## 12. Lições aplicáveis

1. Sempre verificar **entry point real** em `manifest.json`
2. Nunca backups em `plugins/` com mesmo `id`
3. Extensions cobrem **só labels** do menu — não UI chrome
4. `plugin validate` ≠ teste visual/runtime
5. Merge parcial de JSONC exige patch em MenuModel.js (já no clone)

---

*Nenhuma modificação foi feita em `/usr/share/omarchy`.*
