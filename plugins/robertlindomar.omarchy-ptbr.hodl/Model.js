// Pure helpers for the HODL plugin. No QML imports on purpose, so every
// function here runs in a plain JS harness.

var HALVING_INTERVAL = 210000
var SATS_PER_BTC = 100000000

var CURRENCY_SYMBOLS = {
  usd: "$", eur: "€", gbp: "£", jpy: "¥", chf: "CHF ",
  cad: "C$", aud: "A$", mxn: "MX$", ars: "AR$", brl: "R$"
}

function currencySymbol(code) {
  var key = String(code || "usd").toLowerCase()
  return CURRENCY_SYMBOLS[key] !== undefined ? CURRENCY_SYMBOLS[key] : (key.toUpperCase() + " ")
}

// ---------------------------------------------------------------- formatting

// Market convention: comma thousands, dot decimals. Deliberately not locale
// derived — the bar, the panel, and the CLI have to agree on one shape, and a
// price that changes separators between surfaces reads as a different number.
function fmtNumber(value, decimals) {
  var n = Number(value)
  if (!isFinite(n)) return "—"
  var d = decimals === undefined ? 2 : decimals
  var negative = n < 0
  var fixed = Math.abs(n).toFixed(d)
  var parts = fixed.split(".")
  var whole = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  return (negative ? "-" : "") + whole + (parts[1] ? "." + parts[1] : "")
}

// Prices swing over five orders of magnitude across currencies (JPY vs USD)
// and across a position's life, so decimals follow magnitude rather than a
// fixed setting.
function priceDecimals(value) {
  var n = Math.abs(Number(value) || 0)
  if (n >= 1000) return 0
  if (n >= 100) return 1
  if (n >= 1) return 2
  return 4
}

function fmtMoney(value, code, decimals) {
  if (value === null || value === undefined || !isFinite(Number(value))) return "—"
  var d = decimals === undefined ? priceDecimals(value) : decimals
  var n = Number(value)
  return (n < 0 ? "-" : "") + currencySymbol(code) + fmtNumber(Math.abs(n), d)
}

function fmtMoneySigned(value, code, decimals) {
  var n = Number(value)
  if (!isFinite(n)) return "—"
  return (n >= 0 ? "+" : "-") + currencySymbol(code) + fmtNumber(Math.abs(n), decimals === undefined ? 2 : decimals)
}

function fmtPct(value, decimals) {
  var n = Number(value)
  if (!isFinite(n)) return "—"
  var d = decimals === undefined ? 2 : decimals
  return (n >= 0 ? "+" : "-") + Math.abs(n).toFixed(d) + "%"
}

// Bar real estate is scarce, so the pill drops to k/M once the number stops
// fitting; the panel always shows the full figure.
function fmtCompact(value, code) {
  var n = Number(value)
  if (!isFinite(n)) return "—"
  var sym = currencySymbol(code)
  var abs = Math.abs(n)
  if (abs >= 1000000) return sym + (n / 1000000).toFixed(2) + "M"
  if (abs >= 10000) return sym + (n / 1000).toFixed(1) + "k"
  return sym + fmtNumber(n, priceDecimals(n))
}

// Trailing zeros on an eight-decimal amount are noise; 0.025 reads faster
// than 0.02500000. Never trimmed below two decimals so amounts stay in a
// column.
function fmtBtc(amount) {
  var n = Number(amount)
  if (!isFinite(n)) return "—"
  var s = n.toFixed(8)
  s = s.replace(/(\.\d{2}\d*?)0+$/, "$1")
  return s
}

function fmtSats(amount) {
  var n = Math.round(Number(amount) * SATS_PER_BTC)
  if (!isFinite(n)) return "—"
  return fmtNumber(n, 0) + " sats"
}

function fmtHashrate(hashes) {
  var n = Number(hashes)
  if (!isFinite(n) || n <= 0) return "—"
  var units = ["H/s", "kH/s", "MH/s", "GH/s", "TH/s", "PH/s", "EH/s", "ZH/s"]
  var i = 0
  while (n >= 1000 && i < units.length - 1) { n = n / 1000; i++ }
  return n.toFixed(n >= 100 ? 0 : 1) + " " + units[i]
}

