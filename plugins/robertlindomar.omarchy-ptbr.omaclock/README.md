# Instalação independente — robertlindomar.omarchy-ptbr.omaclock

Esta é uma tradução comunitária não oficial. O código e os créditos originais estão preservados; veja `LICENSE` e a documentação abaixo. Publicação no GitHub não representa aprovação ou selo Verified do marketplace.

## Instalar este clone PT-BR

```bash
omarchy plugin add https://github.com/robertlindomar/omarchy-ptbr-omaclock.git --enable
```

Não habilite simultaneamente o clone e o plugin de origem com a mesma função. Instalar o clone não configura atalhos de teclado.

## Remover este clone PT-BR

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.omaclock
omarchy plugin remove robertlindomar.omarchy-ptbr.omaclock --yes
```

Remova também os atalhos manuais que apontem para este ID, se houver. Não apague pastas pessoais de estado para apenas desinstalar o plugin.

## Requisitos e dependências desta edição

Omarchy/Quickshell e Hyprland; `bash`, `cat` e o comando `omarchy-font-list`; não há etapa de compilação. As fontes e suas licenças estão incluídas no plugin.

## Documentação e créditos de origem

Os exemplos de outros atalhos abaixo são opcionais, não configurações aplicadas automaticamente.

# OmaClock PT-BR

Tradução não oficial do [OmaClock de ubeyidah](https://github.com/ubeyidah/omaclock), versão 1.3.0, sob licença MIT. Os créditos e as licenças das fontes foram preservados.

O painel permite ajustar tamanho, posição, cor e fonte do relógio. Esta versão também corrige a leitura do tamanho no painel (`clockScale`), que aparecia como `NaN%`.

As configurações existentes continuam em `~/.config/omaclock/config.json` e são preservadas. O namespace da superfície permanece compatível com o plugin original. Não execute simultaneamente o original e o clone PT-BR.

## Instalação

No pacote Omarchy PT-BR, execute `./install.sh`. O clone é `robertlindomar.omarchy-ptbr.omaclock` e substitui `ubeyidah.omaclock`.
