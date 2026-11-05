"""Meaningful offline validation. Never modifies the installed game databases."""
from pathlib import Path
import hashlib
import sqlite3
import sys
import xml.etree.ElementTree as ET
import json

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

def main():
    lua = runtime()
    for file in sorted(MOD.rglob('*.lua')):
        lua.execute('return function(...)\n' + file.read_text(encoding='utf-8') + '\nend')
    print('PASS all Lua files compile under Lua 5.1')
    lua.globals().include('CovenantVerses')
    lua.globals().include('CovenantMemory')
    count = execute(lua, ROOT / 'tools/tests/covenant_engine.lua')

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
    print('PASS UI flow: study timer, keyboard capture, paste rejection, reload, rewards, exam, timer balance')
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
            assert entry.attrib['import'] == ('1' if path.suffix == '.lua' else '0')
    assert any(e.attrib['file'] == 'TheCovenant/UI/CovenantGate.xml' for e in manifest.findall('./EntryPoints/EntryPoint'))
    ET.parse(MOD / 'UI/CovenantGate.xml')
    print('PASS Covenant manifest, VFS, XML and hashes')

    from database import database
    db = database()
    before = {t: list(db.execute('SELECT * FROM "' + t + '"')) for t in ('Civilizations', 'Leaders', 'Buildings', 'Traits')}
    for script in sorted((MOD / 'SQL').glob('*.sql')):
        db.executescript(script.read_text(encoding='utf-8'))
    assert tuple(db.execute("SELECT Playable,AIPlayable FROM Civilizations WHERE Type='CIVILIZATION_COVENANT_MEMORY'").fetchone()) == (1, 0)
    assert db.execute("SELECT count(*) FROM Civilization_BuildingClassOverrides WHERE CivilizationType='CIVILIZATION_COVENANT_MEMORY'").fetchone()[0] == 2
    for table, original in before.items():
        remaining = [tuple(row) for row in db.execute('SELECT * FROM "' + table + '"') if not any(isinstance(v, str) and 'COVENANT' in v for v in row)]
        assert remaining == [tuple(row) for row in original], table
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    print('PASS actual BNW/CP schema, human-only selection, unique replacements and preserved original rows')
    print(f'COMPLETE: {count} engine groups, UI model, package and SQL checks; native gameplay remains unverified.')

if __name__ == '__main__':
    main()
