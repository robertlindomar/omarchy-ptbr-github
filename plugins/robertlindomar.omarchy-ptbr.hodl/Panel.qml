import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "Mantras.js" as Mantras

// One bar pill and one panel: the price, what you own, what it is worth, and
// a running reminder that the correct action is almost always none.
Panel {
  id: root
  moduleName: "robertlindomar.omarchy-ptbr.hodl"
  ipcTarget: "hodl"
  manageIpc: false

  // ---------------------------------------------------------------- theming

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property color faint: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.35)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Literal green and red by default: this is a P/L readout, and a theme
  // accent that happens to be pink makes a loss unreadable. "Theme" hands the
  // colors back to the palette for anyone who wants the bar to stay tonal.
  readonly property bool themeColors: String(setting("colors", "Green / red")) === "Theme"
  readonly property color upColor: themeColors ? (bar ? bar.accent : Color.accent) : "#3fb950"
  readonly property color downColor: themeColors ? (bar ? bar.urgent : Color.urgent) : "#f85149"

  function tint(value) { return Number(value) >= 0 ? upColor : downColor }

  // ------------------------------------------------------------------ state

  readonly property string currency: market.currency
  readonly property string barDisplay: String(setting("barDisplay", "Price + change"))

  property string view: "book"          // "book" | "news"

  // Which sections are unfolded. Persisted in this widget's shell.json entry,
  // so a panel you trimmed down stays trimmed across restarts.
  readonly property bool chartVisible: sectionOpen("chart")
  property bool cursorActive: false
  property int cursorIndex: 0
  property bool adding: false
  property string formError: ""
  property string pendingDeleteId: ""

  readonly property var positions: book.positions
  readonly property var totals: book.totals(market.price)
  readonly property bool hasBook: positions.length > 0
  readonly property var headlines: market.newsletter && market.newsletter.headlines ? market.newsletter.headlines : []

  readonly property int cursorMax: view === "news"
    ? Math.max(0, headlines.length - 1)
    : Math.max(0, positions.length - 1)

  readonly property var selectedPosition: (view === "book" && cursorActive && positions.length > 0)
    ? positions[Math.min(cursorIndex, positions.length - 1)]
    : null

  // ------------------------------------------------------------- bar label

  readonly property string barPrice: market.hasPrice
    ? Model.fmtCompact(market.price, currency)
    : "—"

  readonly property string barChange: market.hasPrice ? Model.fmtPct(market.change24h, 1) : ""

  readonly property string barPnl: hasBook && market.hasPrice ? Model.fmtPct(totals.plPct, 1) : ""

  readonly property bool barShowsChange: barDisplay === "Price + change" || barDisplay === "Change only"
  readonly property bool barShowsPrice: barDisplay !== "Change only" && barDisplay !== "Profit / loss" && barDisplay !== "Portfolio value"

  readonly property string barPrimary: {
    if (barDisplay === "Profit / loss") return hasBook ? Model.fmtMoneySigned(totals.pl, currency, 0) : barPrice
    if (barDisplay === "Portfolio value") return hasBook ? Model.fmtCompact(totals.value, currency) : barPrice
    if (barDisplay === "Change only") return market.hasPrice ? Model.fmtPct(market.change24h, 1) : "—"
    return barPrice
  }

  readonly property string barSecondary: {
    if (barDisplay === "Price + change") return barChange
    if (barDisplay === "Profit / loss") return hasBook ? barPnl : barChange
    return ""
  }

  readonly property real barTintValue: {
    if (barDisplay === "Profit / loss" || barDisplay === "Portfolio value") return hasBook ? totals.pl : market.change24h
    return market.change24h
  }

  // Header readings follow the chart when the chart is on screen, and fall
  // back to the fixed 24h/7d/30d windows when it is hidden.
  readonly property bool rangeHeader: market.rangeStats !== null

  readonly property real headlineChange: rangeHeader ? market.rangeStats.changePct : market.change24h
  readonly property string headlineLabel: rangeHeader ? market.timeframe.key : "24h"

  // Whatever the headline is not already saying.
  // One reference window next to the headline, not three: on a 1Y chart the
  // full set ran into the range column on the right.
  readonly property string otherChanges: {
    var key = rangeHeader ? market.timeframe.key : "24h"
    if (key === "1D" || key === "24h")
      return Model.fmtPct(market.change7d, 1) + " 7d · " + Model.fmtPct(market.change30d, 1) + " 30d"
    return Model.fmtPct(market.change24h, 1) + " 24h"
  }

  readonly property string tooltip: {
    if (!market.hasPrice) return "HODL — buscando preço…"
    var lines = ["₿ " + Model.fmtMoney(market.price, currency) + "   " + Model.fmtPct(market.change24h)]
    if (hasBook)
      lines.push(Model.fmtBtc(totals.btc) + " BTC · " + Model.fmtMoney(totals.value, currency)
                 + " · " + Model.fmtMoneySigned(totals.pl, currency, 0) + " (" + Model.fmtPct(totals.plPct, 1) + ")")
    if (market.fngValue >= 0) lines.push("Medo e ganância " + market.fngValue + " — " + market.fngLabelDisplay)
    lines.push(market.heroLine)
    return lines.join("\n")
  }

  // ------------------------------------------------------------- sections

  // Folds live here first and in shell.json second. Writing the config file
  // makes the shell reload it and hand `settings` back, and waiting on that
  // round trip is what made a fast second press of `z` look stuck: the panel
  // was reading a value the file had not caught up to yet. This layer is
  // authoritative for the session; the file is written behind it.
  property var foldOverrides: ({})

  function sectionOpen(name) {
    if (foldOverrides[name] !== undefined) return foldOverrides[name] !== false
    var stored = setting("sections", null)
    if (!stored || stored[name] === undefined || stored[name] === null) return true
    return stored[name] !== false
  }

  function setSections(changes) {
    var next = {}
    for (var k in foldOverrides) next[k] = foldOverrides[k]
    for (var c in changes) next[c] = changes[c] === true
    foldOverrides = next
    foldPersistTimer.restart()
    if (sectionOpen("chart")) market.loadCandles(false)
  }

  function setSection(name, open) {
    var one = {}
    one[name] = open === true
    setSections(one)
  }

  function toggleSection(name) {
    setSection(name, !sectionOpen(name))
  }

  // Folds the readouts, and only those. The chart is its own decision — `c`
  // owns it — because "show me less text" and "put the chart away" are not
  // the same intent, and one of them costs a fetch.
  function toggleFold() {
    var anyOpen = sectionOpen("book") || sectionOpen("sentiment") || sectionOpen("network")
    setSections({ book: !anyOpen, sentiment: !anyOpen, network: !anyOpen })
  }

  // Coalesces a burst of folding into a single config write.
  Timer {
    id: foldPersistTimer
    interval: 400
    onTriggered: {
      var merged = {}
      var stored = root.setting("sections", null)
      if (stored) for (var k in stored) merged[k] = stored[k]
      for (var j in root.foldOverrides) merged[j] = root.foldOverrides[j]
      root.saveSetting("sections", merged)
    }
  }

  // Write one key back into this widget's inline shell.json entry, the way
  // the stock clock persists a cycled format.
  function saveSetting(key, value) {
    var entry = { id: root.moduleName }
    for (var k in root.settings) if (k !== "id") entry[k] = root.settings[k]
    entry[key] = value
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  // ------------------------------------------------------------- behaviour

  function openPanel() {
    root.controller.show()
    market.refreshAll(false)
    book.reload()
    // Loaded even when the chart is folded: the header reads its range and
    // percentage off these, and the cache means this is a disk read.
    market.loadCandles(false)
    if (!market.newsletter) market.refreshNews(false)
    Qt.callLater(function () { keyCatcher.forceActiveFocus() })
  }

  function close() {
    cancelAdd()
    view = "book"
    pendingDeleteId = ""
    root.controller.hide()
  }

  function toggle() { opened ? close() : openPanel() }

  function moveCursor(step) {
    if (!cursorActive) { cursorActive = true; return }
    cursorIndex = Math.max(0, Math.min(cursorMax, cursorIndex + step))
    pendingDeleteId = ""
  }

  function setView(next) {
    view = next
    cursorIndex = 0
    cursorActive = false
    pendingDeleteId = ""
    if (next === "news" && !market.newsletter) market.refreshNews(false)
  }

  function startAdd() {
    if (view !== "book") setView("book")
    adding = true
    formError = ""
    amountField.text = ""
    priceField.text = ""
    dateField.text = Model.isoDate(new Date())
    Qt.callLater(function () { amountField.forceActiveFocus(); amountField.selectAll() })
  }

  function cancelAdd() {
    adding = false
    formError = ""
    Qt.callLater(function () { if (root.opened) keyCatcher.forceActiveFocus() })
  }

  function commitAdd() {
    var priceText = String(priceField.text || "").trim()
    var price = priceText === "" ? market.price : Model.parsePrice(priceText)
    if (!isFinite(price) || price <= 0) {
      formError = market.hasPrice ? "Informe um preço de entrada válido" : "Sem preço ao vivo — digite o preço de entrada"
      return
    }
    var size = Model.parseSizeInput(amountField.text, price, currency)
    if (size.error !== "") { formError = size.error; return }
    var parsedDate = Model.parseDateInput(dateField.text)
    if (parsedDate.error !== "") { formError = parsedDate.error; return }

    book.add(parsedDate.date, size.btc, price, currency, 0, "")
    adding = false
    formError = ""
    cursorActive = false
    Qt.callLater(function () { if (root.opened) keyCatcher.forceActiveFocus() })
  }

  // Two presses to delete. A position is a record of something that actually
  // happened, so a single keystroke should not be able to erase it.
  function requestDelete() {
    if (!selectedPosition) return
    if (pendingDeleteId === selectedPosition.id) {
      book.remove(selectedPosition.id)
      pendingDeleteId = ""
      cursorIndex = Math.max(0, Math.min(cursorIndex, positions.length - 1))
    } else {
      pendingDeleteId = selectedPosition.id
      deleteResetTimer.restart()
    }
  }

  function openHeadline() {
    if (view !== "news" || !cursorActive) return
    var item = headlines[Math.min(cursorIndex, headlines.length - 1)]
    if (item && item.link) Util.execArgv(["xdg-open", String(item.link)])
  }

  // Past a year the panel is the wrong tool: hand it over to a real charting
  // page instead of pretending a 380px canvas can do more.
  function openOnCoinGecko() {
    Util.execArgv(["xdg-open", "https://www.coingecko.com/en/coins/bitcoin"])
  }

  function openDigestInTerminal() {
    if (!bar) return
    bar.run("omarchy-launch-floating-terminal-with-presentation " + Util.shellQuote(market.cliPath + " news"))
  }

  Timer {
    id: deleteResetTimer
    interval: 4000
    onTriggered: root.pendingDeleteId = ""
  }

  Service {
    id: market
    settings: root.settings
    panelOpen: root.opened
  }

  Portfolio {
    id: book
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.openPanel() }
    function close(): void { root.close() }
    function show(): void { root.openPanel() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { market.refreshAll(true); return "ok" }
    function price(): string { return market.hasPrice ? Model.fmtMoney(market.price, root.currency) : "—" }
    function status(): string {
      if (!market.hasPrice) return "no price"
      var out = Model.fmtMoney(market.price, root.currency) + " " + Model.fmtPct(market.change24h)
      if (root.hasBook) out += " · book " + Model.fmtPct(root.totals.plPct)
      return out
    }
    function mantra(): string { market.nextPhrase(); return market.heroLine }
    function news(): void { root.openPanel(); root.setView("news") }
    function add(): void { root.openPanel(); root.startAdd() }
    function chart(range: string): string {
      var wanted = String(range || "").toUpperCase()
      for (var i = 0; i < Model.TIMEFRAMES.length; i++) {
        if (Model.TIMEFRAMES[i].key === wanted) {
          root.openPanel()
          root.setSection("chart", true)
          market.setTimeframe(i)
          // Report what the panel actually ended up on, not what was asked
          // for: the two diverging is exactly the bug worth seeing.
          return market.timeframe.key + " · " + Model.TIMEFRAMES[i].label
        }
      }
      return "unknown range — use 1D, 7D, 1M, 3M or 1Y"
    }

    function fold(section: string): string {
      var name = String(section || "").toLowerCase()
      if (name === "" || name === "all") {
        root.toggleFold()
        return root.sectionOpen("book") ? "all open" : "all folded"
      }
      if (["chart", "book", "sentiment", "network"].indexOf(name) < 0)
        return "unknown section — use chart, book, sentiment, network or all"
      root.toggleSection(name)
      return name + " " + (root.sectionOpen(name) ? "open" : "folded")
    }

    function state(): string {
      return JSON.stringify({
        open: root.opened,
        view: root.view,
        chart: root.chartVisible,
        sections: { chart: root.sectionOpen("chart"), book: root.sectionOpen("book"),
                    sentiment: root.sectionOpen("sentiment"), network: root.sectionOpen("network") },
        range: market.timeframe.key,
        rangeIndex: market.timeframeIndex,
        candles: market.candles.length,
        candlesDays: market.candlesDays,
        price: market.price,
        positions: root.positions.length
      })
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (!opened) {
    cursorActive = false
    pendingDeleteId = ""
    if (adding) cancelAdd()
  }

  // -------------------------------------------------------------- bar pill

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.bar && root.bar.vertical ? -1 : pillRow.implicitWidth + scaledHorizontalMargin * 2
    tooltipText: root.tooltip
    active: root.opened

    onPressed: function (b) {
      if (b === Qt.RightButton) market.refreshAll(true)
      else if (b === Qt.MiddleButton) root.openDigestInTerminal()
      else root.toggle()
    }
    onWheelMoved: function (delta) {
      if (!root.opened) return
      market.cycleTimeframe(delta > 0 ? -1 : 1)
    }

    // Reaching for the pill is a request to look at the price. One call, and
    // only if the last one has already gone cold.
    onTooltipHoveredChanged: if (tooltipHovered) market.refreshIfStale(45)

    Row {
      id: pillRow
      anchors.centerIn: parent
      spacing: Style.space(5)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: "₿"
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        font.bold: true
        renderType: Text.NativeRendering
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: text !== ""
        textFormat: Text.PlainText
        text: root.barPrimary
        color: root.barDisplay === "Change only" || root.barDisplay === "Profit / loss"
          ? root.tint(root.barTintValue)
          : button.foreground
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        renderType: Text.NativeRendering
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: text !== ""
        textFormat: Text.PlainText
        text: root.barSecondary
        color: root.tint(root.barTintValue)
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        renderType: Text.NativeRendering
      }
    }
  }

  // ----------------------------------------------------------------- panel

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight + footer.height + Style.space(8), Style.space(780))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.adding

      onMoveRequested: function (dx, dy) {
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) market.cycleTimeframe(dx)
      }
      onActivateRequested: root.openHeadline()
      onReturnRequested: root.view === "news" ? root.openHeadline() : root.startAdd()
      onDeleteRequested: root.requestDelete()
      onCloseRequested: root.view === "news" ? root.setView("book") : root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }
      onTextKey: function (t) {
        var key = String(t).toLowerCase()
        if (key === "a" || key === "+") root.startAdd()
        else if (key === "d") root.requestDelete()
        else if (key === "r") { market.refreshAll(true); if (root.chartVisible) market.loadCandles(true); market.refreshNews(true) }
        else if (key === "c") root.toggleSection("chart")
        else if (key === "b") root.toggleSection("book")
        else if (key === "s") root.toggleSection("sentiment")
        else if (key === "w") root.toggleSection("network")
        else if (key === "z") root.toggleFold()
        else if (key === "n") root.setView(root.view === "news" ? "book" : "news")
        else if (key === "t") root.openDigestInTerminal()
        else if (key === "m") market.nextPhrase()
        else if (key === "h") market.cycleTimeframe(-1)
        else if (key === "l") market.cycleTimeframe(1)
        else if (key === "6") root.openOnCoinGecko()
        else if (key >= "1" && key <= "5") { root.setSection("chart", true); market.setTimeframe(parseInt(key, 10) - 1) }
      }

      Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.bottomMargin: Style.space(8)
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(12)

          // ---------------------------------------------------------- hero

          Item {
            width: parent.width
            height: Math.max(heroLeft.implicitHeight, heroRight.implicitHeight)

            Row {
              id: heroLeft
              anchors.left: parent.left
              anchors.right: heroRight.left
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(10)

              Text {
                id: btcMark
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: "₿"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.displayLarge
                font.bold: true
              }

              Column {
                id: heroLabels
                width: Math.max(0, heroLeft.width - btcMark.width - Style.space(10))
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(1)

                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  textFormat: Text.PlainText
                  text: market.hasPrice ? Model.fmtMoney(market.price, root.currency) : "—"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                  font.bold: true
                }

                Row {
                  id: changesRow
                  width: parent.width
                  spacing: Style.space(8)

                  Text {
                    id: headlineChangeText
                    textFormat: Text.PlainText
                    text: market.hasPrice
                      ? Model.fmtPct(root.headlineChange) + " " + root.headlineLabel
                      : (market.loading ? "carregando…" : (market.lastError || ""))
                    color: market.hasPrice ? root.tint(root.headlineChange) : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }

                  Text {
                    visible: market.hasPrice
                    width: Math.max(0, changesRow.width - headlineChangeText.width - Style.space(8))
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: root.otherChanges
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                  }
                }
              }
            }

            Column {
              id: heroRight
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                anchors.right: parent.right
                textFormat: Text.PlainText
                visible: market.high24h > 0 || root.rangeHeader
                text: {
                  var low = root.rangeHeader ? market.rangeStats.low : market.low24h
                  var high = root.rangeHeader ? market.rangeStats.high : market.high24h
                  return root.headlineLabel + "  " + Model.fmtCompact(low, root.currency)
                    + " – " + Model.fmtCompact(high, root.currency)
                }
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              Text {
                anchors.right: parent.right
                textFormat: Text.PlainText
                visible: market.ath > 0
                text: "ATH " + Model.fmtCompact(market.ath, root.currency)
                  + "  " + Model.fmtPct(market.athChangePct, 1)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          // The line the whole plugin exists for.
          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: market.heroLine
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            wrapMode: Text.WordWrap

            TapHandler { onTapped: market.nextPhrase() }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
          }

          // --------------------------------------------------------- chart

          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: root.chartVisible && root.view === "book"

            Row {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: Model.TIMEFRAMES

                Rectangle {
                  required property var modelData
                  required property int index

                  readonly property bool selected: index === market.timeframeIndex
                  width: tfLabel.implicitWidth + Style.space(12)
                  height: Style.space(19)
                  radius: Style.cornerRadius
                  color: selected ? Style.selectedFillFor(root.foreground, root.foreground) : "transparent"

                  Text {
                    id: tfLabel
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: modelData.key
                    color: selected ? root.foreground : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: selected
                  }

                  TapHandler { onTapped: market.setTimeframe(index) }
                  HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
              }

              // Beyond 1Y, or for anything this chart cannot show.
              Rectangle {
                id: moreChip
                width: moreIcon.implicitWidth + Style.space(12)
                height: Style.space(19)
                radius: Style.cornerRadius
                color: moreHover.hovered ? Style.hoverFillFor(root.foreground, root.foreground) : "transparent"

                Text {
                  id: moreIcon
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: "\uf08e"  // nf-fa-external_link
                  color: moreHover.hovered ? root.foreground : root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                HoverHandler { id: moreHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.openOnCoinGecko() }
              }

              Item { width: Style.space(4); height: 1 }

              Spinner {
                anchors.verticalCenter: parent.verticalCenter
                active: market.candlesLoading
                color: root.dim
                font.family: root.fontFamily
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                // Errors wait for the fetch to finish; a stale message next to
                // a live spinner reads as the new attempt having failed.
                text: market.candlesLoading || market.candlesError === "" ? "" : market.candlesError
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            CandleChart {
              id: chart
              width: parent.width
              height: Style.space(112)
              // Dimmed only while the candles on screen are the *previous*
              // range — a plain refresh of the range you are looking at
              // leaves the chart at full strength.
              opacity: market.candlesDays !== market.timeframe.days && market.candles.length > 0 ? 0.4 : 1

              Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
              }
              candles: market.candles
              breakEven: root.hasBook ? root.totals.avgPrice : 0
              currency: root.currency
              foreground: root.foreground
              upColor: root.upColor
              downColor: root.downColor
              fontFamily: root.fontFamily
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              visible: root.hasBook
              text: {
                var be = Model.fmtMoney(root.totals.avgPrice, root.currency)
                if (chart.breakEvenVisible) return "preço médio " + be + "  (tracejado)"
                return "preço médio " + be + "  " + (chart.breakEvenBelow ? "↓" : "↑") + " fora do gráfico"
              }
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          // ---------------------------------------------------------- book

          PanelSeparator { foreground: root.foreground; visible: root.view === "book" }

          Column {
            width: parent.width
            spacing: Style.space(8)
            visible: root.view === "book"

            SectionHeader {
              text: root.hasBook ? "Sua carteira · " + Model.fmtBtc(root.totals.btc) + " BTC" : "Sua carteira"
              open: root.sectionOpen("book")
              summary: root.hasBook
                ? Model.fmtMoneySigned(root.totals.pl, root.currency, 0) + "  " + Model.fmtPct(root.totals.plPct, 1)
                : ""
              summaryColor: root.tint(root.totals.pl)
              foreground: root.foreground
              fontFamily: root.fontFamily
              onToggled: root.toggleSection("book")
            }

            Column {
              width: parent.width
              spacing: Style.space(8)
              visible: root.sectionOpen("book")


              // Totals, the eToro-style summary line: what it cost, what it is
              // worth now, and the number that decides your mood.
              Item {
                width: parent.width
                height: Math.max(totalsLeft.implicitHeight, totalsRight.implicitHeight)
                visible: root.hasBook

                Column {
                  id: totalsLeft
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(1)

                  Text {
                    textFormat: Text.PlainText
                    text: Model.fmtMoney(root.totals.value, root.currency)
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.heading
                    font.bold: true
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: "custo " + Model.fmtMoney(root.totals.cost, root.currency)
                      + " · média " + Model.fmtMoney(root.totals.avgPrice, root.currency)
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Column {
                  id: totalsRight
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(1)

                  Text {
                    anchors.right: parent.right
                    textFormat: Text.PlainText
                    text: Model.fmtMoneySigned(root.totals.pl, root.currency)
                    color: root.tint(root.totals.pl)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.heading
                    font.bold: true
                  }

                  Text {
                    anchors.right: parent.right
                    textFormat: Text.PlainText
                    text: Model.fmtPct(root.totals.plPct)
                    color: root.tint(root.totals.pl)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }
              }

              // Positions keep the currency they were bought in. Switching the
              // widget to another one would otherwise add euros to dollars in
              // total silence.
              Text {
                width: parent.width
                textFormat: Text.PlainText
                visible: root.hasBook && Model.hasForeignPositions(root.positions, root.currency)
                text: "Moedas mistas nesta carteira — o total as soma como se fossem uma só."
                color: root.downColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              Text {
                width: parent.width
                textFormat: Text.PlainText
                visible: root.hasBook
                text: Mantras.positionLine(root.totals.plPct, market.phraseSeed)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              // Empty state
              Text {
                width: parent.width
                visible: !root.hasBook && book.loaded
                textFormat: Text.PlainText
                text: "Nenhuma posição ainda.\nPressione a para registrar sua primeira compra — ou rode: hodl add 0.01 62000 2025-03-14"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }

              // Column headers
              Row {
                width: parent.width
                visible: root.hasBook
                spacing: 0

                Text {
                  width: parent.width * 0.19
                  textFormat: Text.PlainText
                  text: "DATA"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
                Text {
                  width: parent.width * 0.22
                  textFormat: Text.PlainText
                  text: "QUANTIDADE"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
                Text {
                  width: parent.width * 0.21
                  textFormat: Text.PlainText
                  text: "ENTRADA"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
                Text {
                  width: parent.width * 0.20
                  horizontalAlignment: Text.AlignRight
                  textFormat: Text.PlainText
                  text: "P/L"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
                Text {
                  width: parent.width * 0.18
                  horizontalAlignment: Text.AlignRight
                  textFormat: Text.PlainText
                  text: "%"
                  color: root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
              }

              Repeater {
                model: root.positions

                Rectangle {
                  id: row
                  required property var modelData
                  required property int index

                  readonly property var metrics: Model.positionMetrics(modelData, market.price)
                  readonly property bool hasCursor: root.cursorActive && root.view === "book" && index === root.cursorIndex
                  readonly property bool pendingDelete: root.pendingDeleteId === modelData.id

                  width: parent.width
                  height: Style.space(24)
                  radius: Style.cornerRadius
                  color: pendingDelete
                    ? Qt.rgba(root.downColor.r, root.downColor.g, root.downColor.b, 0.18)
                    : (hasCursor || rowHover.hovered ? Style.hoverFillFor(root.foreground, root.foreground) : "transparent")

                  HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      root.cursorActive = true
                      root.view = "book"
                      root.cursorIndex = row.index
                      root.pendingDeleteId = ""
                    }
                  }

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(4)
                    anchors.rightMargin: Style.space(4)
                    spacing: 0

                    Text {
                      width: (parent.width) * 0.19
                      anchors.verticalCenter: parent.verticalCenter
                      textFormat: Text.PlainText
                      text: Model.fmtDate(row.modelData.date)
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      elide: Text.ElideRight
                    }
                    Text {
                      width: (parent.width) * 0.22
                      anchors.verticalCenter: parent.verticalCenter
                      textFormat: Text.PlainText
                      text: Model.fmtBtc(row.modelData.amount)
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      elide: Text.ElideRight
                    }
                    Text {
                      width: (parent.width) * 0.21
                      anchors.verticalCenter: parent.verticalCenter
                      textFormat: Text.PlainText
                      text: Model.fmtMoney(row.modelData.price, row.modelData.currency || root.currency)
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      elide: Text.ElideRight
                    }
                    Text {
                      width: (parent.width) * 0.20
                      anchors.verticalCenter: parent.verticalCenter
                      horizontalAlignment: Text.AlignRight
                      textFormat: Text.PlainText
                      text: Model.fmtMoneySigned(row.metrics.pl, root.currency, 0)
                      color: root.tint(row.metrics.pl)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                    }
                    Text {
                      width: (parent.width) * 0.18
                      anchors.verticalCenter: parent.verticalCenter
                      horizontalAlignment: Text.AlignRight
                      textFormat: Text.PlainText
                      text: Model.fmtPct(row.metrics.plPct, 1)
                      color: root.tint(row.metrics.pl)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                    }
                  }
                }
              }

              // Cursor detail: held-for and cost, plus the delete confirmation.
              Text {
                width: parent.width
                visible: root.selectedPosition !== null
                textFormat: Text.PlainText
                text: {
                  if (!root.selectedPosition) return ""
                  var m = Model.positionMetrics(root.selectedPosition, market.price)
                  if (root.pendingDeleteId === root.selectedPosition.id)
                    return "Pressione d novamente para remover esta posição"
                  return "há " + Model.fmtDuration(m.days) + " · custo " + Model.fmtMoney(m.cost, root.currency)
                    + " · agora " + Model.fmtMoney(m.value, root.currency)
                    + " · " + Model.fmtSats(root.selectedPosition.amount)
                }
                color: root.pendingDeleteId !== "" ? root.downColor : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              // ------------------------------------------------------ add form

              Column {
                width: parent.width
                spacing: Style.space(6)
                visible: root.adding

                PanelSectionHeader {
                  text: "Nova posição"
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                }

                Row {
                  width: parent.width
                  spacing: Style.space(6)

                  TextField {
                    id: amountField
                    width: (parent.width - Style.space(12)) * 0.34
                    placeholderText: "0.025"
                    foreground: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    Keys.onReturnPressed: function (event) { event.accepted = true; root.commitAdd() }
                    Keys.onEnterPressed: function (event) { event.accepted = true; root.commitAdd() }
                    Keys.onEscapePressed: root.cancelAdd()
                    KeyNavigation.tab: priceField
                  }
                  TextField {
                    id: priceField
                    width: (parent.width - Style.space(12)) * 0.33
                    placeholderText: market.hasPrice ? Model.fmtNumber(market.price, 0) : "preço de entrada"
                    foreground: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    Keys.onReturnPressed: function (event) { event.accepted = true; root.commitAdd() }
                    Keys.onEnterPressed: function (event) { event.accepted = true; root.commitAdd() }
                    Keys.onEscapePressed: root.cancelAdd()
                    KeyNavigation.tab: dateField
                  }
                  TextField {
                    id: dateField
                    width: (parent.width - Style.space(12)) * 0.33
                    placeholderText: "YYYY-MM-DD"
                    foreground: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    Keys.onReturnPressed: function (event) { event.accepted = true; root.commitAdd() }
                    Keys.onEnterPressed: function (event) { event.accepted = true; root.commitAdd() }
                    Keys.onEscapePressed: root.cancelAdd()
                    KeyNavigation.tab: amountField
                  }
                }

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: root.formError !== ""
                    ? root.formError
                    : "quantidade · preço de entrada (vazio = mercado) · data. Aceita também 250k sats ou "
                      + Model.currencySymbol(root.currency) + "500. Enter para salvar, Esc para cancelar."
                  color: root.formError !== "" ? root.downColor : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
              }
            }
          }

          // ----------------------------------------------------- sentiment

          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: root.view === "book" && market.fngValue >= 0

            PanelSeparator { foreground: root.foreground }

            SectionHeader {
              text: "Medo e ganância"
              open: root.sectionOpen("sentiment")
              summary: market.fngValue + " · " + market.fngLabelDisplay
              summaryColor: root.dim
              foreground: root.foreground
              fontFamily: root.fontFamily
              onToggled: root.toggleSection("sentiment")
            }

            Column {
              width: parent.width
              spacing: Style.space(6)
              visible: root.sectionOpen("sentiment")


              Item {
                width: parent.width
                height: Style.space(22)

                // Fear on the left, greed on the right — the standard reading.
                // The marker is the value; the gradient is only there to make
                // "which half am I in" legible without reading the number.
                Rectangle {
                  id: gauge
                  anchors.left: parent.left
                  anchors.right: valueLabel.left
                  anchors.rightMargin: Style.space(10)
                  anchors.verticalCenter: parent.verticalCenter
                  height: Style.space(5)
                  radius: height / 2
                  gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(root.downColor.r, root.downColor.g, root.downColor.b, 0.85) }
                    GradientStop { position: 0.5; color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.30) }
                    GradientStop { position: 1.0; color: Qt.rgba(root.upColor.r, root.upColor.g, root.upColor.b, 0.85) }
                  }

                  Rectangle {
                    width: Style.space(3)
                    height: Style.space(13)
                    radius: width / 2
                    color: root.foreground
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * (market.fngValue / 100) - width / 2))
                  }
                }

                Text {
                  id: valueLabel
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  textFormat: Text.PlainText
                  text: market.fngValue + " · " + market.fngLabelDisplay
                    + (market.fngYesterday >= 0
                       ? "  (" + (market.fngValue - market.fngYesterday >= 0 ? "+" : "")
                         + (market.fngValue - market.fngYesterday) + ")"
                       : "")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                }
              }

              // The index is published once a day; without this the same 69
              // sitting there for hours reads as a number that is stuck.
              Text {
                width: parent.width
                textFormat: Text.PlainText
                visible: market.fngPublishedAt > 0
                text: {
                  var age = Date.now() / 1000 - market.fngPublishedAt
                  var out = "publicado há " + Model.fmtSpan(age)
                  if (market.fngNextUpdate > 0) out += " · próximo em " + Model.fmtSpan(market.fngNextUpdate)
                  return out + " · verificado a cada hora"
                }
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: market.sentimentLine
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }

          // ------------------------------------------------------- network

          Column {
            width: parent.width
            spacing: Style.space(4)
            visible: root.view === "book" && market.blockHeight > 0

            PanelSeparator { foreground: root.foreground }

            SectionHeader {
              text: "Rede"
              open: root.sectionOpen("network")
              summary: "bloco " + Model.fmtNumber(market.blockHeight, 0)
              summaryColor: root.dim
              foreground: root.foreground
              fontFamily: root.fontFamily
              onToggled: root.toggleSection("network")
            }

            Column {
              width: parent.width
              spacing: Style.space(4)
              visible: root.sectionOpen("network")


              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: {
                  var bits = ["bloco " + Model.fmtNumber(market.blockHeight, 0)]
                  if (market.network.feeFast) bits.push(market.network.feeFast + " sat/vB")
                  if (market.network.hashrate) bits.push(Model.fmtHashrate(market.network.hashrate))
                  if (market.network.difficultyChange !== undefined && market.network.difficultyChange !== null)
                    bits.push("dificuldade " + Model.fmtPct(market.network.difficultyChange, 1))
                  return bits.join("  ·  ")
                }
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              Text {
                width: parent.width
                visible: market.halving !== null
                textFormat: Text.PlainText
                text: market.halving
                  ? "halving em " + Model.fmtNumber(market.halving.blocksLeft, 0) + " blocos (~"
                    + Model.fmtNumber(market.halving.days, 0) + " dias) · subsídio "
                    + market.halving.subsidy + " BTC"
                  : ""
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }

          // -------------------------------------------------------- digest

          Column {
            width: parent.width
            spacing: Style.space(8)
            visible: root.view === "news"

            PanelSeparator { foreground: root.foreground }

            Row {
              width: parent.width
              spacing: Style.space(6)

              PanelSectionHeader {
                text: market.newsletter
                  ? "O que aconteceu · " + market.newsletter.date
                  : (market.newsLoading ? "Buscando notícias…" : "Resumo diário")
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Spinner {
                anchors.verticalCenter: parent.verticalCenter
                active: market.newsLoading
                color: root.dim
                font.family: root.fontFamily
              }
            }

            Text {
              width: parent.width
              visible: root.headlines.length === 0
              textFormat: Text.PlainText
              text: market.newsLoading ? "Lendo a imprensa bitcoin…" : "Sem manchetes agora. Pressione r para tentar de novo."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Repeater {
              model: root.headlines

              Rectangle {
                id: newsRow
                required property var modelData
                required property int index

                readonly property bool hasCursor: root.cursorActive && root.view === "news" && index === root.cursorIndex

                width: parent.width
                height: Math.max(newsText.implicitHeight, thumb.height) + Style.space(10)
                radius: Style.cornerRadius
                color: hasCursor || newsHover.hovered
                  ? Style.hoverFillFor(root.foreground, root.foreground)
                  : "transparent"

                HoverHandler { id: newsHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  onTapped: {
                    root.cursorActive = true
                    root.cursorIndex = newsRow.index
                    root.openHeadline()
                  }
                }

                // Always drawn, so the list keeps one rhythm. Plenty of feed
                // items ship no artwork at all; those get the mark rather
                // than a hole where every other row has a picture.
                Rectangle {
                  id: thumb
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(52)
                  height: Style.space(38)
                  radius: Style.cornerRadius
                  clip: true
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)

                  Text {
                    anchors.centerIn: parent
                    visible: thumbImage.status !== Image.Ready
                    textFormat: Text.PlainText
                    text: "\u20bf"
                    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.32)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.heading
                    font.bold: true
                  }

                  Image {
                    id: thumbImage
                    visible: status === Image.Ready
                    anchors.fill: parent
                    source: newsRow.modelData.imageFile
                      ? Util.fileUrl(String(newsRow.modelData.imageFile))
                      : ""
                    fillMode: Image.PreserveAspectCrop
                    // Decode at roughly twice the drawn size and no more.
                    sourceSize.width: Style.space(120)
                    asynchronous: true
                    cache: true
                  }
                }

                Column {
                  id: newsText
                  anchors.left: thumb.right
                  anchors.right: parent.right
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(1)

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: newsRow.modelData.title
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: String(newsRow.modelData.source || "")
                    color: root.faint
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }

            Text {
              width: parent.width
              visible: market.newsletter !== null
              textFormat: Text.PlainText
              text: market.newsletter ? market.newsletter.mantra : ""
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              wrapMode: Text.WordWrap
            }
          }

        }
      }

      // The key hints stay pinned under the scroll area: they are the only
      // affordance for everything the mouse cannot reach, so scrolling the
      // book must not scroll them away.
      Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: hints.implicitHeight + Style.space(10)

        PanelSeparator {
          anchors.top: parent.top
          width: parent.width
          foreground: root.foreground
        }

        Text {
          id: hints
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          width: parent.width - stamp.width - Style.space(8)
          textFormat: Text.PlainText
          text: root.view === "news"
            ? "enter abrir · n carteira · t terminal · r sync"
            : "a adicionar · d excluir · c gráfico · z recolher · 1-6 período · n notícias"
          color: root.faint
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        // Last update, with the global activity mark pinned to its left. The
        // time stays readable the whole way through a refresh; the spinner is
        // the only thing that changes.
        Row {
          id: stamp
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          spacing: Style.space(5)

          Spinner {
            anchors.baseline: stampText.baseline
            active: market.busy
            color: root.faint
            font.family: root.fontFamily
          }

          Text {
            id: stampText
            textFormat: Text.PlainText
            text: market.marketAt > 0
              ? Qt.formatDateTime(new Date(market.marketAt * 1000), "HH:mm")
              : ""
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
