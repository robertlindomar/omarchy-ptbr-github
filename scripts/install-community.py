#!/usr/bin/env python3
"""Instala traduções comunitárias; preserva layout, estado e atalhos existentes."""
import argparse
import copy
from datetime import datetime, timezone
import difflib
import json
import os
from pathlib import Path
import shutil
import subprocess

from importlib.util import spec_from_file_location, module_from_spec
spec = spec_from_file_location('native', Path(__file__).with_name('migrate-native.py'))
native = module_from_spec(spec)
spec.loader.exec_module(native)

COMMUNITY = ('omaclock', 'notification-center', 'app-launcher', 'hyprmoncfg', 'plugin-manager', 'hodl', 'launcher-plus')


def transform(config, mapping):
    result = copy.deepcopy(config)
    def entries(items):
        mapped = []
        positions = {}
        originals = set()
        for entry in items:
            original = entry.get('id') if isinstance(entry, dict) else entry
            target = mapping.get(original, original)
            value = dict(entry, id=target) if isinstance(entry, dict) else target
            if target not in positions:
                positions[target] = len(mapped)
                mapped.append(value)
                if original in mapping:
                    originals.add(target)
            else:
                index = positions[target]
                previous = mapped[index]
                if isinstance(previous, dict) and isinstance(value, dict):
                    # A configuração explícita do clone prevalece sobre a original.
                    mapped[index] = dict(previous, **value) if original not in mapping or target in originals else dict(value, **previous)
                if original not in mapping:
                    originals.discard(target)
        return mapped
    bar = result.get('bar', {})
    for section, items in bar.get('layout', {}).items():
        bar['layout'][section] = entries(items)
    if 'plugins' in result:
        result['plugins'] = entries(result['plugins'])
    if 'centerAnchor' in bar:
        bar['centerAnchor'] = mapping.get(bar['centerAnchor'], bar['centerAnchor'])
    if 'centerAnchor' in result:
        result['centerAnchor'] = mapping.get(result['centerAnchor'], result['centerAnchor'])
    disabled = result.get('disabledPlugins', [])
    result['disabledPlugins'] = [item for item in disabled if item not in mapping.values()]
    for original in mapping:
        if original not in result['disabledPlugins']:
            result['disabledPlugins'].append(original)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--config-dir', type=Path, default=Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home()/'.config'))) / 'omarchy')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    plugins = args.config_dir/'plugins'
    shell = args.config_dir/'shell.json'
    config = json.loads(shell.read_text())
    mapping = {}
    sources = []
    for suffix in COMMUNITY:
        source = root/'plugins'/('robertlindomar.omarchy-ptbr.'+suffix)
        manifest = json.loads((source/'manifest.json').read_text())
        subprocess.run(['omarchy', 'plugin', 'validate', str(source)], check=True, stdout=subprocess.DEVNULL)
        original = manifest.get('omarchy', {}).get('clonedFrom')
        if original:
            mapping[original] = manifest['id']
        sources.append(source)
    updated = transform(config, mapping)
    text = json.dumps(updated, ensure_ascii=False, indent=2)+'\n'
    before = shell.read_text()
    print(''.join(difflib.unified_diff(before.splitlines(True), text.splitlines(True), fromfile=str(shell), tofile='proposto')), end='')
    # IDs públicos nos atalhos são redirecionados; as demais linhas são preservadas.
    bindings = args.config_dir.parent/'hypr/bindings.lua'
    old_bindings = bindings.read_text() if bindings.exists() else ''
    new_bindings = old_bindings
    for original, clone in mapping.items():
        new_bindings = new_bindings.replace('shell toggle '+original+' ', 'shell toggle '+clone+' ').replace('shell summon '+original+' ', 'shell summon '+clone+' ')
    print('Plugins comunitários: '+', '.join(p.name for p in sources))
    if new_bindings != old_bindings:
        print('Atualizar IDs dos plugins nos atalhos existentes de bindings.lua')
    if not args.apply:
        print('Simulação: nenhum arquivo alterado.')
        return
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
    state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state')))/'omarchy-ptbr/backups'/('native-'+stamp)
    state.mkdir(parents=True)
    shutil.copy2(shell, state/'shell.json')
    if bindings.exists():
        shutil.copy2(bindings, state/'bindings.lua')
    plugins.mkdir(parents=True, exist_ok=True)
    for source in sources:
        dest = plugins/source.name
        if dest.exists():
            shutil.copytree(dest, state/dest.name, symlinks=True)
        # rsync remove arquivos obsoletos somente no clone já copiado no backup.
        subprocess.run(['rsync','-a','--delete',str(source)+'/',str(dest)+'/'], check=True)
    if updated != config:
        native.atomic_write(shell, text)
    if new_bindings != old_bindings:
        native.atomic_write(bindings, new_bindings)
    print('Aplicado. Backup: '+str(state))


if __name__ == '__main__':
    main()
