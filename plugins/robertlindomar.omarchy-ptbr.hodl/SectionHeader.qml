import QtQuick
import qs.Commons
import qs.Ui

// A stock panel section header that can be folded away. Folding never hides
// the number the section exists for: the headline value moves into the
// header itself, so a collapsed panel still answers the question at a
// glance and only the detail goes away.
Item {
  id: root

  property string text: ""
  property string summary: ""
  property color summaryColor: Color.foreground
  property bool open: true
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal toggled()

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(label.implicitHeight, summaryText.implicitHeight) + Style.space(3)
  height: implicitHeight

  HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
  TapHandler { onTapped: root.toggled() }

  Row {
    id: labelRow
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(5)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      // chevron-down when open, chevron-right when folded
      text: root.open ? "\uf078" : "\uf054"
      color: hover.hovered ? root.foreground : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    PanelSectionHeader {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      foreground: hover.hovered ? root.foreground : Qt.darker(root.foreground, 1.1)
      fontFamily: root.fontFamily
    }
  }

  Text {
    id: summaryText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(0, parent.width - labelRow.width - Style.space(10))
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
    textFormat: Text.PlainText
    text: root.open ? "" : root.summary
    color: root.summaryColor
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
  }
}
