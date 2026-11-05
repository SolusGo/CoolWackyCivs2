"""Meaningful offline validation. Never modifies the installed game databases."""
from pathlib import Path
import hashlib
import sqlite3
import sys
import xml.etree.ElementTree as ET
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'TheCovenant'
from lupa.lua51 import LuaRuntime

def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    def include(name):
        lua.execute((MOD / 'Lua' / (name + '.lua')).read_text(encoding='utf-8'))
    lua.globals().include = include
    return lua

def execute(lua, path):
    return lua.execute(path.read_text(encoding='utf-8'))

def ui_runtime(saved=None):
    lua = runtime()
    if saved:
        lua.globals().saved = lua.table_from(saved)
    execute(lua, ROOT / 'tools/tests/covenant_mock.lua')
    execute(lua, MOD / 'UI' / 'CovenantGate.lua')
    return lua

def lifecycle_tests():
    scenarios = ROOT / 'tools/tests/covenant_lifecycle.lua'
    names = sorted(execute(ui_runtime(), scenarios).keys())
    for name in names:
        ui = ui_runtime()
        execute(ui, scenarios)[name]()
        print('PASS UI contract model:', name)

    # Reload the ACTUAL persisted mid-exam payload, including its reward journal.
    ui = ui_runtime()
    ui.execute('''
      Events.LoadScreenClose.fire()
      for t = 0, 4 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
      turn = 9; Events.ActivePlayerTurnStart.fire(); finishPassage()
      typeText(CovenantVerses[currentState().session.queue[1]].reference); click('Submit')
      assert(currentState().session.exam and currentState().session.phase == 'section')
      assert(#currentState().session.queue == 4 and currentState().rewardTurn == 9)
    ''')
    snapshot = dict(ui.globals().saved.items())
    restored = ui_runtime(snapshot)
    restored.execute('''
      turn = 9; Events.LoadScreenClose.fire()
      assert(currentState().session.phase == 'section' and #currentState().session.queue == 4)
      for n = 1, 4 do finishPassage() end
      assert(player.faith == 0 and player.culture == 0 and semaphores == 0)
      assert(currentState().rewardTurn == 9)
    ''')
    print('PASS reload mid-exam/numbered section preserves reward cap and remaining queue')

    # Same player/key in a different saved-game database starts a fresh curriculum.
    empty = ui_runtime()
    empty.execute('Events.LoadScreenClose.fire(); assert(currentState().lessons[1].passes == 0)')
    # Exercise the original v24 key and payload plus its separate reward marker.
    legacy = {}
    for key, value in snapshot.items():
        if not key.endswith('_RewardTurn'):
            fields = value.split(',')
            assert fields[0] == '2'
            legacy[key] = ','.join(['1'] + fields[1:4] + fields[5:])
        else:
            legacy[key] = value
    migrated = ui_runtime(legacy)
    migrated.execute('''
      turn = 9; Events.LoadScreenClose.fire()
      assert(currentState().rewardTurn == 9 and #currentState().session.queue == 4)
      for n = 1, 4 do finishPassage() end
      assert(player.faith == 0 and player.culture == 0)
    ''')
    print('PASS existing v24 key/payload/legacy reward migration and separate-campaign store isolation')
    for invalid in ('garbage', '999,0,-1,-1,0', '1,0,-1,-1,1,0'):
        damaged = {key: invalid for key in snapshot if not key.endswith('_RewardTurn')}
        ui = ui_runtime(damaged)
        ui.execute('Events.LoadScreenClose.fire(); assert(currentState().session.assisted and currentState().session.phase == "study")')
    print('PASS invalid saves restart safely with mandatory assisted introduction')
    return len(names) + 4

