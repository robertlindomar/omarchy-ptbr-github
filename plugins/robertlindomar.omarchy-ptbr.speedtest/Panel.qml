import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "SecurityBounds.js" as Bounds

// The shared gauge-cluster overlay (SpeedTestOverlay) dressed for the
// internet speed test: download and upload dials in Mbps, titled with the
// connection under test.
//
// Standalone panel plugin: summoning it starts a fresh run, dismissing it
// stops the traffic, so the download workers never keep saturating the link
// behind a closed overlay. The payload may carry the connection's display
// name -- {"connection": "MyWifi"} -- and the panel looks it up itself via
// omarchy-network-status when the caller doesn't know it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string connectionName: ""

  property bool running: false
  property bool expectedStop: false
  property bool pendingRun: false
  property string phase: ""        // "down" | "up" | ""
  property string stderrText: ""
  property string downloadMbps: ""
  property string uploadMbps: ""
  property string error: ""

  readonly property real downloadValue: toMbps(downloadMbps)
  readonly property real uploadValue: toMbps(uploadMbps)

  property int stdoutLineCount: 0

  function toMbps(raw) {
    var value = Bounds.parseBoundedFloat(raw, 100000)
    return isFinite(value) && value > 0 ? value : 0
  }

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") || {} } catch (e) {}
    if (payload.connection !== undefined) root.connectionName = String(payload.connection)
    else refreshConnectionName()
    root.opened = true
    runSpeedTest()
  }

  function close() {
    root.opened = false
    root.pendingRun = false
    phaseTimer.stop()
    // Clear the phase before killing the process: onExited advances to the
    // upload phase when it still reads "down".
    root.phase = ""
    root.running = false
    if (speedTestProc.running) {
      root.expectedStop = true
      speedTestProc.running = false
    }
  }

  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "omarchy.speedtest")
    else close()
  }

  function refreshConnectionName() {
    root.connectionName = ""
    statusProc.running = false
    statusWatchdog.stop()
    statusProc.running = true
    statusWatchdog.start()
  }

  function updateSpeedTestLine(line) {
    if (stdoutLineCount >= Bounds.MAX_STDOUT_LINES) return
    stdoutLineCount += 1
    var value = Bounds.parseBoundedFloat(Bounds.capText(line, Bounds.MAX_LINE_CHARS), 100000)
    if (!isFinite(value)) return

    if (phase === "down") downloadMbps = String(value)
    else if (phase === "up") uploadMbps = String(value)
  }

  Timer {
    id: speedWatchdog
    interval: Bounds.PROCESS_TIMEOUT_MS
    repeat: false
    onTriggered: {
      if (!speedTestProc.running) return
      root.expectedStop = true
      root.error = Bounds.capText(root.stderrText, Bounds.MAX_FIELD_CHARS) || "Teste de velocidade expirou"
      speedTestProc.running = false
    }
  }

  Timer {
    id: statusWatchdog
    interval: 30000
    repeat: false
    onTriggered: { if (statusProc.running) statusProc.running = false }
  }

  function runSpeedTest() {
    if (speedTestProc.running) {
      // A dismissal's SIGTERM is still in flight; Process.running stays true
      // until the child exits, so queue the fresh run for onExited.
      if (expectedStop) pendingRun = true
      return
    }
    stdoutLineCount = 0
    speedWatchdog.stop()
    error = ""
    downloadMbps = ""
    uploadMbps = ""
    running = true
    startPhase("down")
  }

  function startPhase(nextPhase) {
    expectedStop = false
    phase = nextPhase
    stderrText = ""
    speedTestProc.command = ["omarchy-network-speedtest", nextPhase]
    speedTestProc.running = true
    phaseTimer.restart()
    speedWatchdog.start()
  }

  function stopPhase() {
    phaseTimer.stop()
    if (speedTestProc.running) {
      expectedStop = true
      speedTestProc.running = false
      return
    }
    finishPhase()
  }

  function finishPhase() {
    if (phase === "down") {
      startPhase("up")
      return
    }

    phase = ""
    running = false
    expectedStop = false
  }

  Process {
    id: speedTestProc
    stdout: SplitParser { onRead: function(line) { root.updateSpeedTestLine(line) } }
    // Exit and stream-finished have no guaranteed order: when a failed exit
    // beat the collector and published the generic message, replace it with
    // the specific one once it lands.
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "")
        if (raw.length > Bounds.MAX_STDERR_BYTES) raw = raw.slice(0, Bounds.MAX_STDERR_BYTES)
        root.stderrText = raw.trim()
        if (root.error !== "" && root.stderrText !== "") root.error = Bounds.capText(root.stderrText, Bounds.MAX_FIELD_CHARS)
      }
    }
    onExited: function(exitCode) {
      phaseTimer.stop()
      speedWatchdog.stop()

      if (root.pendingRun) {
        root.pendingRun = false
        root.expectedStop = false
        if (root.opened) Qt.callLater(root.runSpeedTest)
        return
      }

      if (!root.expectedStop && exitCode !== 0) {
        root.error = Bounds.capText(root.stderrText, Bounds.MAX_FIELD_CHARS) || "Teste de velocidade falhou"
        root.phase = ""
        root.running = false
        return
      }

      root.expectedStop = false
      root.finishPhase()
    }
  }

  Timer {
    id: phaseTimer
    interval: 5000
    repeat: false
    onTriggered: root.stopPhase()
  }

  // Names the connection under test when the summoner didn't. First tab
  // field is the kind, second the SSID (wifi) or device (ethernet).
  Process {
    id: statusProc
    command: ["omarchy-network-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "")
        if (raw.length > Bounds.MAX_STDERR_BYTES) raw = raw.slice(0, Bounds.MAX_STDERR_BYTES)
        var fields = raw.trim().split("\t")
        var kind = Bounds.capText(fields[0] || "", 32)
        if (kind === "wifi") root.connectionName = Bounds.capText(fields[1] || "Wi-Fi", Bounds.MAX_FIELD_CHARS)
        else if (kind === "ethernet") root.connectionName = "Ethernet"
      }
    }
    onExited: statusWatchdog.stop()
  }

  SpeedTestOverlayPtbr {
    fontFamily: Style.font.family
    layerNamespace: "omarchy-network-speedtest"
    title: root.connectionName
    leftLabel: "DOWNLOAD"
    rightLabel: "UPLOAD"
    runAgainTooltip: "Medir novamente via fast.com"
    running: root.running
    leftValue: root.downloadValue
    rightValue: root.uploadValue
    leftLive: root.running && root.phase === "down"
    rightLive: root.running && root.phase === "up"
    error: root.error
    open: root.opened
    onCloseRequested: root.dismiss()
    onRunAgainRequested: root.runSpeedTest()
  }
}
