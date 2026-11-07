import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT/'scripts'/(name+'.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

native = load('migrate-native')
community = load('install-community')

class MigrationTests(unittest.TestCase):
    def test_preserves_layout_settings_and_cursor_choice(self):
        config = {'bar': {'layout': {'right': [{'id': native.PREFIX+'agents', 'providers': {'cursor': {'enabled': True}}, 'syncDir': '/tmp/sync'}, {'id':'omarchy.elsewhen','cities':[{'name':'São Paulo'}]}]}, 'position':'bottom'}, 'idle': {'lock':123}, 'disabledPlugins':['omarchy.agents','custom'], 'cloneSourceRestores':[native.PREFIX+'agents']}
        result = native.migrate(config, ['agents'])
        self.assertTrue(result['bar']['layout']['right'][0]['providers']['cursor']['enabled'])
        self.assertEqual(result['idle'], config['idle'])
        self.assertEqual(result['bar']['layout']['right'][1], config['bar']['layout']['right'][1])
        self.assertEqual(result, native.migrate(result, ['agents']))
        self.assertEqual(config['bar']['layout']['right'][0]['id'],native.PREFIX+'agents')

    def test_community_merges_duplicate_and_preserves_clone_preference(self):
        for entries in [[{'id':'old','x':1},{'id':'clone','x':2}], [{'id':'clone','x':2},{'id':'old','x':1}]]:
            result = community.transform({'bar':{'centerAnchor':'old','layout':{'left':entries}},'plugins':['old','clone']}, {'old':'clone'})
            self.assertEqual(result['bar']['layout']['left'],[{'id':'clone','x':2}])
            self.assertEqual(result['bar']['centerAnchor'],'clone')
            self.assertEqual(result['plugins'],['clone'])

    def test_dryrun_backups_and_idempotence(self):
        with tempfile.TemporaryDirectory() as directory:
            config_dir = Path(directory)
            shell = config_dir/'shell.json'
            before = json.dumps({'plugins':[{'id':native.PREFIX+'reminders'}]})
            shell.write_text(before)
            command = ['python3', str(ROOT/'scripts/migrate-native.py'), '--config-dir', directory, '--plugins', 'reminders']
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            self.assertEqual(shell.read_text(), before)
            self.assertFalse((config_dir/'language').exists())
            subprocess.run(command+['--apply'], check=True, stdout=subprocess.DEVNULL)
            self.assertEqual(next(config_dir.glob('shell.json.bak.*')).read_text(),before)
            self.assertTrue(list(config_dir.glob('language.bak.*.absent')))
            count = len(list(config_dir.iterdir()))
            subprocess.run(command+['--apply'],check=True,stdout=subprocess.DEVNULL)
            self.assertEqual(count,len(list(config_dir.iterdir())))

if __name__ == '__main__':
    unittest.main()
