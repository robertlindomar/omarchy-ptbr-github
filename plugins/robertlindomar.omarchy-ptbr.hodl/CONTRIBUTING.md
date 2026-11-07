# Contributing

Bug reports and patches are welcome.

## Running the tests

The pure logic — price parsing, portfolio maths, candle merging, the phrase
bank — has no QML or network in it and runs under plain Node:

```bash
node tests/model.test.mjs
```

Anything that touches money (`parsePrice`, `parseSizeInput`, `portfolioTotals`)
needs a test in that file before it changes. A rounding bug here is somebody's
cost basis.

## Working on the QML

```bash
omarchy plugin add https://github.com/alvaroeds/omarchy-hodl.git --enable --yes
```

Saving a file under `~/.config/omarchy/plugins/` hot-reloads the panel.
**Adding or renaming an IPC method needs a full `omarchy restart shell`** — a
hot reload keeps the previously registered handler, and the new method answers
"Function not found" until the shell restarts.

Useful while developing:

```bash
omarchy-shell hodl state          # panel state as JSON
hodl fetch --sources market       # what the panel sees, without the panel
quickshell log -i <instance> -t 50
```

## House style

Match the surrounding code: comments explain *why* a line exists, not what it
does. The shell never makes a network request — `bin/hodl` owns every fetch and
every cache, and the panel only ever reads what it produced.
