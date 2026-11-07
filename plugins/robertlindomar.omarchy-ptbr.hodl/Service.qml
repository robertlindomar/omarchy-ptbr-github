import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model
import "Mantras.js" as Mantras

// Market state for the widget: price, sentiment, chain stats, candles, and
// the two things that interrupt you — a big move, and the daily digest.
//
// Nothing is fetched in QML directly. `bin/hodl` owns every HTTP call and
// every disk cache, so the terminal and the bar always quote the same number,
// and a one-minute poll only reaches the network for the sources whose TTL
// has actually expired.
Item {
  id: root

  property var settings: ({})

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  readonly property string cliPath: String(Qt.resolvedUrl("bin/hodl")).replace(/^file:\/\//, "")
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy-hodl"

  readonly property string currency: String(setting("currency", "USD")).toLowerCase()
  readonly property int refreshSeconds: Math.max(30, parseInt(setting("refreshSeconds", 60), 10) || 60)
  readonly property bool notificationsEnabled: setting("notifications", true) !== false
  readonly property int alertPercent: Math.max(0, parseInt(setting("alertPercent", 5), 10) || 0)
  readonly property int reminderHours: Math.max(0, parseInt(setting("hodlReminderHours", 6), 10) || 0)
  readonly property int newsletterHour: Math.max(0, Math.min(23, parseInt(setting("newsletterHour", 9), 10) || 0))

  // Each source is polled at the speed of the thing it measures, not at one
  // global heartbeat. Price is the only value on screen while the panel is
  // shut, so it is the only one on the fast clock; the greed index is
  // published once a day; the chain stats are panel-only, so they are not
  // fetched at all until the panel is open.
  readonly property int fngIntervalSec: 3600
  readonly property int networkIntervalSec: 900

  // Set by the panel, so a closed panel stops paying for what it is not
  // showing.
  property bool panelOpen: false

  // ---- market ------------------------------------------------------------
  property var market: ({})
  property var fng: ({})
  property var network: ({})
  property double marketAt: 0
  property double fngAt: 0
  property double networkAt: 0
  property string lastError: ""
  property bool loading: false
  property bool everLoaded: false

  readonly property bool hasPrice: market && isFinite(Number(market.price)) && Number(market.price) > 0
  readonly property real price: hasPrice ? Number(market.price) : 0
  readonly property real change24h: market && isFinite(Number(market.change24h)) ? Number(market.change24h) : 0
  readonly property real change7d: market && isFinite(Number(market.change7d)) ? Number(market.change7d) : 0
  readonly property real change30d: market && isFinite(Number(market.change30d)) ? Number(market.change30d) : 0
  readonly property real high24h: market && isFinite(Number(market.high24h)) ? Number(market.high24h) : 0
  readonly property real low24h: market && isFinite(Number(market.low24h)) ? Number(market.low24h) : 0
  readonly property real ath: market && isFinite(Number(market.ath)) ? Number(market.ath) : 0
  readonly property real athChangePct: market && isFinite(Number(market.athChangePct)) ? Number(market.athChangePct) : 0
  readonly property string regime: Model.regime(change24h)

  readonly property int fngValue: fng && isFinite(Number(fng.value)) ? Number(fng.value) : -1
  readonly property int fngYesterday: fng && isFinite(Number(fng.yesterday)) ? Number(fng.yesterday) : -1
  readonly property string fngLabel: fngValue >= 0 ? Model.fngLabel(fngValue) : ""
  readonly property string fngLabelDisplay: fngValue >= 0 ? Model.fngLabelDisplay(fngValue) : ""

  // The index itself only moves once a day. These two make that visible, so a
  // number that has not changed since yesterday still looks alive.
  readonly property double fngPublishedAt: fng && isFinite(Number(fng.timestamp)) ? Number(fng.timestamp) : 0
  readonly property double fngNextUpdate: fng && isFinite(Number(fng.nextUpdate)) ? Number(fng.nextUpdate) : 0

  readonly property int blockHeight: network && isFinite(Number(network.height)) ? Number(network.height) : 0
  readonly property var halving: Model.nextHalving(blockHeight)

  // ---- phrases -----------------------------------------------------------
  //
  // A counter rather than a random draw: the same tick renders the same line
  // on every repaint, and the line only turns over when this advances.
  property int phraseSeed: Math.floor(Date.now() / 3600000)
  readonly property string heroLine: Mantras.heroLine(regime, fngValue >= 0 ? fngValue : undefined, phraseSeed)
  readonly property string sentimentLine: fngValue >= 0 ? Mantras.sentimentLine(fngValue) : ""

  function nextPhrase() { phraseSeed = phraseSeed + 1 }

  // ---- candles -----------------------------------------------------------
  property int timeframeIndex: 1
  readonly property var timeframe: Model.timeframeAt(timeframeIndex)
  property var candles: []
  property int candlesDays: 0
  property bool candlesLoading: false
  property string candlesError: ""
  property var candleCache: ({})
  property var candleAt: ({})

  // A year of candles does not move in an hour; a day of candles does. Same
  // numbers the CLI uses on disk, applied here so flipping ranges does not
  // even spawn a process.
  readonly property var candleTtl: ({ "1": 300, "7": 900, "30": 3600, "90": 21600, "365": 43200 })

  // Low, high and change over the window actually on screen, derived from the
  // candles rather than fetched: the header has to describe the period the
  // chart is showing, not a fixed 24 hours next to a one-year chart.
  readonly property var rangeStats: {
    var rows = candles || []
    if (rows.length === 0 || candlesDays !== timeframe.days) return null
    var low = rows[0].l
    var high = rows[0].h
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].l < low) low = rows[i].l
      if (rows[i].h > high) high = rows[i].h
    }
    var open = rows[0].o
    // Closing on the live price, not the last candle's close, so the number
    // moves with the pill.
    var last = hasPrice ? price : rows[rows.length - 1].c
    return {
      low: low,
      high: high,
      open: open,
      changePct: open > 0 ? ((last - open) / open) * 100 : 0
    }
  }

  // ---- digest ------------------------------------------------------------
  property var newsletter: null
  property bool newsLoading: false

  // Anything in flight, for the panel's global "updating" mark.
  readonly property bool busy: loading || candlesLoading || newsLoading

  signal marketUpdated()

  // ------------------------------------------------------------------ fetch

  // `sources` names what to actually go and get; everything else still comes
  // back from the CLI's disk cache, so a price-only poll returns a complete
  // snapshot and no section of the panel ever goes blank.
  function refresh(force, sources) {
    if (snapshotProc.running) return
    loading = true
    var args = [cliPath, "fetch", "--currency", currency]
    if (sources && sources.length > 0) args = args.concat(["--sources", sources.join(",")])
    if (force) args.push("--force")
    snapshotProc.command = args
    snapshotProc.running = true
  }

  function refreshAll(force) {
    refresh(force, ["market", "fng", "network"])
  }

  // Hovering the bar pill is a request to look at the price, so it is worth
  // one call if the last one has gone cold.
  function refreshIfStale(maxAgeSec) {
    if (snapshotProc.running) return
    var age = Date.now() / 1000 - marketAt
    if (age > (maxAgeSec || 45)) refresh(false, ["market"])
  }

  // What is actually due, evaluated every tick.
  function tick() {
    var now = Date.now() / 1000
    var sources = ["market"]
    if (now - fngAt > fngIntervalSec) sources.push("fng")
    if (panelOpen && now - networkAt > networkIntervalSec) sources.push("network")
    refresh(false, sources)
  }

  function hasKeys(obj) {
    if (!obj || typeof obj !== "object") return false
    for (var k in obj) return true
    return false
  }

  function applySnapshot(raw) {
    try {
      var snap = JSON.parse(String(raw || ""))
      if (snap && snap.market && isFinite(Number(snap.market.price))) {
        market = snap.market
        marketAt = Number(snap.marketAt) || Date.now() / 1000
        lastError = String(snap.error || "")
        everLoaded = true
      } else if (!everLoaded) {
        lastError = String((snap && snap.error) || "sem dados")
      }
      // Only ever replace with something. A source that is down comes back
      // as {} once its disk cache is gone, and an empty object would take
      // the sentiment gauge and the network line off the panel entirely —
      // the last known reading is always better than a hole.
      if (snap && hasKeys(snap.fng)) {
        fng = snap.fng
        fngAt = Number(snap.fngAt) || fngAt
      }
      if (snap && hasKeys(snap.network)) {
        network = snap.network
        networkAt = Number(snap.networkAt) || networkAt
      }
      marketUpdated()
      evaluateAlert()
    } catch (e) {
      lastError = "resposta inválida"
    }
  }

  function setTimeframe(index) {
    var next = Math.max(0, Math.min(Model.TIMEFRAMES.length - 1, index))
    if (next === timeframeIndex && candles.length > 0) return
    timeframeIndex = next
    loadCandles()
  }

  function cycleTimeframe(step) {
    var n = Model.TIMEFRAMES.length
    setTimeframe(((timeframeIndex + step) % n + n) % n)
  }

  // Candles are cached per timeframe in memory as well as on disk: flipping
  // 7D → 1M → 7D should not repaint an empty chart while a process starts.
  function loadCandles(force) {
    var days = timeframe.days
    var key = currency + "-" + days
    if (!force && candleCache[key]) {
      candles = candleCache[key]
      candlesDays = days
      candlesError = ""
      var ttl = Number(candleTtl[String(days)]) || 3600
      var age = Date.now() / 1000 - (Number(candleAt[key]) || 0)
      if (age < ttl) return
    }
    if (candlesProc.running) return
    // True for every fetch, not just the first: the chart keeps showing the
    // previous range while the new one is in flight, and the spinner is the
    // only thing that says so.
    candlesLoading = true
    candlesProc.command = [cliPath, "candles", "--days", String(days), "--currency", currency].concat(force ? ["--force"] : [])
    candlesProc.running = true
  }

  function applyCandles(raw) {
    candlesLoading = false
    try {
      var doc = JSON.parse(String(raw || ""))
      var rows = Model.normalizeCandles(doc.candles, 64)
      if (rows.length === 0) {
        candlesError = doc.error ? String(doc.error) : "sem candles"
        return
      }
      var cache = {}
      for (var key in candleCache) cache[key] = candleCache[key]
      var fetchedKey = currency + "-" + doc.days
      cache[fetchedKey] = rows
      candleCache = cache
      candleAt[fetchedKey] = Number(doc.fetchedAt) || Date.now() / 1000
      if (Number(doc.days) === timeframe.days) {
        candles = rows
        candlesDays = timeframe.days
        candlesError = ""
      }
    } catch (e) {
      candlesError = "dados de candles inválidos"
    }
  }

  function refreshNews(force) {
    if (newsProc.running) return
    newsLoading = true
    newsProc.command = [cliPath, "news", "--json", "--currency", currency].concat(force ? ["--force"] : [])
    newsProc.running = true
  }

  // ------------------------------------------------------------- notifying

  function notify(headline, body, urgency) {
    if (!notificationsEnabled) return
    Util.execArgv(["omarchy-notification-send", "--app-name", "HODL", "-g", "₿",
                   "-u", String(urgency || "low"), String(headline), String(body || "")])
  }

  // One alert per direction per cooldown: a day that keeps sliding should
  // interrupt once, not once per poll, but a reversal from -6% to +6% is
  // genuinely new information.
  readonly property int alertCooldownSec: 6 * 3600

  function evaluateAlert() {
    if (!notificationsEnabled || alertPercent <= 0 || !hasPrice) return
    if (Math.abs(change24h) < alertPercent) return
    var direction = change24h >= 0 ? "up" : "down"
    var now = Date.now() / 1000
    if (direction === persisted.lastAlertDirection && now - persisted.lastAlertAt < alertCooldownSec) return

    notify(Mantras.alertHeadline(regime, change24h),
           Model.fmtMoney(price, currency) + "  " + Model.fmtPct(change24h) + " em 24h — "
             + Mantras.alertBody(regime, phraseSeed),
           regime === "crash" || regime === "moon" ? "normal" : "low")
    persisted.lastAlertAt = now
    persisted.lastAlertDirection = direction
    savePersisted()
  }

  function sendReminder() {
    if (!notificationsEnabled || reminderHours <= 0) return
    nextPhrase()
    var line = Mantras.reminder(phraseSeed)
    var suffix = hasPrice ? Model.fmtMoney(price, currency) + "  " + Model.fmtPct(change24h) : ""
    notify(line, suffix, "low")
    persisted.lastReminderAt = Date.now() / 1000
    savePersisted()
  }

  // The digest is a wall-clock event, not an interval: it fires the first
  // time the shell is awake at or after the configured hour on a new day, so
  // a machine that was off at 09:00 still gets today's issue at 11:20.
  function maybeSendNewsletter() {
    if (!notificationsEnabled) return
    var now = new Date()
    var today = Model.isoDate(now)
    if (persisted.lastNewsletterDate === today) return
    if (now.getHours() < newsletterHour) return
    pendingNewsletterNotify = true
    refreshNews(false)
  }

  property bool pendingNewsletterNotify: false

  function deliverNewsletter(news) {
    var today = Model.isoDate(new Date())
    persisted.lastNewsletterDate = today
    savePersisted()

    var m = news.market || {}
    var headline = "₿ " + Model.fmtMoney(m.price, currency) + "   " + Model.fmtPct(m.change24h)
    var lines = []
    if (news.fng && news.fng.value !== undefined)
      lines.push("Sentimento " + news.fng.value + "/100 · " + Model.fngLabelDisplay(news.fng.value))
    if (news.portfolio && news.portfolio.count > 0)
      lines.push("Sua carteira " + Model.fmtMoney(news.portfolio.value, currency)
                 + "  " + Model.fmtPct(news.portfolio.plPct))
    var heads = news.headlines || []
    for (var i = 0; i < Math.min(3, heads.length); i++)
      lines.push("• " + heads[i].title)
    lines.push(news.mantra || "HODL.")
    notify(headline, lines.join("\n"), "normal")
  }

  // ------------------------------------------------------------- processes

  Process {
    id: snapshotProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.loading = false
        root.applySnapshot(text)
      }
    }
    onExited: function (code) {
      root.loading = false
      if (code !== 0 && !root.everLoaded && root.lastError === "") root.lastError = "hodl encerrou com código " + code
    }
  }

  Process {
    id: candlesProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyCandles(text)
    }
    onExited: root.candlesLoading = false
  }

  Process {
    id: newsProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.newsLoading = false
        try {
          var doc = JSON.parse(String(text || ""))
          if (doc && doc.date) {
            root.newsletter = doc
            if (root.pendingNewsletterNotify) {
              root.pendingNewsletterNotify = false
              root.deliverNewsletter(doc)
            }
          }
        } catch (e) {
          root.pendingNewsletterNotify = false
        }
      }
    }
    onExited: root.newsLoading = false
  }

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.stateDir]
    running: true
    onExited: stateFile.reload()
  }

  // ------------------------------------------------------- persisted state

  property var persisted: ({
    lastAlertAt: 0,
    lastAlertDirection: "",
    lastReminderAt: 0,
    lastNewsletterDate: ""
  })

  function savePersisted() {
    stateFile.setText(JSON.stringify(persisted, null, 2) + "\n")
  }

  FileView {
    id: stateFile
    path: root.stateDir + "/shell-state.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var doc = JSON.parse(text() || "{}")
        root.persisted = {
          lastAlertAt: Number(doc.lastAlertAt) || 0,
          lastAlertDirection: String(doc.lastAlertDirection || ""),
          lastReminderAt: Number(doc.lastReminderAt) || 0,
          lastNewsletterDate: String(doc.lastNewsletterDate || "")
        }
      } catch (e) {
        // Corrupt state only costs one duplicate notification.
      }
      root.bootstrap()
    }
    onLoadFailed: root.bootstrap()
  }

  property bool bootstrapped: false

  function bootstrap() {
    if (bootstrapped) return
    bootstrapped = true
    refreshAll(false)
    // Give the first price a head start before the digest check runs, so the
    // notification it may send is not built from an empty snapshot.
    newsletterTimer.start()
  }

  // ---------------------------------------------------------------- timers

  Timer {
    id: refreshTimer
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    onTriggered: root.tick()
  }

  // Reminders are wall-clock spaced, so restarting the shell at 10:59 does
  // not reset a six-hour cadence that was about to fire.
  Timer {
    id: reminderTimer
    interval: 60000
    running: root.reminderHours > 0
    repeat: true
    triggeredOnStart: false
    onTriggered: {
      var now = Date.now() / 1000
      var due = root.persisted.lastReminderAt + root.reminderHours * 3600
      if (root.persisted.lastReminderAt <= 0) {
        // First run: start the clock instead of firing immediately.
        root.persisted.lastReminderAt = now
        root.savePersisted()
        return
      }
      if (now >= due) root.sendReminder()
    }
  }

  Timer {
    id: newsletterTimer
    interval: 20000
    repeat: true
    triggeredOnStart: false
    onTriggered: {
      interval = 300000
      root.maybeSendNewsletter()
    }
  }

  // Rotate the hero line on a slow beat so the panel is never quoting the
  // same slogan for an hour.
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.nextPhrase()
  }
}
