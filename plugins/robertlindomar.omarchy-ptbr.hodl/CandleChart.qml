import QtQuick
import qs.Commons
import "Model.js" as Model

// Candlesticks, drawn small on purpose. The only line added to the price is
// your break-even: on a chart of your own money, the question is not where
// the market has been but which side of your cost basis it is on.
Canvas {
  id: root

  property var candles: []
  property real breakEven: 0
  property string currency: "usd"
  property color foreground: Color.foreground
  property color upColor: "#3fb950"
  property color downColor: "#f85149"
  property string fontFamily: Style.font.family
  property int labelSize: Style.font.caption
  property real gutter: Style.space(52)

  // Candle-only bounds first. A break-even far from the current price would
  // otherwise squash a week of trading into a two-pixel ribbon at the top of
  // the chart, which is the opposite of what the line is for — so it only
  // stretches the scale when it is close enough to sit inside it.
  readonly property var priceBounds: Model.candleBounds(candles || [])
  readonly property bool breakEvenNear: breakEven > 0
    && breakEven > priceBounds.min - (priceBounds.max - priceBounds.min) * 0.25
    && breakEven < priceBounds.max + (priceBounds.max - priceBounds.min) * 0.25
  readonly property var bounds: breakEvenNear
    ? Model.candleBounds(candles || [], [breakEven])
    : priceBounds

  // Read by the caller so the caption under the chart can say where an
  // off-scale break-even actually is.
  readonly property bool breakEvenVisible: breakEvenNear
  readonly property bool breakEvenBelow: breakEven > 0 && breakEven <= priceBounds.min

  onCandlesChanged: requestPaint()
  onBreakEvenChanged: requestPaint()
  onBreakEvenNearChanged: requestPaint()
  onForegroundChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.clearRect(0, 0, width, height)

    var rows = candles || []
    if (rows.length === 0) return

    var plotW = Math.max(10, width - gutter)
    var plotH = height
    var min = bounds.min
    var max = bounds.max
    var span = Math.max(1e-9, max - min)
    var yFor = function (value) { return plotH - ((value - min) / span) * plotH }

    var slot = plotW / rows.length
    var body = Math.max(1, Math.min(Style.space(9), slot * 0.62))
    var wick = Math.max(1, Math.round(body * 0.16))

    // Horizontal guides at the extremes and the midpoint. Three lines is
    // enough to read a level off; more turns a 120px chart into graph paper.
    ctx.strokeStyle = Qt.rgba(foreground.r, foreground.g, foreground.b, 0.10)
    ctx.lineWidth = 1
    for (var g = 0; g <= 2; g++) {
      var gy = Math.round(yFor(min + span * (g / 2))) + 0.5
      ctx.beginPath()
      ctx.moveTo(0, gy)
      ctx.lineTo(plotW, gy)
      ctx.stroke()
    }

    for (var i = 0; i < rows.length; i++) {
      var c = rows[i]
      var cx = i * slot + slot / 2
      var rising = c.c >= c.o
      var color = rising ? upColor : downColor
      ctx.strokeStyle = color
      ctx.fillStyle = color

      ctx.lineWidth = wick
      ctx.beginPath()
      ctx.moveTo(Math.round(cx) + 0.5, yFor(c.h))
      ctx.lineTo(Math.round(cx) + 0.5, yFor(c.l))
      ctx.stroke()

      var top = yFor(Math.max(c.o, c.c))
      var bottom = yFor(Math.min(c.o, c.c))
      // A doji still needs a mark, so an empty body is drawn one pixel tall.
      ctx.fillRect(Math.round(cx - body / 2), Math.round(top), Math.round(body), Math.max(1, Math.round(bottom - top)))
    }

    ctx.font = labelSize + "px \"" + fontFamily + "\""
    ctx.textBaseline = "middle"

    var breakEvenY = -1
    if (breakEvenNear && breakEven >= min && breakEven <= max) {
      var by = Math.round(yFor(breakEven)) + 0.5
      ctx.strokeStyle = Qt.rgba(foreground.r, foreground.g, foreground.b, 0.55)
      ctx.lineWidth = 1
      ctx.beginPath()
      // Dashed by hand: setLineDash is not available on every Qt Quick
      // canvas backend, and a manual dash costs nothing at this width.
      for (var x = 0; x < plotW; x += 6) {
        ctx.moveTo(x, by)
        ctx.lineTo(Math.min(plotW, x + 3), by)
      }
      ctx.stroke()
      ctx.fillStyle = Qt.rgba(foreground.r, foreground.g, foreground.b, 0.75)
      ctx.textAlign = "left"
      // Text on a half-pixel baseline renders smeared on a fractional-scale
      // display, so the label rounds even though the rule it annotates does
      // not.
      breakEvenY = Math.round(by)
      ctx.fillText(Model.fmtCompact(breakEven, currency), plotW + Style.space(5), breakEvenY)
    }

    // The scale labels give way to the break-even label when they would
    // collide: two prices printed on top of each other read as neither.
    var clear = function (y) { return breakEvenY < 0 || Math.abs(y - breakEvenY) > labelSize * 1.6 }
    var maxY = Math.round(labelSize * 0.75)
    var minY = Math.round(plotH - labelSize * 0.75)
    ctx.fillStyle = Qt.rgba(foreground.r, foreground.g, foreground.b, 0.45)
    ctx.textAlign = "left"
    if (clear(maxY)) ctx.fillText(Model.fmtCompact(max, currency), plotW + Style.space(5), maxY)
    if (clear(minY)) ctx.fillText(Model.fmtCompact(min, currency), plotW + Style.space(5), minY)
  }
}
