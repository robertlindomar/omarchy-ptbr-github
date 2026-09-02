function clampIndex(index, length) {
  if (length <= 0) return 0
  return Math.max(0, Math.min(length - 1, index))
}

function selectProfileIndex(index, delta, profiles) {
  var values = Array.isArray(profiles) ? profiles : []
  if (values.length === 0) return 0
  return clampIndex(index + delta, values.length)
}

var MAX_LINES = 256
var MAX_LINE_CHARS = 4096
var MAX_PROFILES = 16
var MAX_KEY_CHARS = 64
var MAX_VALUE_CHARS = 256

function capLine(line) {
  var s = String(line || "")
  return s.length <= MAX_LINE_CHARS ? s : s.slice(0, MAX_LINE_CHARS)
}

function parseKeyValue(raw) {
  var next = Object.create(null)
  var lines = String(raw || "").split("\n")
  var limit = Math.min(lines.length, MAX_LINES)
  for (var i = 0; i < limit; i++) {
    var line = capLine(lines[i])
    var idx = line.indexOf("\t")
    if (idx <= 0) continue
    var key = line.substring(0, idx).slice(0, MAX_KEY_CHARS)
    next[key] = line.substring(idx + 1).trim().slice(0, MAX_VALUE_CHARS)
  }
  return next
}

function parseProfiles(raw, previousIndex) {
  var lines = String(raw || "").split("\n")
  var list = []
  var active = ""
  var limit = Math.min(lines.length, MAX_LINES)
  for (var i = 0; i < limit && list.length < MAX_PROFILES; i++) {
    var line = capLine(lines[i]).trim()
    if (!line) continue
    var parts = line.split("\t")
    var name = String(parts[0] || "").slice(0, MAX_KEY_CHARS)
    if (!name) continue
    list.push(name)
    if (parts[1] === "1") active = name
  }
  return {
    profiles: list,
    activeProfile: active,
    profileIndex: clampIndex(previousIndex || 0, list.length)
  }
}

function profileIcon(name) {
  if (name === "power-saver") return "󰌪"
  if (name === "balanced") return "󰊚"
  if (name === "performance") return "󰓅"
  return "󰂄"
}

function profileDisplayLabel(name) {
  switch (name) {
  case "power-saver":
    return "Economia"
  case "balanced":
    return "Equilibrado"
  case "performance":
    return "Desempenho"
  default:
    if (!name) return ""
    return String(name).charAt(0).toUpperCase() + String(name).slice(1)
  }
}

function batteryFraction(device) {
  return device && device.isPresent ? Math.max(0, Math.min(1, device.percentage)) : 0
}

function chargeThresholdActive(device, onBattery, states) {
  var d = device || {}
  var s = states || {}
  if (!(d && d.isPresent && !onBattery)) return false

  var fraction = batteryFraction(d)
  if (d.state === s.Discharging) return false
  if (d.state === s.PendingCharge) return true
  if (d.state === s.FullyCharged && fraction < 0.99) return true
  if (d.state !== s.Charging || fraction >= 0.99) return false

  return Number(d.changeRate || 0) <= 0.2 || Number(d.timeToFull || 0) >= 8 * 60 * 60
}

function batteryIcon(device, onBattery, states) {
  var d = device || {}
  if (!d.isPresent) return ""

  var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
  var defaultIcons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
  var index = Math.max(0, Math.min(9, Math.floor(d.percentage * 10)))
  var threshold = chargeThresholdActive(d, onBattery, states)

  if (threshold) return defaultIcons[index]
  if (d.state === states.FullyCharged) return "󰂅"
  if (!onBattery) return chargingIcons[index]
  return defaultIcons[index]
}

function modeLabel(device, onBattery, states) {
  var d = device || {}
  if (!d.isPresent) return ""

  var percentage = d.isPresent ? d.percentage : 0
  if (chargeThresholdActive(d, onBattery, states)) return "Limite de carga"
  if (onBattery) return "Na bateria"
  if (!onBattery && percentage >= 1) return "Totalmente carregada"
  return "Carregando"
}

if (typeof module !== "undefined") {
  module.exports = {
    clampIndex: clampIndex,
    selectProfileIndex: selectProfileIndex,
    parseKeyValue: parseKeyValue,
    parseProfiles: parseProfiles,
    profileIcon: profileIcon,
    profileDisplayLabel: profileDisplayLabel,
    batteryFraction: batteryFraction,
    chargeThresholdActive: chargeThresholdActive,
    batteryIcon: batteryIcon,
    modeLabel: modeLabel
  }
}
