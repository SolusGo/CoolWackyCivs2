"""Installer checks use disposable copies; never modify the installed mod."""
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase, main
from unittest.mock import patch
import subprocess
import hashlib
import hotfix_boundless_reservations as hotfix

class InstallerTests(TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory(dir=hotfix.ROOT/'dist')
        self.addCleanup(self.temp.cleanup)
        self.target = Path(self.temp.name)/'mod'
        self.target.mkdir()
        self.original = {'TheBoundlessCity/Lua/'+n: ('-- original fixture '+n).encode() for n in hotfix.ORIGINALS}
        entries = ''.join('<File md5="'+hashlib.md5(data).hexdigest()+'">'+name+'</File>' for name,data in self.original.items())
        self.original[hotfix.MANIFEST] = ('<Mod id="'+hotfix.MOD_ID+'" version="23"><Properties><Name>Fixture</Name></Properties><Files>'+entries+'</Files></Mod>').encode()
        self.hashes = patch.object(hotfix,'ORIGINALS',{Path(name).name:hashlib.sha256(data).hexdigest() for name,data in self.original.items() if name!=hotfix.MANIFEST})
        self.hashes.start();self.addCleanup(self.hashes.stop)
        for name,data in self.original.items():
            path = self.target/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            self.original[name] = data
        self.processes = patch.object(hotfix.subprocess,'run',return_value=subprocess.CompletedProcess([],0,stdout=''))
        self.processes.start();self.addCleanup(self.processes.stop)

    def test_install_and_repeat(self):
        before, after = hotfix.plan(self.target)
        backup = hotfix.apply(self.target,before,after,Path(self.temp.name)/'backups')
        for name,data in before.items():self.assertEqual((backup/name).read_bytes(),data)
        before2,after2 = hotfix.plan(self.target)
        self.assertEqual(before2,after2)
        self.assertIsNone(hotfix.apply(self.target,before2,after2))

    def test_unknown_source(self):
        path = self.target/'TheBoundlessCity/Lua/BoundlessCitizens.lua'
        path.write_bytes(path.read_bytes()+b'\n-- unknown edit')
        with self.assertRaisesRegex(ValueError,'Unreviewed'):hotfix.plan(self.target)

    def test_previous_repair_can_be_updated(self):
        relative = 'TheBoundlessCity/Lua/BoundlessCitizens.lua'
        previous = b'-- earlier reviewed repair'
        (self.target/relative).write_bytes(previous)
        manifest = self.target/hotfix.MANIFEST
        manifest.write_bytes(hotfix.update_manifest(self.original[hotfix.MANIFEST], {relative: previous}))
        previous_hash = hashlib.sha256(previous).hexdigest()
        with patch.dict(hotfix.PREVIOUS_PATCHED, {'BoundlessCitizens.lua': previous_hash}):
            before, after = hotfix.plan(self.target)
        self.assertEqual(before[relative], previous)
        self.assertNotEqual(after[relative], previous)

    def test_manifest_checksum(self):
        path = self.target/hotfix.MANIFEST
        relative = 'TheBoundlessCity/Lua/BoundlessCitizens.lua'
        data = hotfix.update_manifest(self.original[hotfix.MANIFEST],{relative:b'wrong bytes'})
        path.write_bytes(data)
        with self.assertRaisesRegex(ValueError,'checksum'):hotfix.plan(self.target)

    def test_running_game(self):
        before,after = hotfix.plan(self.target)
        with patch.object(hotfix.subprocess,'run',return_value=subprocess.CompletedProcess([],0,stdout='CivilizationV_DX11.exe')):
            with self.assertRaisesRegex(ValueError,'Exit Civilization'):hotfix.apply(self.target,before,after)
        for name,data in before.items():self.assertEqual((self.target/name).read_bytes(),data)

    def test_rollback(self):
        before,after = hotfix.plan(self.target)
        write = Path.write_bytes;failed = False
        def fault(path,data):
            nonlocal failed
            if path == self.target/'TheBoundlessCity/Lua/BoundlessPlanner.lua' and not failed:
                failed = True;raise OSError('injected write failure')
            return write(path,data)
        with patch.object(Path,'write_bytes',fault):
            with self.assertRaisesRegex(OSError,'injected'):hotfix.apply(self.target,before,after,Path(self.temp.name)/'backups')
        for name,data in before.items():self.assertEqual((self.target/name).read_bytes(),data)

if __name__ == '__main__':main()
