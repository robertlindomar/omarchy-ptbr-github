import QtQuick
import qs.Ui

// Bar button that summons the grid. It goes through shell IPC rather than
// touching the overlay directly, so the button and the SUPER+A binding share
// one toggle path (and the bar can reload without stranding an open overlay).
BarWidget {
  id: root
  moduleName: "robertlindomar.omarchy-ptbr.app-launcher"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    tooltipText: "Aplicativos e favoritos"
    horizontalMargin: 7.5
    onPressed: function(mouseButton) {
      if (!root.bar) return
      root.bar.run("omarchy-shell shell toggle robertlindomar.omarchy-ptbr.app-launcher '{}'")
    }
  }
}
