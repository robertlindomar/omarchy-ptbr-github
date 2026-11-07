#!/usr/bin/env python3
"""Migração opt-in para i18n nativo; sem --apply, apenas mostra diferenças."""
import argparse
import copy
from datetime import datetime, timezone
import difflib
import json
import os
from pathlib import Path
import shutil
import tempfile

SIMPLE = 'clock indicators audio bluetooth network power weather monitor speedtest disk-speedtest reminders'.split()
PREFIX = 'robertlindomar.omarchy-ptbr.'


def migrate(config, names):
    result = copy.deepcopy(config)
    mapping = {PREFIX + name: 'omarchy.' + name for name in names}

    def entries(items):
        if not isinstance(items, list):
            raise ValueError('plugins e seções de bar.layout devem ser listas')
        for index, item in enumerate(items):
            if isinstance(item, str):
                items[index] = mapping.get(item, item)
            elif isinstance(item, dict) and isinstance(item.get('id'), str):
                item['id'] = mapping.get(item['id'], item['id'])

    if 'plugins' in result:
        entries(result['plugins'])
    bar = result.get('bar', {})
    for items in bar.get('layout', {}).values():
        entries(items)
    if isinstance(bar.get('centerAnchor'), str):
        bar['centerAnchor'] = mapping.get(bar['centerAnchor'], bar['centerAnchor'])
    if isinstance(result.get('centerAnchor'), str):
        result['centerAnchor'] = mapping.get(result['centerAnchor'], result['centerAnchor'])
    if names:
        disabled = result.get('disabledPlugins', [])
        restores = result.get('cloneSourceRestores', [])
        if not isinstance(disabled, list) or not isinstance(restores, list):
            raise ValueError('disabledPlugins e cloneSourceRestores devem ser listas')
        result['disabledPlugins'] = [item for item in disabled if item not in mapping.values()]
        for clone in mapping:
            if clone not in result['disabledPlugins']:
                result['disabledPlugins'].append(clone)
        if 'cloneSourceRestores' in result:
            result['cloneSourceRestores'] = [item for item in restores if item not in mapping]
    return result


def atomic_write(path, content):
    fd, temporary = tempfile.mkstemp(prefix='.' + path.name + '.', dir=path.parent)
    try:
        if path.exists():
            os.fchmod(fd, path.stat().st_mode & 0o777)
        with os.fdopen(fd, 'w', encoding='utf-8') as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='grava após criar backups')
    parser.add_argument('--plugins', nargs='*', default=[], metavar='NOME',
                        help='nomes simples separados por espaços ou vírgulas; padrão: somente idioma')
    parser.add_argument('--config-dir', type=Path,
                        default=Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'omarchy')
    parser.add_argument('--omarchy-path', type=Path,
                        default=Path(os.environ.get('OMARCHY_PATH', '/usr/share/omarchy')))
    args = parser.parse_args()
    names = list(dict.fromkeys(name for item in args.plugins for name in item.split(',') if name))
    unknown = set(names) - set(SIMPLE)
    if unknown:
        parser.error('plugins não permitidos: ' + ', '.join(sorted(unknown)))
    try:
        catalog = args.omarchy_path / 'default/i18n/pt-BR/shell.json'
        if not isinstance(json.loads(catalog.read_text(encoding='utf-8')), dict):
            raise ValueError('catálogo pt-BR inválido')
        manifests = set()
        for path in (args.omarchy_path / 'shell/plugins').rglob('*manifest.json'):
            manifests.add(json.loads(path.read_text(encoding='utf-8')).get('id'))
        for name in names:
            if 'omarchy.' + name not in manifests:
                raise ValueError('manifest oficial ausente: omarchy.' + name)
        shell = args.config_dir / 'shell.json'
        language = args.config_dir / 'language'
        old_shell = shell.read_text(encoding='utf-8')
        config = json.loads(old_shell)
        if not isinstance(config, dict):
            raise ValueError('shell.json deve conter um objeto')
        updated = migrate(config, names)
        new_shell = json.dumps(updated, ensure_ascii=False, indent=2) + '\n' if updated != config else old_shell
        old_language = language.read_text(encoding='utf-8') if language.exists() else ''
        changes = [(language, old_language, 'pt-BR\n'), (shell, old_shell, new_shell)]
        for path, before, after in changes:
            print(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                             fromfile=str(path), tofile=str(path) + ' (proposto)')), end='')
        if not args.apply:
            print('\nSimulação: nenhum arquivo alterado. Use --apply para gravar.')
            return
        if all(before == after for _, before, after in changes):
            print('Configuração já está no estado solicitado.')
            return
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
        # Backup dos dois arquivos antes da primeira gravação. .absent registra ausência.
        for path, _, _ in changes:
            backup = path.with_name(path.name + '.bak.' + stamp)
            if path.exists():
                shutil.copy2(path, backup)
            else:
                backup.with_name(backup.name + '.absent').touch(exist_ok=False)
        for path, before, after in changes:
            if before != after:
                atomic_write(path, after)
        print('\nAplicado. Backups: *.bak.' + stamp + ' (ou .absent).')
    except (OSError, ValueError, TypeError, AttributeError) as error:
        parser.exit(1, 'Erro: ' + str(error) + '\n')


if __name__ == '__main__':
    main()
