import QtQuick
import qs.Commons

// Activity mark for a fetch that is happening *behind* data already on
// screen. It fades in and out in place and keeps its slot in the row whether
// or not it is spinning, so an update never shifts the layout under the
// cursor — and never blanks the value it is refreshing.
Text {
  id: root

  property bool active: false

  textFormat: Text.PlainText
  text: "\uf021"  // nf-fa-refresh, written as an escape so the
                       // glyph cannot be lost by an editor or a pipe
  font.pixelSize: Style.font.caption
  opacity: active ? 0.8 : 0
  transformOrigin: Item.Center

  Behavior on opacity {
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
  }

  RotationAnimation on rotation {
    from: 0
    to: 360
    duration: 900
    loops: Animation.Infinite
    running: root.active
  }
}
