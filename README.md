# Omarchy PT-BR

Tradução **não oficial** do [Omarchy](https://omarchy.org) para português brasileiro (pt-BR).

O projeto usa **clones de plugins** em `~/.config/omarchy/plugins/` e **overrides** em `~/.local/bin/`, sem modificar `/usr/share/omarchy`.

## Componentes traduzidos

| Área | Clone / override |
|------|------------------|
| Menu principal | `robertlindomar.omarchy-ptbr.menu` + `extensions/omarchy-menu.jsonc` |
| Tela de bloqueio | `robertlindomar.omarchy-ptbr.lock` |
| Polkit | `robertlindomar.omarchy-ptbr.polkit` |
| Área de transferência | `robertlindomar.omarchy-ptbr.clipboard` |
| Lembretes | `robertlindomar.omarchy-ptbr.reminders` + `omarchy-reminder` |
| Rede / Bluetooth / Energia / Clima / Áudio | `robertlindomar.omarchy-ptbr.network`, `robertlindomar.omarchy-ptbr.bluetooth`, `robertlindomar.omarchy-ptbr.power`, `robertlindomar.omarchy-ptbr.weather`, `robertlindomar.omarchy-ptbr.audio` |
| Speed test / Disco / Agentes | `robertlindomar.omarchy-ptbr.speedtest`, `robertlindomar.omarchy-ptbr.disk-speedtest`, `robertlindomar.omarchy-ptbr.agents` |
| Central de notificações e histórico | `robertlindomar.omarchy-ptbr.notification-center` |
| Aplicativos e favoritos (SUPER+ESPAÇO) | `robertlindomar.omarchy-ptbr.app-launcher` |
| Notificações / Calendário | `robertlindomar.omarchy-ptbr.notifications`, `robertlindomar.omarchy-ptbr.clock` |
| Indicadores da barra | `robertlindomar.omarchy-ptbr.indicators` |
| Atalhos (SUPER+K) | `omarchy-menu-keybindings` + `keybindings-labels-ptbr.awk` |
| Capturas de tela | `omarchy-capture-screenshot` |

## Aplicativos e histórico de notificações

O instalador inclui a central de notificações em português e o lançador de aplicativos
com favoritos manuais. `SUPER + ESPAÇO` abre o lançador; `Ctrl+F` ou o menu de contexto
adiciona ou remove o aplicativo dos favoritos. A seção de favoritos aparece acima
da lista alfabética e a busca continua disponível.

Os favoritos são gravados em `~/.local/state/omarchy/app-launcher/favorites.json`.
Esse arquivo pessoal não é distribuído. A instalação preserva o estado local existente.
O atalho anterior de `SUPER + ESPAÇO` é substituído por um bloco identificado em
`bindings.lua`; a desinstalação remove esse bloco. O instalador guarda backup antes de alterar o arquivo.

As versões PT-BR substituem `jankeesvw.notification-center` e
`tyrsolution.app-launcher`, preservando os plugins originais e seus créditos MIT.
O daemon de notificações PT-BR continua sendo um componente separado da central.

## Repositórios individuais dos plugins

Cada plugin traduzido também é publicado em um repositório público separado, pronto para futura submissão ao [Omarchy Plugin Marketplace](https://plugins.omarchy.org/).

| Plugin | Repositório | Status |
|--------|-------------|--------|
| Agentes | [omarchy-ptbr-agents](https://github.com/robertlindomar/omarchy-ptbr-agents) | ✅ |
| Áudio | [omarchy-ptbr-audio](https://github.com/robertlindomar/omarchy-ptbr-audio) | ✅ |
| Bluetooth | [omarchy-ptbr-bluetooth](https://github.com/robertlindomar/omarchy-ptbr-bluetooth) | ✅ |
| Área de transferência | [omarchy-ptbr-clipboard](https://github.com/robertlindomar/omarchy-ptbr-clipboard) | ✅ |
| Relógio | [omarchy-ptbr-clock](https://github.com/robertlindomar/omarchy-ptbr-clock) | ✅ |
| Teste de velocidade (disco) | [omarchy-ptbr-disk-speedtest](https://github.com/robertlindomar/omarchy-ptbr-disk-speedtest) | ✅ |
| Indicadores | [omarchy-ptbr-indicators](https://github.com/robertlindomar/omarchy-ptbr-indicators) | ✅ |
| Bloqueio | [omarchy-ptbr-lock](https://github.com/robertlindomar/omarchy-ptbr-lock) | ✅ |
| Menu | [omarchy-ptbr-menu](https://github.com/robertlindomar/omarchy-ptbr-menu) | ✅ |
| Rede | [omarchy-ptbr-network](https://github.com/robertlindomar/omarchy-ptbr-network) | ✅ |
| Notificações | [omarchy-ptbr-notifications](https://github.com/robertlindomar/omarchy-ptbr-notifications) | ✅ |
| Polkit | [omarchy-ptbr-polkit](https://github.com/robertlindomar/omarchy-ptbr-polkit) | ✅ |
| Energia | [omarchy-ptbr-power](https://github.com/robertlindomar/omarchy-ptbr-power) | ✅ |
| Lembretes | [omarchy-ptbr-reminders](https://github.com/robertlindomar/omarchy-ptbr-reminders) | ✅ |
| Teste de velocidade (rede) | [omarchy-ptbr-speedtest](https://github.com/robertlindomar/omarchy-ptbr-speedtest) | ✅ |
| Clima | [omarchy-ptbr-weather](https://github.com/robertlindomar/omarchy-ptbr-weather) | ✅ |

Para republicar ou sincronizar os repositórios individuais a partir deste monorepo:

```bash
./scripts/publish-plugins.sh              # todos os plugins
./scripts/publish-plugins.sh --dry-run    # simular sem push
./scripts/publish-plugins.sh weather      # apenas um plugin (slug)
```

## Submissão ao Marketplace

Arquivos de submissão e metadados ficam em `marketplace/`. Use:

```bash
./scripts/submit-marketplace.sh --dry-run     # prepara/atualiza submissões
./scripts/submit-marketplace.sh weather --dry-run
./scripts/check-marketplace.sh                # acompanha issues criadas
```

Para criar issues no marketplace (após revisão e confirmação explícita):

```bash
./scripts/submit-marketplace.sh --submit      # exige digitar SUBMIT
```

Repositório de submissões: [omacom/omarchy-plugin-marketplace](https://github.com/omacom/omarchy-plugin-marketplace) (formato em `SUBMISSION.md`).

## Requisitos

- Omarchy instalado (`/usr/share/omarchy`)
- Hyprland em execução
- `bash`, `rsync`, `jq` (recomendado para merge de `shell.json`)

## Desenvolvimento local

O projeto ativo fica em `~/Documentos/omarchy-ptbr-github/`. Backups antigos da fase de desenvolvimento estão em `archive/legacy-*/` (não versionados no Git).

## Instalação

```bash
git clone git@github.com:robertlindomar/omarchy-ptbr-github.git
cd omarchy-ptbr-github
./install.sh
```

Simular sem alterar nada:

```bash
./install.sh --dry-run
```

Verificar:

```bash
./scripts/verify-install.sh
```

## Atualização

Após atualizar o Omarchy upstream:

```bash
git pull
./install.sh
./update.sh
```

O `update.sh` gera um relatório de diferenças entre plugins oficiais e clones — **não sobrescreve traduções automaticamente**.

## Desinstalação

```bash
./uninstall.sh
```

Remove apenas arquivos deste projeto e tenta restaurar o backup mais recente da instalação.

## Compatibilidade

Base testada: Omarchy **4.0.0.alpha** (ver `docs/COMPATIBILIDADE.md`).

```bash
./scripts/check-version.sh
```

## Arquitetura

```
plugins/robert.*     → clones com omarchy.clonedFrom no manifest
extensions/          → overrides de labels do menu (JSONC)
overrides/bin/       → scripts em ~/.local/bin (precedem /usr/share/omarchy/bin)
overrides/omarchy/   → mapa awk de keybindings
config/              → exemplos (shell.json)
```

Cada clone declara `clonedFrom` apontando para o plugin oficial; ao habilitar o clone, o Omarchy desabilita o oficial correspondente.

## Política

- **Não** editar `/usr/share/omarchy`
- **Não** commitar segredos, backups ou dados pessoais
- Preferir patches e overrides a forks completos desnecessários

## Contribuir

1. Traduza strings user-facing; preserve IDs, actions, IPC e comandos
2. Documente termos em `docs/GLOSSARIO.md`
3. Rode `./scripts/verify-install.sh` antes de abrir PR

## Licença

Os plugins oficiais do Omarchy declaram **MIT** nos manifests. Este repositório contém **obras derivadas** (traduções e ajustes visuais). Consulte `NOTICE.md` antes de redistribuir.

## Aviso

Projeto comunitário, sem afiliação oficial com Omarchy. Atualizações upstream podem exigir rebase manual dos clones (`./update.sh`).
