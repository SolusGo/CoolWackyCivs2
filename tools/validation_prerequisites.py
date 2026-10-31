"""Read-only, standard-library preflight for reproducible BNW/CP validation."""
from contextlib import closing
from importlib.util import find_spec
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,json,os,sqlite3,sys

ROOT=Path(__file__).resolve().parents[1]
CP_ID='d1b6328c-ff44-4b0d-aad7-c657f83610cd'
CP_COMMIT='44c1e14ff75d80c1dba5c8a71e8289439a53aafb'
SCHEMA_FILES=['City/Buildings/BuildingTableChanges.sql','UnitPromotions/PromotionTableChanges.sql',
              'Units/UnitTableChanges.sql','Policies/PolicyTableChanges.sql','AI/LeaderTableChanges.sql',
              'Civilizations/CivilizationTableChanges.sql']
T1_SOURCES=['CustomMods.h','CvUnit.cpp','CvCity.cpp','CvPlayer.cpp','CvPromotionClasses.cpp',
            'CvUnitClasses.cpp','CvMinorCivAI.cpp','CvLuaUnit.cpp','CvLuaPlayer.cpp','CvLuaCity.cpp','CvLuaTeam.cpp','CvLuaGame.cpp']

class PrerequisiteError(RuntimeError):
    pass

def paths(cache=None,cp=None):
    user=Path(os.environ.get('CWC2_CIV5_USER_PATH',Path.home()/"Documents/My Games/Sid Meier's Civilization 5"))
    cache=Path(cache or os.environ.get('CWC2_CIV5_CACHE',user/'cache_backup/Civ5DebugDatabase.db')).expanduser().resolve()
    cp=Path(cp or os.environ.get('CWC2_CP_DIR',user/'MODS/(1) Community Patch')).expanduser().resolve()
    return cache,cp

