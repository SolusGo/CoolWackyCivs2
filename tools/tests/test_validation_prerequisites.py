"""Prerequisite errors and read-only behavior; all fixtures are synthetic files."""
from pathlib import Path
from contextlib import closing
import hashlib,json,os,sqlite3,sys,tempfile,unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import validation_prerequisites as p
from database import database

class Prerequisites(unittest.TestCase):
    def setUp(self):
        (p.ROOT/'dist').mkdir(exist_ok=True)
        self.temporary=tempfile.TemporaryDirectory(prefix='prerequisites-',dir=p.ROOT/'dist')
        self.root=Path(self.temporary.name);self.cp=self.root/'CP';self.cp.mkdir()
        self.manifest=self.cp/'Community Patch.modinfo'
        self.manifest.write_text(f'<Mod id="{p.CP_ID}" version="151" />')
        for name in p.SCHEMA_FILES+['NewCustomModOptions.xml']:
            target=self.cp/'Database Changes'/name;target.parent.mkdir(parents=True,exist_ok=True)
            target.write_text('<GameData />' if name.endswith('.xml') else '')
        self.cache=self.root/'BNW.db'
        with closing(sqlite3.connect(self.cache)) as d, d:
            d.executescript("""CREATE TABLE Civilizations(Type TEXT);
              INSERT INTO Civilizations VALUES ('CIVILIZATION_VENICE');
              CREATE TABLE Units(Type TEXT);INSERT INTO Units VALUES ('UNIT_XCOM_SQUAD'),('UNIT_ARCHAEOLOGIST');
              CREATE TABLE Buildings(Type TEXT);CREATE TABLE UnitPromotions(Type TEXT);
              CREATE TABLE GameSpeeds(Type TEXT);CREATE TABLE Unit_ClassUpgrades(UnitType TEXT);
              CREATE TABLE UnitPromotions_Features(PromotionType TEXT);""")
    def tearDown(self):
        self.assertEqual(self.root.resolve().parent,(p.ROOT/'dist').resolve())
        self.temporary.cleanup()
    def test_missing_database_actionable(self):
        with self.assertRaisesRegex(p.PrerequisiteError,'CWC2_CIV5_CACHE'):
            p.inspect_database(self.root/'missing.db',self.cp)
    def test_wrong_cp_version_rejected(self):
        self.manifest.write_text(f'<Mod id="{p.CP_ID}" version="150" />')
        with self.assertRaisesRegex(p.PrerequisiteError,'version 151'):p.inspect_database(self.cache,self.cp)
    def test_incomplete_cp_installation(self):
        (self.cp/'Database Changes/NewCustomModOptions.xml').unlink()
        with self.assertRaisesRegex(p.PrerequisiteError,'Incomplete CP'):p.inspect_database(self.cache,self.cp)
    def test_vanilla_database_rejected(self):
        with closing(sqlite3.connect(self.cache)) as d, d:d.execute('DELETE FROM Civilizations')
        with self.assertRaisesRegex(p.PrerequisiteError,'No vanilla substitution'):p.inspect_database(self.cache,self.cp)
    def test_collection_loaded_snapshot_rejected(self):
        with closing(sqlite3.connect(self.cache)) as d, d:d.execute("INSERT INTO Civilizations VALUES ('CIVILIZATION_T1Z_ZOFGK')")
        with self.assertRaisesRegex(p.PrerequisiteError,'already contains this collection'):p.inspect_database(self.cache,self.cp)
    def test_non_sqlite_rejected(self):
        self.cache.write_bytes(b'invalid snapshot')
        with self.assertRaisesRegex(p.PrerequisiteError,'intact SQLite'):p.inspect_database(self.cache,self.cp)
    def test_read_only_snapshot_and_explicit_overlay(self):
        before=hashlib.sha256(self.cache.read_bytes()).hexdigest()
        profile=p.inspect_database(self.cache,self.cp)
        self.assertIn('overlaid explicitly',profile['baseline'])
        d=database(self.cache,self.cp);d.execute('CREATE TABLE T1Z_TEST_MEMORY(value INTEGER)');d.close()
        self.assertEqual(before,hashlib.sha256(self.cache.read_bytes()).hexdigest())
    def test_environment_paths_honor_explicit_inputs(self):
        with patch.dict(os.environ,{'CWC2_CIV5_CACHE':str(self.cache),'CWC2_CP_DIR':str(self.cp)}):
            self.assertEqual(p.paths(),(self.cache.resolve(),self.cp.resolve()))
    def test_missing_sources_fetch_hint(self):
        with self.assertRaisesRegex(p.PrerequisiteError,'audit_cp.py --fetch'):p.require_sources(['CvUnit.cpp'],self.root)
    def test_source_hash_and_commit_are_checked(self):
        source=self.root/'sources';source.mkdir();file=source/'CustomMods.h';file.write_text('pinned fixture')
        manifest={'commit':p.CP_COMMIT,'files':{'CustomMods.h':{'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}}}
        pin=source/'CP-v151-sources.json';pin.write_text(json.dumps(manifest))
        self.assertEqual(p.require_sources(['CustomMods.h'],source)['files'],1)
        file.write_text('changed fixture')
        with self.assertRaisesRegex(p.PrerequisiteError,'has changed'):p.require_sources(['CustomMods.h'],source)
        manifest['commit']='wrong';pin.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(p.PrerequisiteError,'wrong commit'):p.require_sources(['CustomMods.h'],source)
    def test_game_path_is_not_user_directory(self):
        with patch.dict(os.environ,{'CIV5_PATH':str(self.root)}):
            with self.assertRaisesRegex(p.PrerequisiteError,'game install'):p.inspect_game()
    def test_dependencies_have_install_hint(self):
        with patch.object(p,'find_spec',return_value=None):
            with self.assertRaisesRegex(p.PrerequisiteError,'pip install -r requirements-dev.txt'):p.require_packages()

if __name__=='__main__':unittest.main()
