function failure(message) {
  return { screen: null, connector: "", label: "", error: message }
}

// Resolve a saved/draft output through its current hardware key. A connector
// saved at another desk must never identify a different monitor at this desk.
function target(output, currentProfile, editorDisplays, screens) {
  var requested = output || {}
  var key = String(requested.key || "")
  var outputs = currentProfile && currentProfile.outputs instanceof Array ? currentProfile.outputs : []
  var metadata = editorDisplays instanceof Array ? editorDisplays : []
  var current = null
  var connected = null
  if (key === "") return failure("Escolha um monitor conectado para identificar.")
  for (var i = 0; i < outputs.length; i++) {
    if (String((outputs[i] || {}).key || "") === key) {
      if (current) return failure("A identidade deste monitor é ambígua. Atualize a lista de monitores.")
      current = outputs[i]
    }
  }
  for (var j = 0; j < metadata.length; j++) {
    if (String((metadata[j] || {}).key || "") === key) connected = metadata[j]
  }
  if (!current || !connected)
    return failure("Este monitor salvo não está conectado. Identifique um dos monitores atuais.")
  if (current.enabled === false)
    return failure("Este monitor está desabilitado e não pode mostrar uma identificação.")
  if (String(current.mirror_of || "").trim() !== "")
    return failure("Este monitor espelha outra tela e não pode mostrar uma identificação separada.")
  if (connected.dpms === false)
    return failure("Este monitor está em repouso. Ative-o antes de identificá-lo.")
  var connector = String(current.name || "")
  var selected = null
  var available = screens || []
  for (var k = 0; k < available.length; k++) {
    if (available[k] && String(available[k].name || "") === connector) {
      if (selected) return failure("Este conector corresponde a várias telas. Atualize a lista de monitores.")
      selected = available[k]
    }
  }
  if (!selected) return failure("Este monitor ainda não está disponível para a área de trabalho. Atualize e tente novamente.")
  // Qt exposes a serial when the compositor supplies it. Use it as an extra
  // stale-snapshot check without guessing when either side lacks a serial.
  var expectedSerial = String(current.serial || "").trim()
  var screenSerial = String(selected.serialNumber || "").trim()
  if (expectedSerial !== "" && screenSerial !== "" && expectedSerial !== screenSerial)
    return failure("O monitor neste conector mudou. Atualize antes de identificá-lo.")
  var label = [String(current.make || "").trim(), String(current.model || "").trim()]
    .filter(function(part) { return part !== "" }).join(" ")
  return { screen: selected, connector: connector, label: label || connector, error: "" }
}

function containsScreen(screen, screens) {
  if (!screen) return false
  var available = screens || []
  for (var i = 0; i < available.length; i++) {
    if (available[i] === screen) return true
  }
  return false
}

if (typeof module !== "undefined") {
  module.exports = { target: target, containsScreen: containsScreen }
}
