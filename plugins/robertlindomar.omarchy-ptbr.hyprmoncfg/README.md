# Instalação independente — robertlindomar.omarchy-ptbr.hyprmoncfg

Esta é uma tradução comunitária não oficial. O código e os créditos originais estão preservados; veja `LICENSE` e a documentação abaixo. Publicação no GitHub não representa aprovação ou selo Verified do marketplace.

## Instalar este clone PT-BR

```bash
omarchy plugin add https://github.com/robertlindomar/omarchy-ptbr-hyprmoncfg.git --enable
```

Não habilite simultaneamente o clone e o plugin de origem com a mesma função. Instalar o clone não configura atalhos de teclado.

## Remover este clone PT-BR

```bash
omarchy plugin disable robertlindomar.omarchy-ptbr.hyprmoncfg
omarchy plugin remove robertlindomar.omarchy-ptbr.hyprmoncfg --yes
```

Remova também os atalhos manuais que apontem para este ID, se houver. Não apague pastas pessoais de estado para apenas desinstalar o plugin.

## Requisitos e dependências desta edição

Omarchy/Quickshell, Hyprland e o serviço externo `hyprmoncfg` 1.24.0 ou superior. O serviço deve estar instalado e em execução; não é incluído neste repositório.

## Documentação e créditos de origem

Os exemplos de outros atalhos abaixo são opcionais, não configurações aplicadas automaticamente.

# Monitores — hyprmoncfg PT-BR

Tradução brasileira do painel [omarchy-hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg), de Carmine Paolino, versão 2.10.0, distribuída como clone independente no pacote Omarchy PT-BR.

## Funcionalidades

- Disposição visual com arraste, alinhamento, resolução, taxa de atualização e escala.
- Brilho por monitor, tamanho do texto e fonte do terminal.
- Rotação, espelhamento, VRR, HDR, ampla gama de cores e perfis ICC.
- Perfis automáticos associados ao fabricante, modelo e número de série dos monitores.
- Planejamento opcional de áreas de trabalho, com estratégias manual, sequencial e intercalada.
- Identificação dos monitores e prévia com confirmação e reversão automática.

## Uso

Clique no ícone de monitores da barra. Use Expandir para acessar Disposição, Áreas de trabalho e Perfis. O botão Atalhos mostra os comandos de teclado. Alterações na disposição passam por uma prévia antes da confirmação.

A estratégia Desativado no planejador preserva o gerenciamento externo de áreas de trabalho. A tradução mantém os comandos, o protocolo e a configuração do projeto original. O serviço `hyprmoncfg` 1.24.0 ou mais recente continua necessário; suas mensagens e a interface externa de terminal podem aparecer no idioma original.

A instalação e ativação deste clone são feitas pelo instalador da raiz do pacote Omarchy PT-BR. Identificador: `robertlindomar.omarchy-ptbr.hyprmoncfg`. Origem: `crmne.hyprmoncfg`.

## Licença

O código original mantém a licença MIT e os avisos de copyright em [LICENSE](LICENSE). A tradução não altera a autoria do projeto original.
