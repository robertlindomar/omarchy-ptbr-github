#!/usr/bin/env python3
"""Exercise legacy and Omarchy 4.5 storage with isolated synthetic fixtures."""
import hashlib
import json
import os
import select
import signal
from pathlib import Path
import subprocess
import tempfile
import time

SCRIPT = Path(__file__).resolve().parents[1] / 'bin/notification-center'

with tempfile.TemporaryDirectory(prefix='notification-center-test-') as temporary:
    root = Path(temporary)
    source = root / 'source'
    source.mkdir()
    (source / 'history').mkdir()
    store = root / 'archive'
    env = dict(os.environ, NC_SRC_DIR=str(source), NC_STORE=str(store), NC_PREVIEWS='0')
    now = int(time.time() * 1000)
    legacy = str(now - 3000) + '-legacy'
    (source / 'history' / (legacy + '.json')).write_text(json.dumps({
        'summary': 'Legado', 'body': '<b>literal</b>', 'timestamp': now - 3000,
    }))
    key1, key2 = str(now - 2000) + '-native', str(now - 1000) + '-second'
    rows = [
        {'key': key2, 'ts': (now - 1000) / 1000, 'summary': 'Segundo'},
        {'key': key1, 'ts': (now - 2000) / 1000, 'summary': 'Novo',
         'execArgv': json.dumps(['touch', str(root / 'SHOULD_NOT_EXIST')]),
         'exec': 'touch ' + str(root / 'SHOULD_NOT_EXIST')},
        {'key': '../../unsafe', 'ts': now / 1000, 'summary': 'Rejeitar'},
        {'key': 'transient-row', 'ts': now / 1000, 'transient': True},
    ]
    (source / 'live.json').write_text(json.dumps(rows))
    (source / 'history.json').write_text(json.dumps(rows[:2]))
    (source / 'quiet.json').write_text('{"dnd": true}')
    before = {p: hashlib.sha256(p.read_bytes()).digest() for p in source.rglob('*.json')}

    def call(*args):
        return json.loads(subprocess.check_output(['bash', str(SCRIPT), *args], env=env, text=True))

    call('sync')
    entries = call('list')
    assert [r['key'] for r in entries] == [key2, key1, legacy], entries
    assert entries[1]['timestamp'] == now - 2000
    assert all('exec' not in r and 'execArgv' not in r for r in entries)
    assert not (root / 'SHOULD_NOT_EXIST').exists()
    call('sync')
    assert call('list') == entries, 'sync must not duplicate array rows'
    call('remove', key1)
    call('sync')
    assert [r['key'] for r in call('list')] == [key2, legacy]
    call('clear')
    call('sync')
    assert call('list') == [], 'cleared rows must stay cleared'
    assert all(p.exists() and hashlib.sha256(p.read_bytes()).digest() == digest for p, digest in before.items()), 'source storage must never be modified'
    (source / 'live.json').write_text('[not valid JSON')
    call('sync')
    assert call('list') == [], 'partial array must be ignored'
    # Exercise the long-running path: an atomic replacement must be seen,
    # not only a one-shot sync. No real notification or personal store used.
    watcher = subprocess.Popen(['bash', str(SCRIPT), 'watch'], env=env,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, start_new_session=True)
    try:
        time.sleep(0.3)
        watch_key = str(int(time.time() * 1000)) + '-watch'
        staged = source / 'incoming.tmp'
        staged.write_text(json.dumps([{'key': watch_key, 'ts': time.time(), 'summary': 'Watcher'}]))
        staged.replace(source / 'live.json')
        ready, _, _ = select.select([watcher.stdout], [], [], 5)
        assert ready, 'watch did not report atomic array replacement'
        reported = json.loads(watcher.stdout.readline())
        assert reported['key'] == watch_key, reported
        assert call('list')[0]['key'] == watch_key
    finally:
        os.killpg(watcher.pid, signal.SIGTERM)
        watcher.communicate(timeout=5)
print('OK: legacy + arrays, ordering, dedupe, actions discarded, dismiss/clear, read-only sources, malformed JSON, atomic watcher updates')