function fmtDate(value) {
  var d = value instanceof Date ? value : new Date(String(value) + "T00:00:00")
  if (isNaN(d.getTime())) return String(value || "")
  var m = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
  return m[d.getMonth()] + " " + d.getDate() + " " + String(d.getFullYear()).slice(2)
}

function isoDate(date) {
  var d = date || new Date()
  var pad = function (n) { return (n < 10 ? "0" : "") + n }
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function daysHeld(dateStr) {
  var d = new Date(String(dateStr) + "T00:00:00")
  if (isNaN(d.getTime())) return 0
  return Math.max(0, Math.floor((Date.now() - d.getTime()) / 86400000))
}

// Compact relative time for freshness stamps: "6h", "12m", "3d".
function fmtSpan(seconds) {
  var n = Math.abs(Math.round(Number(seconds) || 0))
  if (n < 90) return n + "s"
  if (n < 5400) return Math.round(n / 60) + "m"
  if (n < 172800) return Math.round(n / 3600) + "h"
  return Math.round(n / 86400) + "d"
}

function fmtDuration(days) {
  var n = Math.max(0, Math.floor(Number(days) || 0))
  if (n < 1) return "hoje"
  if (n < 60) return n + "d"
  if (n < 730) return Math.round(n / 30.44) + "mo"
  return (n / 365.25).toFixed(1) + "y"
}

// ------------------------------------------------------------------ parsing

// Fiat: a lone separator followed by exactly three digits is a thousands
// group ("78,417"), anything else is a decimal point ("0,05"). When both
// separators appear the last one wins, which covers 1.234,56 and 1,234.56.
function parsePrice(text) {
  var s = String(text === null || text === undefined ? "" : text).replace(/\s/g, "")
  s = s.replace(/[^0-9.,\-]/g, "")
  if (s === "" || s === "-") return NaN

  var lastDot = s.lastIndexOf(".")
  var lastComma = s.lastIndexOf(",")
  if (lastDot >= 0 && lastComma >= 0) {
    var decimalAt = Math.max(lastDot, lastComma)
    return Number(s.slice(0, decimalAt).replace(/[.,]/g, "") + "." + s.slice(decimalAt + 1))
  }

  var sep = lastDot >= 0 ? "." : (lastComma >= 0 ? "," : "")
  if (sep === "") return Number(s)

  // Repeated separators can only be thousands groups: 1.234.567.
  if (s.split(sep).length > 2) return Number(s.replace(/[.,]/g, ""))

  var head = s.slice(0, s.indexOf(sep))
  var tail = s.slice(s.indexOf(sep) + 1)
  var wholeIsZero = head === "" || head === "0" || head === "-0"
  if (tail.length === 3 && !wholeIsZero) return Number(head + tail)
  return Number(head + "." + tail)
}

// BTC amounts never carry thousands groups in practice, and "1.000" meaning
// one bitcoin is the reading that loses money if guessed wrong. Both
// separators are decimal points here.
function parseBtcNumber(text) {
  var s = String(text === null || text === undefined ? "" : text).replace(/[\s ]/g, "").replace(/,/g, ".")
  s = s.replace(/[^0-9.\-]/g, "")
  var firstDot = s.indexOf(".")
  if (firstDot >= 0) s = s.slice(0, firstDot + 1) + s.slice(firstDot + 1).replace(/\./g, "")
  if (s === "" || s === "-" || s === ".") return NaN
  return Number(s)
}

// The size field accepts what people actually have written down: an amount in
// bitcoin ("0.025"), in sats ("250k sats"), or the fiat they spent ("$500"),
// which needs the unit price to become a position.
function parseSizeInput(text, unitPrice, code) {
  var raw = String(text || "").trim()
  if (raw === "") return { btc: NaN, error: "Informe uma quantidade" }
  var lower = raw.toLowerCase()
  var symbol = currencySymbol(code).trim().toLowerCase()
  var currencyCode = String(code || "usd").toLowerCase()

  var multiplier = 1
  var body = lower
  if (/(k|thousand)\s*sats?$/.test(body)) { multiplier = 1000; body = body.replace(/(k|thousand)\s*sats?$/, "") }
  else if (/m\s*sats?$/.test(body)) { multiplier = 1000000; body = body.replace(/m\s*sats?$/, "") }

  if (/sats?$/.test(body) || multiplier > 1) {
    var sats = parseBtcNumber(body.replace(/sats?$/, "")) * multiplier
    if (!isFinite(sats) || sats <= 0) return { btc: NaN, error: "Quantidade de sats inválida" }
    return { btc: sats / SATS_PER_BTC, error: "" }
  }

  var isFiat = (symbol !== "" && (body.indexOf(symbol) === 0 || body.slice(-symbol.length) === symbol))
    || body.indexOf(currencyCode) >= 0
    || /^[$€£¥]/.test(body) || /[$€£¥]$/.test(body)
  if (isFiat) {
    var price = Number(unitPrice)
    if (!isFinite(price) || price <= 0) return { btc: NaN, error: "Sem preço ainda — informe BTC" }
    var spend = parsePrice(body)
    if (!isFinite(spend) || spend <= 0) return { btc: NaN, error: "Quantidade inválida" }
    return { btc: spend / price, error: "" }
  }

  var btc = parseBtcNumber(body)
  if (!isFinite(btc) || btc <= 0) return { btc: NaN, error: "Quantidade inválida" }
  return { btc: btc, error: "" }
}

function parseDateInput(text) {
  var raw = String(text || "").trim()
  if (raw === "" || raw.toLowerCase() === "today") return { date: isoDate(new Date()), error: "" }
  var iso = raw.match(/^(\d{4})[-\/.](\d{1,2})[-\/.](\d{1,2})$/)
  var dmy = raw.match(/^(\d{1,2})[-\/.](\d{1,2})[-\/.](\d{4})$/)
  var y, m, d
  if (iso) { y = +iso[1]; m = +iso[2]; d = +iso[3] }
  else if (dmy) { y = +dmy[3]; m = +dmy[2]; d = +dmy[1] }
  else return { date: "", error: "Use AAAA-MM-DD" }
  if (m < 1 || m > 12 || d < 1 || d > 31) return { date: "", error: "Data inválida" }
  var probe = new Date(y, m - 1, d)
  if (probe.getMonth() !== m - 1 || probe.getDate() !== d) return { date: "", error: "Data inválida" }
  if (probe.getTime() > Date.now() + 86400000) return { date: "", error: "Data no futuro" }
  return { date: isoDate(probe), error: "" }
}

// ---------------------------------------------------------------- portfolio

function normalizePosition(entry) {
  if (!entry || typeof entry !== "object") return null
  var amount = Number(entry.amount)
  var price = Number(entry.price)
  if (!isFinite(amount) || amount <= 0) return null
  if (!isFinite(price) || price < 0) return null
  return {
    id: String(entry.id || ""),
    date: String(entry.date || ""),
    amount: amount,
    price: price,
    currency: String(entry.currency || "usd").toLowerCase(),
    fee: isFinite(Number(entry.fee)) ? Number(entry.fee) : 0,
    note: String(entry.note || "")
  }
}

function positionMetrics(position, price) {
  var cost = position.amount * position.price + (position.fee || 0)
  var value = position.amount * Number(price || 0)
  var pl = value - cost
  return {
    cost: cost,
    value: value,
    pl: pl,
    plPct: cost > 0 ? (pl / cost) * 100 : 0,
    days: daysHeld(position.date)
  }
}

// True when the book holds a cost basis recorded in some other currency than
// the one on screen. Summing those is meaningless, so the panel says so
// rather than quietly adding euros to dollars.
function hasForeignPositions(positions, currency) {
  var code = String(currency || "usd").toLowerCase()
  for (var i = 0; i < positions.length; i++) {
    var own = String(positions[i].currency || code).toLowerCase()
    if (own !== code) return true
  }
  return false
}

function portfolioTotals(positions, price) {
  var btc = 0, cost = 0
  for (var i = 0; i < positions.length; i++) {
    btc += positions[i].amount
    cost += positions[i].amount * positions[i].price + (positions[i].fee || 0)
  }
  var value = btc * Number(price || 0)
  var pl = value - cost
  return {
    count: positions.length,
    btc: btc,
    cost: cost,
    value: value,
    pl: pl,
    plPct: cost > 0 ? (pl / cost) * 100 : 0,
    avgPrice: btc > 0 ? cost / btc : 0,
    breakEven: btc > 0 ? cost / btc : 0
  }
}

// Newest first: the position you are still thinking about is the one you
// just opened.
function sortPositions(positions) {
  return positions.slice().sort(function (a, b) {
    if (a.date === b.date) return String(b.id).localeCompare(String(a.id))
    return a.date < b.date ? 1 : -1
  })
}

// ------------------------------------------------------------------- market

// Five buckets, because the mantra bank and the color of the pill both want
// "quietly green" to read differently from "up nine percent".
function regime(change24h) {
  var n = Number(change24h)
  if (!isFinite(n)) return "flat"
  if (n >= 5) return "moon"
  if (n >= 1) return "up"
  if (n > -1) return "flat"
  if (n > -5) return "down"
  return "crash"
}

function fngLabel(value) {
  var n = Number(value)
  if (!isFinite(n)) return ""
  if (n <= 24) return "Extreme fear"
  if (n <= 44) return "Fear"
  if (n <= 55) return "Neutral"
  if (n <= 74) return "Greed"
  return "Extreme greed"
}

// Camada de apresentação PT-BR — fngLabel permanece em inglês para lógica interna.
function fngLabelDisplay(value) {
  var key = fngLabel(value)
  var map = {
    "Extreme fear": "Medo extremo",
    "Fear": "Medo",
    "Neutral": "Neutro",
    "Greed": "Ganância",
    "Extreme greed": "Ganância extrema"
  }
  return map[key] || key
}

function nextHalving(height) {
  var h = Number(height)
  if (!isFinite(h) || h <= 0) return null
  var block = (Math.floor(h / HALVING_INTERVAL) + 1) * HALVING_INTERVAL
  var blocksLeft = block - h
  return {
    block: block,
    blocksLeft: blocksLeft,
    days: Math.round(blocksLeft * 10 / 1440),
    subsidy: 50 / Math.pow(2, Math.floor(h / HALVING_INTERVAL) + 1)
  }
}

// --------------------------------------------------------------- candlesticks

// CoinGecko returns [openTimeMs, o, h, l, c]. Long windows come back with
// more candles than a 380px panel can draw, so neighbours are merged into
// buckets rather than dropped — a skipped candle hides a wick, a merged one
// keeps the high and the low.
function normalizeCandles(raw, maxCandles) {
  if (!Array.isArray(raw) || raw.length === 0) return []
  var rows = []
  for (var i = 0; i < raw.length; i++) {
    var r = raw[i]
    if (!Array.isArray(r) || r.length < 5) continue
    var candle = { t: Number(r[0]), o: Number(r[1]), h: Number(r[2]), l: Number(r[3]), c: Number(r[4]) }
    if (!isFinite(candle.o) || !isFinite(candle.c)) continue
    rows.push(candle)
  }
  var cap = Math.max(8, Number(maxCandles) || 60)
  if (rows.length <= cap) return rows

  var group = Math.ceil(rows.length / cap)
  var merged = []
  for (var j = 0; j < rows.length; j += group) {
    var chunk = rows.slice(j, j + group)
    var high = chunk[0].h, low = chunk[0].l
    for (var k = 1; k < chunk.length; k++) {
      if (chunk[k].h > high) high = chunk[k].h
      if (chunk[k].l < low) low = chunk[k].l
    }
    merged.push({ t: chunk[0].t, o: chunk[0].o, h: high, l: low, c: chunk[chunk.length - 1].c })
  }
  return merged
}

function candleBounds(candles, extraValues) {
  var min = Infinity, max = -Infinity
  for (var i = 0; i < candles.length; i++) {
    if (candles[i].l < min) min = candles[i].l
    if (candles[i].h > max) max = candles[i].h
  }
  var extras = extraValues || []
  for (var j = 0; j < extras.length; j++) {
    var v = Number(extras[j])
    if (!isFinite(v) || v <= 0) continue
    if (v < min) min = v
    if (v > max) max = v
  }
  if (!isFinite(min) || !isFinite(max)) return { min: 0, max: 1 }
  if (min === max) return { min: min * 0.995, max: max * 1.005 }
  var pad = (max - min) * 0.06
  return { min: min - pad, max: max + pad }
}

var TIMEFRAMES = [
  { key: "1D", days: 1, label: "24 horas" },
  { key: "7D", days: 7, label: "7 dias" },
  { key: "1M", days: 30, label: "30 dias" },
  { key: "3M", days: 90, label: "90 dias" },
  { key: "1Y", days: 365, label: "1 ano" }
]

function timeframeAt(index) {
  return TIMEFRAMES[Math.max(0, Math.min(TIMEFRAMES.length - 1, index))]
}