def native_source_contracts():
    # Inspect shipped source, never substitute a mock for native execution.
    from validation_prerequisites import inspect_game
    game = Path(inspect_game()['directory'])
    evidence = {}
    for filename in ('SetCityName', 'SetUnitName'):
        path = game / f'Assets/UI/InGame/Popups/{filename}.lua'
        text = path.read_text(encoding='utf-8-sig')
        handler = text[text.index('function InputHandler'):text.index('ContextPtr:SetInputHandler')]
        assert 'return true;' in handler
        assert ':RegisterCallback(Validate)' in text
        assert 'UI.incTurnTimerSemaphore()' in text and 'UI.decTurnTimerSemaphore()' in text
        xml = ET.parse(path.with_suffix('.xml'))
        edit = next(e for e in xml.iter('EditBox'))
        assert edit.get('CallOnChar') == '1' and edit.get('EditMode') == '1'
        evidence[str(path.relative_to(game))] = hashlib.sha256(path.read_bytes()).hexdigest()
    save = game / 'Assets/DLC/DLC_01/Scenarios/Mongol Scenario/CivsAlive.lua'
    text = save.read_text(encoding='utf-8-sig')
    assert 'savedData.GetValue(' in text and 'savedData.SetValue(' in text
    evidence[str(save.relative_to(game))] = hashlib.sha256(save.read_bytes()).hexdigest()
    gate = (MOD / 'UI/CovenantGate.lua').read_text(encoding='utf-8')
    assert 'storage:GetValue' not in gate and 'storage:SetValue' not in gate
    xml = ET.parse(MOD / 'UI/CovenantGate.xml')
    identifiers=[e.get('ID') for e in xml.iter() if e.get('ID')]
    assert len(identifiers)==len(set(identifiers))
    ids = set(identifiers)
    for element in xml.iter():
        if element.get('Font','').startswith('TwCenMT'):
            assert (game/'Assets/UI/Fonts/Tw Cent MT'/(element.get('Font')+'.ggxml')).is_file(),element.get('Font')
    assert set(re.findall(r'Controls\.([A-Za-z_]+)', gate)) <= ids
    edit = next(e for e in xml.iter('EditBox'))
    assert edit.get('CallOnChar') == '1' and edit.get('EditMode') == '1'
    assert xml.find(".//*[@ID='Backdrop']").get('ConsumeMouse') == '1'
    audit = json.loads((MOD / 'docs/SourceAudit.json').read_text(encoding='utf-8'))
    assert evidence == audit['shipped_scripts_sha256']
    print('PASS installed Firaxis modal/EditBox/save-call source contracts (not native UI execution)')

