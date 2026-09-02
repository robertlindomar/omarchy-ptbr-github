// Bounded parsing helpers for plugin subprocess output and UI fields.
var MAX_STDERR_BYTES = 16384
var MAX_STDOUT_LINES = 512
var MAX_LINE_CHARS = 4096
var MAX_FIELD_CHARS = 256
var MAX_PROFILES = 64
var PROCESS_TIMEOUT_MS = 120000

function capText(value, max) {
  var limit = max === undefined || max === null ? MAX_FIELD_CHARS : Number(max)
  if (!isFinite(limit) || limit < 0) limit = MAX_FIELD_CHARS
  var s = String(value || "")
  return s.length <= limit ? s : s.slice(0, limit)
}

function parseBoundedFloat(raw, maxValue) {
  var s = capText(raw, 64).trim()
  if (!s || !/^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$/.test(s)) return NaN
  var value = Number(s)
  var ceiling = maxValue === undefined || maxValue === null ? 1e12 : Number(maxValue)
  if (!isFinite(value) || value < 0 || value > ceiling) return NaN
  return value
}

if (typeof module !== "undefined") {
  module.exports = {
    MAX_STDERR_BYTES: MAX_STDERR_BYTES,
    MAX_STDOUT_LINES: MAX_STDOUT_LINES,
    MAX_LINE_CHARS: MAX_LINE_CHARS,
    MAX_FIELD_CHARS: MAX_FIELD_CHARS,
    MAX_PROFILES: MAX_PROFILES,
    PROCESS_TIMEOUT_MS: PROCESS_TIMEOUT_MS,
    capText: capText,
    parseBoundedFloat: parseBoundedFloat
  }
}
