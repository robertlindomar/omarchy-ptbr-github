import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property string page: "layout"
  property color foreground: Commons.Color.foreground
  property color background: Commons.Color.background
  property color accent: Commons.Color.accent
  property string fontFamily: Style.font.family

  signal closeRequested()

  readonly property var groups: {
    var contextual = []
    if (root.page === "layout") {
      contextual = [
        {
          title: "Monitor selecionado",
          bindings: [
            { keys: "arrastar, setas", action: "Mover 100px" },
            { keys: "Shift+setas", action: "Mover 10px" },
            { keys: "Ctrl+setas", action: "Mover 1px" },
            { keys: "Alt+setas", action: "Alinhar ao lado do monitor mais próximo" },
            { keys: "0", action: "Mover para 0,0" },
            { keys: "[  ]", action: "Selecionar o monitor anterior ou seguinte" }
          ]
        },
        {
          title: "Disposição",
          bindings: [
            { keys: "Tab, Shift+Tab", action: "Alternar entre disposição, Monitor e Cor" },
            { keys: "↑  ↓", action: "Selecionar um campo em Monitor ou Cor" },
            { keys: "←  →", action: "Ajustar o campo selecionado" },
            { keys: "Enter", action: "Editar ou aplicar o campo selecionado" }
          ]
        }
      ]
    } else if (root.page === "profiles") {
      contextual = [{
        title: "Perfil selecionado",
        bindings: [
          { keys: "↑  ↓", action: "Navegar pelos perfis e suas configurações salvas" },
          { keys: "Enter, a", action: "Visualizar este perfil" },
          { keys: "l", action: "Carregar no editor de disposição" },
          { keys: "e", action: "Editar comando após aplicar" },
          { keys: "d", action: "Excluir com confirmação" },
          { keys: "Shift+F10", action: "Abrir ações do perfil" },
          { keys: "Espaço", action: "Alternar seleção automática de perfil" }
        ]
      }]
    } else {
      contextual = [{
        title: "Áreas de trabalho",
        bindings: [
          { keys: "↑  ↓", action: "Selecionar configuração, área de trabalho ou monitor" },
          { keys: "←  →", action: "Ajustar, atribuir uma área de trabalho ou reordenar monitores" },
          { keys: "Enter, Espaço", action: "Avançar a configuração selecionada" }
        ]
      }]
    }
    contextual.push({
      title: "Em qualquer lugar",
      bindings: [
        { keys: "1  2  3", action: "Alternar abas" },
        { keys: "a", action: "Aplicar o rascunho atual ou perfil selecionado" },
        { keys: "s", action: "Salvar o rascunho atual como perfil" },
        { keys: "r", action: "Restaurar a partir do estado atual do Hyprland" },
        { keys: "?", action: "Mostrar estes atalhos" },
        { keys: "R", action: "Reiniciar o serviço após uma atualização" },
        { keys: "q, Esc", action: "Fechar o painel" }
      ]
    })
    return contextual
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.58)

    MouseArea {
      anchors.fill: parent
      onClicked: root.closeRequested()
    }
  }

  BorderSurface {
    anchors.centerIn: parent
    width: Math.min(parent.width - Style.space(48), Style.space(650))
    implicitHeight: helpContent.implicitHeight + Style.space(30)
    color: root.background
    borderSpec: Border.controlSpec("focus", root.foreground, root.accent)
    radius: Style.cornerRadius

    Column {
      id: helpContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(18)
      anchors.rightMargin: Style.space(18)
      spacing: Style.space(13)

      Text {
        textFormat: Text.PlainText
        text: "Atalhos"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Repeater {
        model: root.groups

        Column {
          required property var modelData
          width: helpContent.width
          spacing: Style.space(4)

          Text {
            textFormat: Text.PlainText
            text: String(parent.modelData.title || "")
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Repeater {
            model: modelData.bindings || []

            Row {
              required property var modelData
              width: parent.width
              spacing: Style.space(14)

              Text {
                textFormat: Text.PlainText
                width: Style.space(150)
                text: String(parent.modelData.keys || "")
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width - Style.space(164)
                text: String(parent.modelData.action || "")
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        text: "Qualquer tecla fecha esta ajuda."
        color: Qt.darker(root.foreground, 1.5)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
