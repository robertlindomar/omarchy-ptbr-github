#!/usr/bin/env python3
"""Confere referências, exclusão dos clones nativos e resposta do shell."""
import json
import os
from pathlib import Path
import subprocess
import sys

config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home()/'.config')))/'omarchy'
shell = json.loads((config/'shell.json').read_text())
failures = []
if (config/'language').read_text().strip() != 'pt-BR':
    failures.append('Idioma da shell diferente de pt-BR')
try:
    items = json.loads(subprocess.check_output(['omarchy','plugin','list','--json'], text=True))
except (subprocess.CalledProcessError, json.JSONDecodeError):
    sys.exit('FALHA: shell indisponível ou lista de plugins inválida')
known = {p['id']:p for p in items}
refs = [p['id'] for group in shell.get('bar',{}).get('layout',{}).values() for p in group if isinstance(p,dict)]
refs += [p['id'] for p in shell.get('plugins',[]) if isinstance(p,dict)]
explicit = {p['id'] for p in shell.get('plugins',[]) if isinstance(p,dict)}
disabled = set(shell.get('disabledPlugins', []))
for plugin in sorted(set(refs)):
    if plugin not in known:
        failures.append('Plugin ausente: '+plugin)
    elif plugin in disabled or (not known[plugin]['enabled'] and not (plugin in explicit and 'bar-widget' in known[plugin]['kinds'])):
        failures.append('Plugin referenciado mas desabilitado: '+plugin)
for p in items:
    if p['id'].startswith('robertlindomar.omarchy-ptbr.') and p.get('clonedFrom','').startswith('omarchy.') and p['enabled']:
        failures.append('Clone nativo ainda habilitado: '+p['id'])
for error in failures:
    print('FALHA: '+error)
if failures:
    sys.exit(1)
print('OK: idioma pt-BR, referências válidas e clones oficiais desabilitados.')
