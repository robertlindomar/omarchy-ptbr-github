// Pure-function tests for Model.js and Mantras.js. No QML, no network:
// `node tests/model.test.mjs` from the plugin root.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

const root = join(dirname(fileURLToPath(import.meta.url)), "..")
const load = (file, names) =>
  new Function(readFileSync(join(root, file), "utf8") + `; return {${names.join(",")}}`)()

const M = load("Model.js", [
  "parsePrice", "parseBtcNumber", "parseSizeInput", "parseDateInput", "isoDate",
  "fmtNumber", "fmtMoney", "fmtMoneySigned", "fmtPct", "fmtBtc", "fmtCompact",
  "fmtSats", "fmtHashrate", "fmtSpan", "fmtDuration", "positionMetrics",
  "portfolioTotals", "hasForeignPositions", "sortPositions", "normalizePosition",
  "normalizeCandles", "candleBounds", "regime", "fngLabel", "nextHalving",
  "timeframeAt", "TIMEFRAMES"
])
const P = load("Mantras.js", ["heroLine", "reminder", "alertHeadline", "alertBody", "sentimentLine", "positionLine", "HODL", "WISDOM"])

let failed = 0
const is = (label, got, want) => {
  const ok = String(got) === String(want)
  if (!ok) failed++
  console.log(`${ok ? "ok  " : "FAIL"} ${label}${ok ? "" : `  got ${got}, want ${want}`}`)
}

// ---- parsing: the money-losing cases first
is("price 78,417 is thousands", M.parsePrice("78,417"), 78417)
is("price 0,05 is decimal", M.parsePrice("0,05"), 0.05)
is("price 1.234,56 european", M.parsePrice("1.234,56"), 1234.56)
is("price 1,234.56 american", M.parsePrice("1,234.56"), 1234.56)
is("price 1.234.567 grouped", M.parsePrice("1.234.567"), 1234567)
is("price with symbol/spaces", M.parsePrice("$78 417.5"), 78417.5)
is("btc 1.000 is one coin", M.parseBtcNumber("1.000"), 1)
is("btc 0,05 is decimal", M.parseBtcNumber("0,05"), 0.05)

is("size in btc", M.parseSizeInput("0.025", 78000, "usd").btc, 0.025)
is("size in fiat", M.parseSizeInput("$500", 80000, "usd").btc, 0.00625)
is("size in fiat code", M.parseSizeInput("500 usd", 80000, "usd").btc, 0.00625)
is("size in sats", M.parseSizeInput("250k sats", 0, "usd").btc, 0.0025)
is("size rejects junk", M.parseSizeInput("abc", 1, "usd").error, "Quantidade inválida")
is("size rejects zero", M.parseSizeInput("0", 1, "usd").error, "Quantidade inválida")
is("size fiat needs a price", M.parseSizeInput("$500", 0, "usd").error, "Sem preço ainda — informe BTC")

is("date blank is today", M.parseDateInput("").date, M.isoDate(new Date()))
is("date dd/mm/yyyy", M.parseDateInput("14/03/2025").date, "2025-03-14")
is("date pads", M.parseDateInput("2025-3-4").date, "2025-03-04")
is("date rejects feb 31", M.parseDateInput("2025-02-31").error, "Data inválida")
is("date rejects the future", M.parseDateInput("2099-01-01").error, "Data no futuro")

// ---- formatting
is("number grouping", M.fmtNumber(78417.123, 2), "78,417.12")
is("money drops cents when large", M.fmtMoney(78417.4, "usd"), "$78,417")
is("money keeps sign outside symbol", M.fmtMoney(-1234.5, "eur", 2), "-€1,234.50")
is("signed money", M.fmtMoneySigned(430.8, "usd"), "+$430.80")
is("percent", M.fmtPct(-1.955), "-1.96%")
is("btc trims to two", M.fmtBtc(1.5), "1.50")
is("btc keeps sats", M.fmtBtc(0.00000123), "0.00000123")
is("compact k", M.fmtCompact(78417, "usd"), "$78.4k")
is("compact M", M.fmtCompact(1575182255261, "usd"), "$1575182.26M")
is("sats", M.fmtSats(0.0025), "250,000 sats")
is("hashrate", M.fmtHashrate(922341173643098000000), "922 EH/s")
is("span hours", M.fmtSpan(21600), "6h")
is("span minutes", M.fmtSpan(900), "15m")

// ---- book maths
const book = [
  { amount: 0.025, price: 61200, fee: 0, date: "2025-03-14", currency: "usd" },
  { amount: 0.01, price: 95000, fee: 0, date: "2025-11-02", currency: "usd" }
]
const t = M.portfolioTotals(book, 78417)
is("total btc", t.btc.toFixed(4), "0.0350")
is("total cost", t.cost.toFixed(2), "2480.00")
is("total value", t.value.toFixed(2), "2744.60")
is("total pl%", t.plPct.toFixed(2), "10.67")
is("break-even", Math.round(t.avgPrice), 70857)
is("fees count as cost", M.positionMetrics({ amount: 1, price: 100, fee: 10, date: "2025-01-01" }, 100).pl, -10)
is("empty book is safe", M.portfolioTotals([], 78417).plPct, 0)
is("newest first", M.sortPositions(book)[0].date, "2025-11-02")
is("rejects a zero amount", M.normalizePosition({ amount: 0, price: 1 }), null)
is("rejects a missing price", M.normalizePosition({ amount: 1 }), null)
is("spots foreign currency", M.hasForeignPositions([{ amount: 1, price: 1, currency: "eur" }], "usd"), true)
is("same currency is fine", M.hasForeignPositions(book, "usd"), false)

// ---- candles
const rows = Array.from({ length: 40 }, (_, i) => [i, i, i + 2, i - 1, i + 1])
const merged = M.normalizeCandles(rows, 10)
is("merged to the cap", merged.length, 10)
is("merge keeps the high", merged[0].h, 5)
is("merge keeps the low", merged[0].l, -1)
is("merge keeps the last close", merged.at(-1).c, 40)
is("bad rows are dropped", M.normalizeCandles([[1, "x", 2, 3, "y"]], 10).length, 0)
is("no candles, no bounds crash", M.candleBounds([]).max, 1)
is("bounds pad", M.candleBounds([{ o: 10, h: 12, l: 8, c: 11 }]).max > 12, true)

// ---- market
is("regime moon", M.regime(6), "moon")
is("regime crash", M.regime(-8), "crash")
is("regime flat", M.regime(0.2), "flat")
is("greed label", M.fngLabel(69), "Greed")
is("extreme fear label", M.fngLabel(12), "Extreme fear")
is("next halving block", M.nextHalving(964973).block, 1050000)
is("halving needs a height", M.nextHalving(0), null)
is("timeframes clamp", M.timeframeAt(99).key, "1Y")

// ---- phrases
is("hero line is never empty", P.heroLine("crash", 12, 3).length > 0, true)
is("hero rotates", P.heroLine("up", 50, 0) === P.heroLine("up", 50, 1), false)
is("reminder is never empty", P.reminder(7).length > 0, true)
is("moon headline", P.alertHeadline("moon", 7), "🚀 TO THE MOON")
is("phrase bank is stocked", P.HODL.length + P.WISDOM.length > 50, true)

console.log(failed === 0 ? "\nall green" : `\n${failed} failing`)
process.exit(failed === 0 ? 0 : 1)
