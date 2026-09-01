# Glossário proposto — Omarchy pt-BR

> Documento de planejamento. **Não aplicado no sistema.**

## Termos de navegação e ação

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Settings | Configurações | Menu raiz `setup` já usa este termo |
| Setup | Configurações | Evitar misturar "Setup" e "Settings" em pt-BR |
| Save | Salvar | |
| Cancel | Cancelar | Usado em `ConfirmDialog` compartilhado |
| Confirm | Confirmar | **Decisão:** manter "Confirmar" vs "OK"? |
| Close | Fechar | |
| Back | Voltar | |
| Next | Avançar | |
| Done | Concluído | |
| Search | Pesquisar | **Decisão:** "Pesquisar" vs "Buscar" |
| Search... | Pesquisar… | Placeholder com reticências |
| Install | Instalar | |
| Remove | Remover | |
| Uninstall | Desinstalar | Menu de apps |
| Update | Atualizar | |
| Delete | Excluir | **Decisão:** "Excluir" vs "Apagar" |
| Refresh | Atualizar | Contexto: lista/dados |
| Run Again | Executar novamente | Speed test |
| Select | Selecionar | Dmenu |
| Input | Entrada | Dmenu |
| Go | Ir | Label do menu raiz — **decisão:** manter "Ir" ou ocultar? |

## Estados e feedback

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Nothing here yet | Nada aqui ainda | Menu vazio |
| No matches | Nenhum resultado | |
| No matches for "…" | Nenhum resultado para "…" | Padrão com interpolação |
| Clipboard is empty | Área de transferência vazia | |
| No recent notifications | Nenhuma notificação recente | |
| Loading… | Carregando… | |
| Checking… | Verificando… | Lock / Polkit |
| Authentication failed | Falha na autenticação | |
| Wrong | Incorreto | Polkit |

## Lock / segurança

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Enter Password | Digite a senha | |
| Enter password | Digite a senha | Polkit (minúscula) |
| Authentication is needed | Autenticação necessária | Polkit |

## Rede / Bluetooth / energia

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Connected | Conectado | |
| Connecting… | Conectando… | |
| Disconnecting… | Desconectando… | |
| Forgetting… | Esquecendo… | Rede |
| Forget network | Esquecer rede | |
| Turn Bluetooth on | Ativar Bluetooth | |
| Turn Bluetooth off | Desativar Bluetooth | |
| Pair | Parear | **Decisão:** "Parear" vs "Emparelhar" |
| Scanning… | Procurando… | |
| Battery | Bateria | |
| POWER PROFILE | PERFIL DE ENERGIA | Caps em UI — manter estilo? |
| On battery | Na bateria | |
| Fully charged | Totalmente carregada | |

## Clima / display / áudio

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Fetching forecast… | Obtendo previsão… | Weather |
| BRIGHTNESS | BRILHO | Caps em painel |
| TEXT SIZE | TAMANHO DO TEXTO | |
| SCALE | ESCALA | |
| OUTPUT | SAÍDA | Áudio |
| INPUT | ENTRADA | Áudio |
| Mute | Silenciar | |
| Unmute | Ativar som | |

## Lembretes / clipboard / emojis

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Remind in minutes | Lembrar em minutos | |
| Reminder message | Mensagem do lembrete | |
| Search clipboard… | Pesquisar área de transferência… | |
| Search emojis… | Pesquisar emojis… | |
| Delete entire clipboard history? | Excluir todo o histórico da área de transferência? | |

## Bar / indicadores

| Inglês | Português proposto | Notas |
|--------|-------------------|-------|
| Dictate | Ditado | Tooltip |
| Do not disturb | Não perturbe | |
| Night Light | Luz noturna | Nome do recurso Omarchy |
| Day Light | Luz diurna | |
| Stay Awake | Manter ativo | |
| Screen Recording | Gravação de tela | |
| Stop recording | Parar gravação | |

## Não traduzir (nomes próprios / tecnologia)

- Hyprland, Wayland, Arch Linux, Omarchy
- Docker, Firefox, Chromium, Chrome, GitHub, Codex, Cursor, VS Code
- Tailscale, Dropbox, Spotify, Steam, Bluetooth (opcional manter)
- DNS, QR, VPN, Git, Wi-Fi (ou "Wi-Fi" como marca)
- Nomes de apps, pacotes, fontes, temas
- IDs de menu (`system.shutdown`), actions (`omarchy-system-shutdown`), providers

## Decisões pendentes (revisar manualmente)

1. **Pesquisar vs Buscar** — padrão para todos os placeholders de busca
2. **Confirmar vs OK** — diálogos genéricos
3. **Excluir vs Apagar vs Remover** — consistência entre clipboard, apps e sistema
4. **Configurações vs Ajustes** — termo único para `setup`/`settings`
5. **Caps lock em labels de painel** — traduzir mantendo MAIÚSCULAS ou usar capitalização pt-BR?
6. **Frases de humor da bateria** (power panel) — traduzir literalmente ou reescrever?
7. **Dias da semana** no weather — locale do sistema vs strings hardcoded em JS
8. **"Go"** no cabeçalho do menu — traduzir ou deixar como ícone conceitual?

## Consistência com menu já traduzido

O arquivo `~/.config/omarchy/extensions/omarchy-menu.jsonc` (~320 labels) é a **fonte de verdade** para termos do menu. Novas traduções devem alinhar-se a ele:

- `setup` → Configurações
- `system` → Sistema
- `apps` → Aplicativos
- `install` → Instalar
- `trigger` → Alternar
- `update` → Atualizar