def sql_contracts(db):
    civ, leader, trait = 'CIVILIZATION_COVENANT_MEMORY', 'LEADER_COVENANT_SCRIBE', 'TRAIT_COVENANT_WRITTEN_HEART'
    assert db.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?', (civ,)).fetchone()[0] == leader
    assert db.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?', (leader,)).fetchone()[0] == trait
    assert db.execute('SELECT CityCultureBonus FROM Traits WHERE Type=?', (trait,)).fetchone()[0] == 1
    for table, columns in [('Civilization_FreeUnits', 'UnitClassType,UnitAIType,Count'),
                           ('Civilization_FreeTechs', 'TechType'), ('Civilization_FreeBuildingClasses', 'BuildingClassType')]:
        def rows(which):
            return sorted(tuple(r) for r in db.execute(f'SELECT {columns} FROM {table} WHERE CivilizationType=?', (which,)))
        assert rows(civ) == rows('CIVILIZATION_EGYPT'), table
    for old, new, yields in [('SHRINE', 'SCRIPTORIUM', {'YIELD_FAITH': 2, 'YIELD_CULTURE': 1}),
                              ('TEMPLE', 'TABERNACLE', {'YIELD_FAITH': 3, 'YIELD_SCIENCE': 1})]:
        original, custom = 'BUILDING_' + old, 'BUILDING_COVENANT_' + new
        a = db.execute('SELECT * FROM Buildings WHERE Type=?', (original,)).fetchone()
        b = db.execute('SELECT * FROM Buildings WHERE Type=?', (custom,)).fetchone()
        for field in ('BuildingClass', 'Cost', 'FaithCost', 'PrereqTech', 'GoldMaintenance',
                      'ArtDefineTag', 'NeverCapture'):
            assert a[field] == b[field], (custom, field)
        assert dict(db.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?', (custom,))) == yields
        for table in ('Building_ClassesNeededInCity',):
            def prerequisites(which):
                return sorted(tuple(r)[1:] for r in db.execute('SELECT * FROM ' + table + ' WHERE BuildingType=?', (which,)))
            assert prerequisites(original) == prerequisites(custom)
    assert db.execute('SELECT ArtDefineTag FROM Civilizations WHERE Type=?',(civ,)).fetchone()[0] == db.execute("SELECT ArtDefineTag FROM Civilizations WHERE Type='CIVILIZATION_EGYPT'").fetchone()[0]
    text = '\n'.join(p.read_text(encoding='utf-8') for p in (MOD / 'SQL').glob('*.sql'))
    keys = set(re.findall(r"'(TXT_KEY_COVENANT_[A-Z_0-9]+)'", text))
    assert keys
    for key in keys:
        assert db.execute('SELECT Text FROM Language_en_US WHERE Tag=?', (key,)).fetchone(), key
    print('PASS exact trait/reward SQL scope, starts, building yields/inheritance/prerequisites, native models and localization')

def artwork_contracts(db):
    from PIL import Image
    from prepare_covenant_art import SIZES, UI_SIZES
    from standardize_icons import frame_cell
    expected = [('CIV','Icon',1,SIZES), ('ALPHA','Alpha',1,SIZES),
                ('LEADER','Portrait',1,SIZES), ('OBJECT','Objects',2,SIZES), ('FLAG','Flag',1,(32,))]
    rows = list(db.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'COVENANT_%'"))
    assert len(rows)==37
    for family,stem,columns,sizes in expected:
        for size in sizes:
            row=db.execute('SELECT * FROM IconTextureAtlases WHERE Atlas=? AND IconSize=?',(f'COVENANT_{family}_ATLAS',size)).fetchone()
            assert row and row['Filename']==f'COVENANT_{stem}{size}.dds'
            assert (int(row['IconsPerRow']),int(row['IconsPerColumn']))==(columns,1)
    for table,typ,atlas,index in [('Civilizations','CIVILIZATION_COVENANT_MEMORY','CIV',0),
                                ('Leaders','LEADER_COVENANT_SCRIBE','LEADER',0),
                                ('Buildings','BUILDING_COVENANT_SCRIPTORIUM','OBJECT',0),
                                ('Buildings','BUILDING_COVENANT_TABERNACLE','OBJECT',1)]:
        assert tuple(db.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()) == (f'COVENANT_{atlas}_ATLAS',index)
    civ=db.execute("SELECT AlphaIconAtlas,MapImage,DawnOfManImage,DawnOfManAudio FROM Civilizations WHERE Type='CIVILIZATION_COVENANT_MEMORY'").fetchone()
    assert tuple(civ)==('COVENANT_ALPHA_ATLAS','COVENANT_Map.dds','COVENANT_Dawn.dds','')
    scene=db.execute("SELECT ArtDefineTag FROM Leaders WHERE Type='LEADER_COVENANT_SCRIBE'").fetchone()[0]
    assert scene=='COVENANT_LeaderScene.xml'
    assert ET.parse(MOD/'Art'/scene).getroot().get('FallbackImage')=='COVENANT_Leader.dds'
    textures=list((MOD/'Art').glob('*.dds'));assert len(textures)==43
    for p in textures:
        raw=p.read_bytes();assert raw[:4]==b'DDS ' and raw[84:88]!=b'DX10'
        with Image.open(p) as im:
            im.load();w,h=im.size
            assert struct.unpack_from('<I',raw,28)[0]==max(w,h).bit_length(),p
            assert len(raw)==128+sum(max(1,w>>i)*max(1,h>>i)*4 for i in range(max(w,h).bit_length())),p
            if '_Alpha' in p.name or '_Flag' in p.name:
                rgb=im.convert('RGB')
                assert rgb.getchannel('R').tobytes()==rgb.getchannel('G').tobytes()==rgb.getchannel('B').tobytes(),p
    xml=ET.parse(MOD/'UI/CovenantGate.xml')
    for element in xml.iter('Image'):
        if element.get('Texture','').startswith('COVENANT_'):
            with Image.open(MOD/'Art'/element.get('Texture')) as im:
                assert im.size==tuple(map(int,element.get('Size').split(','))),element.attrib
            assert element.get('ConsumeMouse')=='0'
    for button in xml.iter('GridButton'):
        data=button.find('GridData')
        assert data is not None and data.get('Style')=='Grid9FrameButtons' and data.get('Texture')=='COVENANT_UI_Buttons.dds'
    for name,size in UI_SIZES.items():
        with Image.open(MOD/'Art'/f'COVENANT_UI_{name}.dds') as im:assert im.size==size
    # Prove native atlas cells are the actual deterministic compiler output.
    for stem,columns in [('Icon',1),('Portrait',1),('Objects',2)]:
        with Image.open(ROOT/'art-source/IconAtlasMasters'/f'COVENANT_{stem}256.png') as master:
            expected=Image.new('RGBA',(columns*256,256))
            for i in range(columns):
                cell=frame_cell(master.crop((i*256,0,(i+1)*256,256)),256,stem=='Portrait')
                expected.alpha_composite(cell,(i*256,0))
            with Image.open(MOD/'Art'/f'COVENANT_{stem}256.dds') as compiled:assert expected.tobytes()==compiled.convert('RGBA').tobytes()
    print('PASS original Covenant art: 37 atlas declarations, 43 decoded full-mip legacy DDS, exact cells, native-size UI skins and static leader/loading/map references')

def nonvisual_snapshot(db):
    allowed={'Civilizations':{'IconAtlas','AlphaIconAtlas','PortraitIndex','MapImage','DawnOfManImage','DawnOfManAudio'},
             'Leaders':{'IconAtlas','PortraitIndex','ArtDefineTag'},'Buildings':{'IconAtlas','PortraitIndex'}}
    result={}
    for (table,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        if table=='IconTextureAtlases':continue
        columns=[r[1] for r in db.execute('PRAGMA table_info("'+table+'")') if r[1] not in allowed.get(table,set())]
        result[table]=[tuple(r) for r in db.execute('SELECT '+','.join('"'+c+'"' for c in columns)+' FROM "'+table+'"')]
    return result

def main():
    lua = runtime()
    for file in sorted(MOD.rglob('*.lua')):
        lua.execute('return function(...)\n' + file.read_text(encoding='utf-8') + '\nend')
    print('PASS all Lua files compile under Lua 5.1')
    lua.globals().include('CovenantVerses')
    lua.globals().include('CovenantMemory')
    count = execute(lua, ROOT / 'tools/tests/covenant_engine.lua')
    ui_count = lifecycle_tests()
    native_source_contracts()

    ui = ui_runtime()
    ui.execute('''
      Events.LoadScreenClose.fire()
      assert(not ContextPtr.hidden and semaphores == 1)
      assert(currentState().session.phase == 'study')
      click('Submit')
      assert(currentState().session.phase == 'study')
      for _, key in ipairs({Keys.VK_ESCAPE, Keys.VK_RETURN, Keys.VK_SPACE, 116}) do
        assert(ContextPtr.input(KeyEvents.KeyDown, key, 0))
        assert(ContextPtr.input(KeyEvents.KeyUp, key, 0))
        assert(not ContextPtr.hidden)
      end
      tick(60); click('Submit')
      Controls.Answer:SetText('Revelation 3:17-18')
      assert(Controls.Answer:GetText() == '')
      typeText('Revelation 3:17-18'); click('Submit')
      assert(currentState().session.phase == 'section')
      typeText(CovenantVerses[1].sections[1]); click('Submit')
      assert(currentState().session.section == 2)
    ''')
    saved = dict(ui.globals().saved.items())
    restored = ui_runtime(saved)
    restored.execute('''
      Events.LoadScreenClose.fire()
      assert(not ContextPtr.hidden and currentState().session.section == 2)
      finishPassage()
      assert(ContextPtr.hidden and semaphores == 0)
      assert(player.faith == 0 and player.culture == 0)
      tick(1)
      assert(ContextPtr.hidden)
      for n = 1, 4 do
        turn = n; Events.ActivePlayerTurnStart.fire(); finishPassage()
        assert(ContextPtr.hidden and semaphores == 0)
      end
      turn = 5; Events.ActivePlayerTurnStart.fire(); finishPassage()
      assert(player.faith == 10 and player.culture == 5)
      turn = 9; Events.ActivePlayerTurnStart.fire()
      assert(#currentState().session.queue == 5)
      for n = 1, 5 do finishPassage() end
      assert(ContextPtr.hidden and semaphores == 0)
      assert(player.faith == 20 and player.culture == 10)
      Events.ActivePlayerTurnStart.fire(); tick(1)
      assert(ContextPtr.hidden and player.faith == 20)
    ''')
    print('PASS UI model: study timer, unhandled keyboard capture, bulk-edit rejection, reload, rewards, exam, timer balance')
    for mode in ('player.civ = 0', 'player.human = false', 'network = true', 'hotseat = true'):
        ui = ui_runtime()
        ui.execute(mode + '; Events.LoadScreenClose.fire(); tick(1); assert(ContextPtr.hidden and semaphores == 0)')
    print('PASS other civilizations, AI, multiplayer, and hotseat are unaffected')

    manifest = ET.parse(ROOT / 'Cool Wacky Civs 2 (v 24).modinfo').getroot()
    assert manifest.attrib['version'] == '24'
    entries = manifest.findall('./Files/File')
    for entry in entries:
        if entry.text.startswith('TheCovenant/'):
            path = ROOT / entry.text
            assert hashlib.md5(path.read_bytes()).hexdigest().upper() == entry.attrib['md5']
            from build_mod import imported
            assert entry.attrib['import'] == str(int(imported(path)))
    assert any(e.attrib['file'] == 'TheCovenant/UI/CovenantGate.xml' for e in manifest.findall('./EntryPoints/EntryPoint'))
    ET.parse(MOD / 'UI/CovenantGate.xml')
    print('PASS Covenant manifest, VFS, XML and hashes')

    from database import database
    db = database()
    before = {t: list(db.execute('SELECT * FROM "' + t + '"')) for t in ('Civilizations', 'Leaders', 'Buildings', 'Traits')}
    for script in sorted((MOD / 'SQL').glob('*.sql')):
        if script.name=='03_COVENANT_Art.sql':
            gameplay=nonvisual_snapshot(db)
            native_atlases=[tuple(r) for r in db.execute('SELECT * FROM IconTextureAtlases')]
        db.executescript(script.read_text(encoding='utf-8'))
        if script.name=='03_COVENANT_Art.sql':
            assert nonvisual_snapshot(db)==gameplay,'Art overlay changed gameplay data'
            assert [tuple(r) for r in db.execute("SELECT * FROM IconTextureAtlases WHERE Atlas NOT LIKE 'COVENANT_%'")]==native_atlases
            print('PASS art overlay changes only Covenant presentation; all gameplay tables and prior atlases preserved')
    assert tuple(db.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_COVENANT_MEMORY'").fetchone()) == (1, 0)
    assert db.execute("SELECT count(*) FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_COVENANT_MEMORY'").fetchone()[0] == 2
    sql_contracts(db)
    artwork_contracts(db)
    for table, original in before.items():
        remaining = [tuple(row) for row in db.execute('SELECT * FROM "' + table + '"') if not any(isinstance(v, str) and 'COVENANT' in v for v in row)]
        assert remaining == [tuple(row) for row in original], table
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    print('PASS actual BNW/CP schema, human-only selection, unique replacements and preserved original rows')
    print(f'COMPLETE: {count} engine groups, {ui_count} additional UI/persistence groups, package and SQL checks; native gameplay remains unverified.')

if __name__ == '__main__':
    main()
