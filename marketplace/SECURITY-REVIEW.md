# Marketplace — revisão de segurança (bloqueadores)

Matriz derivada das issues #4057–#4072 e #4260. Detalhes estruturados em `security-findings.json`.

| Plugin | Issue | Finding | Arquivo | Comum/Específico | Status local |
|--------|-------|---------|---------|------------------|--------------|
| agents | 4057 | README monorepo unpinned | README.md | COMMON | README template fixado |
| audio | 4058 | README + process/model bounds | README, Panel.qml | COMMON + SPECIFIC | README fixado; runtime pendente |
| bluetooth | 4059 | README + collection bounds | README, Panel.qml | COMMON + SPECIFIC | README fixado; runtime pendente |
| clipboard | 4060 | README + history size | README, ClipboardHistory.js | COMMON + SPECIFIC | Corrigido localmente |
| clock | 4061 | README + format bounds | README, BarWidget.qml | COMMON + SPECIFIC | Corrigido localmente |
| disk-speedtest | 4062 | README + process bounds | README, Panel.qml | COMMON + SPECIFIC | Corrigido localmente |
| indicators | 4063 | README + settings/helpers | README, Indicators.qml | COMMON + SPECIFIC | README fixado; runtime pendente |
| lock | 4064 | README + password length | README, LockView.qml | COMMON + SPECIFIC | Corrigido localmente |
| menu | 4065 | README + disabled guard | README, Menu-v2.qml | COMMON + SPECIFIC | disabled guard sync quattro |
| network | 4066 | README + NM helpers + upstream SHA | README, Panel.qml | COMMON + SPECIFIC | README fixado; runtime pendente |
| notifications | 4067 | README + model/persistence/exec | README, Service.qml | COMMON + SPECIFIC | README fixado; runtime pendente |
| polkit | 4068 | README monorepo unpinned | README.md | COMMON | README template fixado |
| power | 4069 | README + helper parsing | README, Model.js | COMMON + SPECIFIC | Model.js parcial |
| reminders | 4070 | README + IPC bounds | README, ReminderFlow.qml | COMMON + SPECIFIC | README fixado; runtime pendente |
| weather | 4071 | README monorepo unpinned | README.md | COMMON | README template fixado |
| speedtest | 4072 | README + process bounds | README, Panel.qml | COMMON + SPECIFIC | Parcial (bounds + watchdog) |
| monitor | 4260 | Tag `display` inválida | submission | SPECIFIC | Tag → `system` |

## Revalidação rodada 1 (2026-09-02)

Plugins revalidados com baseline **passed**: agents, polkit, weather, lock, clipboard, clock.

Monitor #4260 **não** revalidado — ownership não confirmado na issue.
