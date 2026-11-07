import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// The book. One JSON file under ~/.local/share, watched for changes so a
// position added from the terminal (`hodl add ...`) shows up in the panel
// without a reload, and so the CLI and the panel can never disagree about
// what you own.
Item {
  id: root

  readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/omarchy-hodl"
  readonly property string filePath: dataDir + "/positions.json"

  property var positions: []
  property bool loaded: false
  property string lastError: ""

  readonly property int count: positions.length

  signal changed()

  function reload() {
    file.reload()
  }

  function apply(raw) {
    var next = []
    try {
      var doc = JSON.parse(String(raw || "{}"))
      var list = doc && Array.isArray(doc.positions) ? doc.positions : []
      for (var i = 0; i < list.length; i++) {
        var entry = Model.normalizePosition(list[i])
        if (entry) {
          // Legacy rows written by hand may have no id; the file path is the
          // only identity we need, so mint one rather than refusing the row.
          if (entry.id === "") entry.id = "p" + i + "-" + entry.date
          next.push(entry)
        }
      }
      lastError = ""
    } catch (e) {
      lastError = "positions.json não é JSON válido"
    }
    positions = Model.sortPositions(next)
    loaded = true
    root.changed()
  }

  function persist() {
    var payload = { version: 1, positions: positions }
    file.setText(JSON.stringify(payload, null, 2) + "\n")
  }

  function add(dateStr, amount, price, currency, fee, note) {
    var entry = {
      id: Date.now().toString(16),
      date: String(dateStr),
      amount: Number(amount),
      price: Number(price),
      currency: String(currency || "usd").toLowerCase(),
      fee: Number(fee || 0),
      note: String(note || "")
    }
    positions = Model.sortPositions(positions.concat([entry]))
    persist()
    root.changed()
    return entry
  }

  function remove(id) {
    var next = []
    for (var i = 0; i < positions.length; i++)
      if (positions[i].id !== id) next.push(positions[i])
    if (next.length === positions.length) return false
    positions = next
    persist()
    root.changed()
    return true
  }

  function totals(price) {
    return Model.portfolioTotals(positions, price)
  }

  // FileView writes the file but not the directory above it, and the very
  // first run of this plugin can precede the first CLI call that would have
  // created it.
  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.dataDir]
    running: true
    onExited: file.reload()
  }

  FileView {
    id: file
    path: root.filePath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.apply(text())
    onFileChanged: reload()
    onLoadFailed: {
      // No file yet is the normal first-run state, not an error.
      root.positions = []
      root.loaded = true
      root.changed()
    }
  }
}