def inspect_database(cache=None,cp=None):
    cache,cp=paths(cache,cp)
    if not cache.is_file():
        raise PrerequisiteError(f'Missing Civ V baseline: {cache}\n'
            'Copy a BNW debug database to that path or set $env:CWC2_CIV5_CACHE to an explicit snapshot. '
            'Activate BNW + CP v151 without this collection, load a game with LoggingEnabled=1, quit, '
            'then copy cache\\Civ5DebugDatabase.db. No menu/vanilla fallback is used.')
    manifests=[]
    for p in cp.glob('*.modinfo'):
        try:
            root=ET.parse(p).getroot()
            if root.get('id','').lower()==CP_ID:manifests.append((p,root.get('version')))
        except ET.ParseError as exc:raise PrerequisiteError(f'Invalid CP modinfo {p}: {exc}') from exc
    if len(manifests)!=1 or manifests[0][1]!='151':
        raise PrerequisiteError(f'Expected Community Patch UUID {CP_ID}, version 151 in {cp}. '
            'Install CP v151 and set $env:CWC2_CP_DIR to its mod directory (not the game install directory).')
    required=[cp/'Database Changes'/name for name in SCHEMA_FILES+['NewCustomModOptions.xml']]
    missing=[str(p) for p in required if not p.is_file()]
    if missing:raise PrerequisiteError('Incomplete CP v151 schema installation:\n'+'\n'.join(missing))
    try:
        with closing(sqlite3.connect(cache.as_uri()+'?mode=ro',uri=True)) as d:
            tables={r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            needed={'Civilizations','Units','Buildings','UnitPromotions','GameSpeeds','Unit_ClassUpgrades','UnitPromotions_Features'}
            if not needed<=tables:raise PrerequisiteError(f'Incompatible Civ V database {cache}: missing {sorted(needed-tables)}. Use a BNW snapshot.')
            for table,typ in [('Civilizations','CIVILIZATION_VENICE'),('Units','UNIT_XCOM_SQUAD'),('Units','UNIT_ARCHAEOLOGIST')]:
                if not d.execute('SELECT 1 FROM '+table+' WHERE Type=?',(typ,)).fetchone():
                    raise PrerequisiteError(f'{cache} is not a compatible BNW baseline: missing {typ}. No vanilla substitution is allowed.')
            if d.execute("SELECT 1 FROM Civilizations WHERE Type IN ('CIVILIZATION_T1Z_ZOFGK','CIVILIZATION_BOUNDLESS_CITY')").fetchone():
                raise PrerequisiteError(f'{cache} already contains this collection. Capture a baseline without Cool Wacky Civs 2 to avoid duplicate definitions.')
            cp_schema='IsDummy' in {r[1] for r in d.execute('PRAGMA table_info(Buildings)')} and 'CustomModOptions' in tables
    except sqlite3.Error as exc:raise PrerequisiteError(f'Cannot read Civ V snapshot {cache}: {exc}. Choose an intact SQLite debug database.') from exc
    return {'cache':str(cache),'cp':str(cp),'cp_modinfo':str(manifests[0][0]),'cp_version':151,
            'baseline':'BNW snapshot with CP schema' if cp_schema else 'BNW snapshot; CP v151 schema overlaid explicitly in memory',
            'read_only':True}

def require_sources(names,source=None):
    source=Path(source or ROOT/'tools/reference')
    missing=[name for name in names if not (source/name).is_file()]
    hint='Run python tools/audit_cp.py --fetch from the repository root to download the pinned v151 references.'
    if missing:raise PrerequisiteError('Missing CP source prerequisites: '+', '.join(missing)+'. '+hint)
    manifest=source/'CP-v151-sources.json'
    if not manifest.is_file():raise PrerequisiteError('Missing pinned source manifest. '+hint)
    try:inventory=json.loads(manifest.read_text(encoding='utf-8'))
    except (ValueError,OSError) as exc:raise PrerequisiteError(f'Invalid source manifest {manifest}. '+hint) from exc
    if inventory.get('commit')!=CP_COMMIT:raise PrerequisiteError('CP source manifest has the wrong commit. '+hint)
    for name in names:
        entry=inventory.get('files',{}).get(name,{})
        digest=hashlib.sha256((source/name).read_bytes()).hexdigest()
        if digest!=entry.get('sha256'):raise PrerequisiteError(f'CP source {name} is missing from the pin or has changed. '+hint)
    return {'commit':CP_COMMIT,'directory':str(source.resolve()),'files':len(names)}

def require_packages():
    if sys.version_info<(3,11):raise PrerequisiteError('Use Python 3.11 or later.')
    missing=[name for name,module in [('Pillow','PIL'),('lupa','lupa'),('py7zr','py7zr')] if find_spec(module) is None]
    if missing:raise PrerequisiteError('Missing Python dependencies: '+', '.join(missing)+'. Run python -m pip install -r requirements-dev.txt.')

def inspect_game():
    candidates=([Path(os.environ['CIV5_PATH'])] if os.environ.get('CIV5_PATH') else
                [Path("G:/SteamLibrary/steamapps/common/Sid Meier's Civilization V"),Path("C:/Program Files (x86)/Steam/steamapps/common/Sid Meier's Civilization V")])
    required=['Assets/UI/SupportFunctions.lua','Assets/UI/Styles.xml','Assets/UI/IconSupport.lua',
              'Assets/DLC/Expansion2/UI/Civilopedia/CivilopediaScreen.lua']
    for game in candidates:
        if all((game/name).is_file() for name in required):return {'directory':str(game.resolve()),'files':required}
    raise PrerequisiteError('Missing installed BNW UI assets. Set $env:CIV5_PATH to the Civilization V game install '
        '(Steam\\steamapps\\common\\Sid Meier\'s Civilization V), containing Assets\\UI\\Styles.xml and BNW Civilopedia Lua. '
        'This is different from the Documents/My Games user directory.')

def check_environment(collection=False):
    require_packages()
    if collection:
        from audit_cp import FILES
        names=[Path(name).name for name in FILES]
    else:names=T1_SOURCES
    result={'database':inspect_database(),'sources':require_sources(names),'game':inspect_game()}
    print('PREREQUISITES:',result['database']['baseline'],'; CP v151 source pin and installed BNW UI verified (read-only)')
    return result

def main_check(collection=False):
    try:return check_environment(collection)
    except PrerequisiteError as exc:raise SystemExit('Validation prerequisites not met:\n'+str(exc)) from None
