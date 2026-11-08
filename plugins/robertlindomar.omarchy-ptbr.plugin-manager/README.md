# Instalação independente — robertlindomar.omarchy-ptbr.plugin-manager

Esta é uma tradução comunitária não oficial. O código e os créditos originais estão preservados; veja `LICENSE` e a documentação abaixo. Publicação no GitHub não representa aprovação ou selo Verified do marketplace.

## Instalar este clone PT-BR

```bash
omarchy plugin add https://github.com/robertlindomar/omarchy-ptbr-plugin-manager.git --enable
```

Não habilite simultaneamente o clone e o plugin de origem com a mesma função. Instalar o clone não configura atalhos de teclado.

## Remover este clone PT-BR

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.plugin-manager
omarchy plugin remove robertlindomar.omarchy-ptbr.plugin-manager --yes
```

Remova também os atalhos manuais que apontem para este ID, se houver. Não apague pastas pessoais de estado para apenas desinstalar o plugin.

## Requisitos e dependências desta edição

Omarchy/Quickshell, `git`, `jq`, `python3` (catálogo HTTPS), CLI `omarchy` e coreutils (`setsid`, `nohup`, `timeout`, `sed`). Consultas de catálogo e atualizações precisam de rede.

## Documentação e créditos de origem

Os exemplos de outros atalhos abaixo são opcionais, não configurações aplicadas automaticamente.

# 🧩 Omaplug

**A small tool for managing your Omarchy plugins.**


Access it right from the Omarchy bar — it gives you a centralized place to view and organize the plugins you have installed. Here are a few things you can use it for:

- Easily turn individual plugins on or off as needed.
- Check for available updates and update them individually — or all at once.
- Remove plugins individually, or several in one go.
- Jump straight to each plugin's repo, or browse the [Omarchy marketplace](https://plugins.omarchy.org).

Omaplug é o projeto de origem; seu status no marketplace não se transfere a este clone PT-BR.

## Screenshots

![Omaplug preview](preview.png)

<table>
  <tr>
    <td align="center"><img src="preview_main.png" alt="Main plugin list" width="280"/></td>
    <td align="center"><img src="preview_check-update.png" alt="Checking for updates" width="280"/></td>
    <td align="center"><img src="preview_add.png" alt="Installing a plugin" width="280"/></td>
  </tr>
  <tr>
    <td align="center">Plugin list</td>
    <td align="center">Checking for updates</td>
    <td align="center">Installing a plugin</td>
  </tr>
  <tr>
    <td align="center"><img src="preview_filter.png" alt="Scope filter" width="280"/></td>
    <td align="center"><img src="preview_filter_2.png" alt="Type filter" width="280"/></td>
    <td align="center"><img src="preview_action.png" alt="Row action menu" width="280"/></td>
  </tr>
  <tr>
    <td align="center">Scope filter</td>
    <td align="center">Type filter</td>
    <td align="center">Row action menu</td>
  </tr>
</table>

## What it can do

- **🔌 Enable / disable** — every discovered plugin (Omarchy's own and third-party) gets a simple toggle. Flipping it goes through the same registry the `omarchy plugin enable/disable` command uses, so what you see here is always what's really running.
- **🔄 Check for updates** — scans every installed third-party plugin and distinguishes clean updates from local plugins, symlinked development plugins, local changes, and genuine fetch errors.
- **⬆️ Update (or update everything)** — apply one update, or finish every proven-safe pending update from a single click, even while Omarchy reloads changed plugins.
- **➕ Install** — paste a git repo URL and add a plugin in one step. It'll warn you first that plugins run as unsandboxed code, because honesty is the default here.
- **🗑️ Remove** — third-party plugins only. Trash one, or enter Select mode to check several and remove them all at once (with a confirmation, no accidents).
- **🔗 Source link** — every git-managed plugin gets a `SOURCE` button that jumps straight to its repo page.
- **🔍 Search & filter** — narrow the list to Omarchy plugins, third-party plugins, or search by name, description, ID, author, or kind.
- **♻️ Restart shell** — if a plugin ever acts up from stale compiled code, one button clears the QML cache and restarts the shell so everything reloads fresh.

## Install

```bash
omarchy plugin add https://github.com/robertlindomar/omarchy-ptbr-plugin-manager.git --enable
```

## Remove

```bash
omarchy plugin remove robertlindomar.omarchy-ptbr.plugin-manager
```

## Remove manually

No terminal? No problem — or maybe you just like doing things the hands-on way. Here's how to remove it by hand:

1. Delete the plugin folder:

```bash
rm -rf ~/.config/omarchy/plugins/robertlindomar.omarchy-ptbr.plugin-manager
```

2. Remove the `"id": "robertlindomar.omarchy-ptbr.plugin-manager"` entry from the bar layout in `~/.config/omarchy/shell.json`.

3. Restart the shell to apply:

```bash
omarchy-restart-shell
```

## Requirements

- Omarchy 4.x
- Quickshell
- `git`, `jq`, and the `omarchy` CLI
- Standard coreutils (`setsid`, `nohup`, `timeout`, `sed`)

## License

[MIT](LICENSE) © 2026 Fross
