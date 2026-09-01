# Omarchy PT-BR

Tradução **não oficial** do [Omarchy](https://omarchy.org) para português brasileiro (pt-BR).

O projeto usa **clones de plugins** em `~/.config/omarchy/plugins/` e **overrides** em `~/.local/bin/`, sem modificar `/usr/share/omarchy`.

## Componentes traduzidos

| Área | Clone / override |
|------|------------------|
| Menu principal | `robert.menu` + `extensions/omarchy-menu.jsonc` |
| Tela de bloqueio | `robert.lock` |
| Polkit | `robert.polkit` |
| Área de transferência | `robert.clipboard` |
| Lembretes | `robert.reminders` + `omarchy-reminder` |
| Rede / Bluetooth / Energia / Clima / Áudio | `robert.network`, `robert.bluetooth`, `robert.power`, `robert.weather`, `robert.audio` |
| Speed test / Disco / Agentes | `robert.speedtest`, `robert.disk-speedtest`, `robert.agents` |
| Notificações / Calendário | `robert.notifications`, `robert.clock` |
| Atalhos (SUPER+K) | `omarchy-menu-keybindings` + `keybindings-labels-ptbr.awk` |
| Capturas de tela | `omarchy-capture-screenshot` |

## Requisitos

- Omarchy instalado (`/usr/share/omarchy`)
- Hyprland em execução
- `bash`, `rsync`, `jq` (recomendado para merge de `shell.json`)

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
