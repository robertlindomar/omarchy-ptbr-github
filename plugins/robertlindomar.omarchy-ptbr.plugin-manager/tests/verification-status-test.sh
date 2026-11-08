#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
PAGE="$ROOT/panel/updates/Page.qml"
PANEL="$ROOT/Panel.qml"

assert_contains() {
  local needle="$1"
  local file="$2"
  grep -Fq -- "$needle" "$file" || {
    printf 'FAIL: missing %q in %s\n' "$needle" "$file" >&2
    exit 1
  }
}

assert_contains 'required property var marketplaceMap' "$PAGE"
assert_contains 'required property bool marketplaceFetchFailed' "$PAGE"
assert_contains 'function verificationText(id)' "$PAGE"
assert_contains 'page.verificationText(updateRow.modelData.id)' "$PAGE"
assert_contains 'marketplaceMap: root.marketplaceMap' "$PANEL"
assert_contains 'marketplaceFetching: root.marketplaceFetching' "$PANEL"
assert_contains 'marketplaceFetchFailed: root.marketplaceFetchFailed' "$PANEL"
assert_contains 'Qt.resolvedUrl("bin/fetch-catalog")' "$PANEL"

# Exercise the helper offline: bound the full response and emit badge fields only.
python3 - "$ROOT/bin/fetch-catalog" <<'PYTEST'
import contextlib
import io
import json
import runpy
import sys
from unittest.mock import patch

helper = runpy.run_path(sys.argv[1])
main = helper['main']
compact = helper['compact']
limit = helper['LIMIT']
assert limit == 32 * 1024 * 1024
catalog = {'plugins': [{'id': 'sample', 'verificationStatus': 'verified',
                       'description': 'not sent to QML',
                       'verificationCommit': 'a' * 300,
                       'repositoryRelease': {'url': 'https://github.com/owner/repo'}}]}
row = compact(catalog)['plugins'][0]
assert row['id'] == 'sample' and row['verificationStatus'] == 'verified'
assert 'description' not in row and len(row['verificationCommit']) == 256
assert 'repositoryRelease' not in compact({'plugins': [{'id': 'x', 'repositoryRelease': {'url': 'http://untrusted'}}]})['plugins'][0]

class Response:
    def __init__(self, raw):
        self.raw = raw
    def __enter__(self):
        return self
    def __exit__(self, *args):
        pass
    def read(self, size):
        assert size == limit + 1
        return self.raw

output = io.StringIO()
with patch('urllib.request.urlopen', return_value=Response(json.dumps(catalog).encode())) as fetch, patch('signal.alarm'), contextlib.redirect_stdout(output):
    assert main() == 0
    fetch.assert_called_once_with('https://plugins.omarchy.org/catalog.json', timeout=20)
assert json.loads(output.getvalue()) == compact(catalog)
with patch('urllib.request.urlopen', return_value=Response(b'x' * (limit + 1))), patch('signal.alarm'), contextlib.redirect_stderr(io.StringIO()):
    assert main() == 1
print('catalog-helper: ok')
PYTEST

printf 'verification-status-test: ok\n'
