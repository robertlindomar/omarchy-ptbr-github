pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Rectangle {
  id: dialog

  required property bool open
  required property bool running
  required property bool failed
  required property string result
  required property color foreground
  required property string fontFamily
  required property color panelBackground

  signal closeRequested
  signal installRequested(string rawUrl)

  visible: open
  color: Util.alpha(panelBackground, 0.7)
  focus: true
  onOpenChanged: {
    if (open) Qt.callLater(function() { urlField.forceActiveFocus() })
  }
  Keys.priority: Keys.BeforeItem
  Keys.onEscapePressed: {
    if (!dialog.running) dialog.closeRequested()
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      if (!dialog.running) dialog.closeRequested()
    }
  }

  Rectangle {
    id: card

    anchors.centerIn: parent
    width: Math.min(parent.width - Style.space(32), Style.space(360))
    height: content.implicitHeight + Style.space(36)
    color: dialog.panelBackground
    radius: Style.cornerRadius
    border.color: Style.selectedStateColor(dialog.foreground, Color.accent)
    border.width: 1

    ColumnLayout {
      id: content

      anchors.fill: parent
      anchors.margins: Style.space(18)
      spacing: Style.space(12)

      Text {
        text: "Instalar um plugin de um repositório git"
        textFormat: Text.PlainText
        color: dialog.foreground
        font.family: dialog.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }

      Text {
        text: "Plugins executam código arbitrário e sem sandbox dentro do processo omarchy-shell. Adicione apenas repositórios em que confia — revise o código antes de ativar o plugin."
        textFormat: Text.PlainText
        color: Qt.darker(dialog.foreground, 1.6)
        font.family: dialog.fontFamily
        font.pixelSize: Style.font.bodySmall
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }

      TextField {
        id: urlField

        placeholderText: "https://github.com/acme/omarchy-weather.git"
        foreground: dialog.foreground
        accent: Color.accent
        font.family: dialog.fontFamily
        Layout.fillWidth: true
        onAccepted: {
          if (urlField.text.trim() !== "" && !dialog.running)
            dialog.installRequested(urlField.text)
        }
      }

      Text {
        visible: dialog.result !== ""
        text: dialog.result
        textFormat: Text.PlainText
        color: dialog.running ? dialog.foreground
          : (dialog.failed ? Color.urgent
            : Style.selectedStateColor(dialog.foreground, Color.accent))
        font.family: dialog.fontFamily
        font.pixelSize: Style.font.caption
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        Button {
          text: dialog.result !== "" ? "Fechar" : "Cancelar"
          enabled: !dialog.running
          foreground: dialog.foreground
          accent: Color.accent
          fontFamily: dialog.fontFamily
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(12)
          verticalPadding: Style.space(6)
          onClicked: dialog.closeRequested()
        }

        Button {
          text: dialog.running ? "Instalando…" : "Instalar"
          enabled: !dialog.running
          foreground: dialog.foreground
          accent: Color.accent
          fontFamily: dialog.fontFamily
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(12)
          verticalPadding: Style.space(6)
          onClicked: dialog.installRequested(urlField.text)
        }
      }
    }
  }
}
