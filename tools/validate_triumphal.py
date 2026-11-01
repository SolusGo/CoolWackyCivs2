"""Read-only database/source audit and actual shipped Lua 5.1 contract tests.

These are static and mocked tests, never evidence of native Civ V execution.
"""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,json,math,re,struct
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from generate_triumphal import R,V,CIV,LEADER,UNIT,HALL,TEXT
from validation_prerequisites import inspect_database,require_sources,CP_COMMIT

def activate(d):
    for p in sorted((V/'SQL').glob('*.sql')):d.executescript(p.read_text(encoding='utf-8'))

def inheritance(d):
    for table,old,new in [('Units','UNIT_SWORDSMAN',UNIT),('Buildings','BUILDING_BARRACKS',HALL)]:
        allowed={'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}
        before=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        after=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for field in before.keys():
            if field not in allowed:assert before[field]==after[field],(table,field)
        prefix,key=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or key not in cols:continue
            cols=[c for c in cols if c not in (key,'ID')]
            query='SELECT '+','.join(map(quote,cols))+' FROM '+quote(t)+' WHERE '+quote(key)+'=?'
            a=Counter(tuple(r) for r in d.execute(query,(old,)))
            b=Counter(tuple(r) for r in d.execute(query,(new,)))
            if t=='Unit_FreePromotions':b.subtract({('PROMOTION_TRI_UNBROKEN_ADVANCE',):1});b=+b
            if t=='Building_YieldChanges':
                culture=next((r for r in a if r[0]=='YIELD_CULTURE'),('YIELD_CULTURE',0))
                if culture in a:del a[culture]
                a[(culture[0],culture[1]+1)]=1
            assert a==b,(t,a-b,b-a)

def sql():
    from build_mod import files
    d=database()
    for path in files():
        if path.suffix=='.sql' and path.relative_to(R).parts[0]!='TheTriumphalImperium':d.executescript(path.read_text(encoding='utf-8'))
    tables=[t for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    old={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables}
    activate(d)
    for t,rows in old.items():
        if t!='CustomModOptions':assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('unrelated content modified',t)
    inheritance(d)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    assert tuple(d.execute('SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,)).fetchone())==('UNITCLASS_SWORDSMAN',UNIT)
    assert tuple(d.execute('SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?',(CIV,)).fetchone())==('BUILDINGCLASS_BARRACKS',HALL)
    assert len(d.execute('SELECT * FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchall())>=20
    adv=d.execute("SELECT * FROM UnitPromotions WHERE Type='PROMOTION_TRI_UNBROKEN_ADVANCE'").fetchone()
    assert (adv['AttackMod'],adv['DefenseMod'],adv['LostWithUpgrade'],adv['CannotBeChosen'])==(10,0,0,1)
    for i in range(1,7):
        p=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',('PROMOTION_TRI_MOMENTUM_'+str(i),)).fetchone()
        assert (p['CombatPercent'],p['MovesChange'],p['LostWithUpgrade'],p['LostOnGifting'],p['CannotBeChosen'])==(2*i,0,1,1,1)
        b=d.execute('SELECT * FROM Buildings WHERE Type=?',('BUILDING_TRI_MOBILISATION_'+str(i),)).fetchone()
        assert (b['MilitaryProductionModifier'],b['Cost'],b['IsDummy'],b['ShowInPedia'],b['NeverCapture'],b['ConquestProb'])==(i*4,-1,1,0,1,0)
    assert d.execute("SELECT MilitaryProductionModifier FROM Buildings WHERE Type='BUILDING_TRI_MOBILISATION_HALL_ACTIVE'").fetchone()[0]==10
    for table in ['Civilizations','Leaders','Units','Buildings','UnitPromotions','BuildingClasses','Traits']:
        assert not d.execute('SELECT Type,COUNT(*) FROM '+table+' GROUP BY Type HAVING COUNT(*)>1').fetchall(),table
    for key,value in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_TRI_'+key,)).fetchone()[0]==value
    for path in (V/'SQL').glob('*.sql'):
        for tag in re.findall(r"'(TXT_KEY_TRI_[A-Z0-9_]+)'",path.read_text(encoding='utf-8')):
            if tag in ('TXT_KEY_TRI_CIV5','TXT_KEY_TRI_AURELION'):continue
            assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(tag,)).fetchone(),tag
    for table in ['Units','Buildings','UnitPromotions','Civilizations','Leaders']:
        for row in d.execute('SELECT * FROM '+table):
            if not (row['Type'].startswith(('UNIT_TRI_','BUILDING_TRI_','PROMOTION_TRI_','CIVILIZATION_TRIUMPHAL_','LEADER_TRI_'))):continue
            assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(row['IconAtlas'],row['PortraitIndex'])).fetchone(),row['Type']
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    altered=database()
    altered.execute("UPDATE Units SET Combat=29,Cost=137,Moves=3 WHERE Type='UNIT_SWORDSMAN'")
    altered.execute("UPDATE Buildings SET Cost=159,GoldMaintenance=4 WHERE Type='BUILDING_BARRACKS'")
    activate(altered);inheritance(altered)
    standalone=database()
    for optional in ('Leader_SharedTraits','Building_JFD_District','Building_ConstructionAudio'):
        standalone.execute('DROP TABLE IF EXISTS '+quote(optional))
    standalone.executescript((R/'Shared/SQL/00_OptionalCompatibility.sql').read_text(encoding='utf-8'))
    activate(standalone);inheritance(standalone)
    print('PASS SQL: full collection activation, isolation, active base/companion inheritance, exact modifiers, replacements and text')
    return d

def source():
    names=['CustomMods.h','CvUnit.cpp','CvPlayer.cpp','CvCity.cpp','CvUnitCombat.cpp','CvGameCoreStructs.cpp','CvLuaUnit.cpp','CvLuaPlayer.cpp','CvLuaPlot.cpp','CvPlot.cpp','CvDllNetMessageHandler.cpp']
    pin=require_sources(names)
    s={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    def body(file,start):
        i=s[file].index(start);return s[file][i:s[file].index('\n}',i)+2]
    kill=body('CvPlayer.cpp','void CvPlayer::DoUnitKilledCombat(')
    assert all(x in kill for x in ['args->Push(GetID())','args->Push(eKilledPlayer)','args->Push(eUnitType)','pKillingUnit ? pKillingUnit->GetID() : -1'])
    damage=body('CvUnit.cpp','int CvUnit::setDamage(')
    assert damage.index('kill(true, ePlayer)')<damage.index('DoUnitKilledCombat(NULL')
    prekill=body('CvUnit.cpp','void CvUnit::kill(')
    assert prekill.index('GAMEEVENT_UnitPrekill')<prekill.index('startDelayedDeath()')
    assert 'BATTLE_JOINED(unit, unitType, false)' in body('CvGameCoreStructs.cpp','void CvCombatInfo::setUnit(')
    assert 'BATTLE_JOINED(pkCity, unitType, true)' in body('CvGameCoreStructs.cpp','void CvCombatInfo::setCity(')
    assert all('BATTLE_FINISHED()' in body('CvUnitCombat.cpp',signature) for signature in [
        'void CvUnitCombat::ResolveMeleeCombat(', 'void CvUnitCombat::ResolveRangedUnitVsCombat(',
        'void CvUnitCombat::ResolveRangedCityVsUnitCombat(', 'void CvUnitCombat::ResolveAirUnitVsCombat(',
        'void CvUnitCombat::ResolveAirSweep('])
    assert 'pkUnitInfo->IsMilitaryProduction()' in s['CvCity.cpp'] and 'iTempMod = getMilitaryProductionModifier()' in s['CvCity.cpp']
    assert 'changeMilitaryProductionModifier(pBuildingInfo->GetMilitaryProductionModifier() * iChange)' in s['CvCity.cpp']
    moves=body('CvUnit.cpp','void CvUnit::changeExtraMoves(')
    assert 'm_iExtraMoves += iChange' in moves and 'setMoves' not in moves
    convert=body('CvUnit.cpp','void CvUnit::convert(')
    assert '!pkPromotionInfo->IsLostWithUpgrade()' in convert and 'GAMEEVENT_UnitConverted' in convert
    assert convert.index('setMoves(pUnit->getMoves())')<convert.index('GAMEEVENT_UnitConverted')<convert.index('pUnit->kill(true')
    assert 'visitor(player.m_strScriptData)' in s['CvPlayer.cpp']
    assert 'scriptData.assign(plot.m_szScriptData)' in s['CvPlot.cpp']
    assert 'visitor(unit.m_strScriptData)' in s['CvUnit.cpp']
    sale=body('CvDllNetMessageHandler.cpp','void CvDllNetMessageHandler::ResponseSellBuilding(')
    assert sale.index('DoSellBuilding(eBuilding)')<sale.index('GAMEEVENT_CitySoldBuilding')
    assert 'pkUnit->changeDamage(kEntry.GetDamage(), eAttackerOwner)' in s['CvUnitCombat.cpp']
    print('PASS pinned CP151 source contracts: kill identity/order, battle membership, native military industry, movement and upgrades')
    return pin

def runtime(d):
    results=[]
    # Decay is per player-turn cycle, deliberately identical on every game speed.
    for speed in ['GAMESPEED_QUICK','GAMESPEED_STANDARD','GAMESPEED_EPIC','GAMESPEED_MARATHON']:
        lua=LuaRuntime(unpack_returned_tuples=True)
        tables={};types={}
        for t in ['Units','Buildings','UnitPromotions','Technologies','Civilizations']:
            rows={}
            for r in d.execute('SELECT * FROM '+t):
                row=dict(r);rows[row['ID']]=row;types[row['Type']]=row['ID']
            tables[t]=rows
        lua.globals().GameInfo=lua.table_from(tables,recursive=True)
        lua.globals().GameInfoTypes=lua.table_from(types)
        lua.globals().TEXT=lua.table_from({'TXT_KEY_TRI_'+k:v for k,v in TEXT.items()})
        lua.globals().SPEED=speed
        lua.execute((R/'tools/tests/triumphal_mock.lua').read_text(encoding='utf-8'))
        def include(name):
            path=V/'Lua'/(name+'.lua')
            lua.execute(path.read_text(encoding='utf-8'))
        def panel():lua.execute((V/'UI/TRI_Panel.lua').read_text(encoding='utf-8'))
        lua.globals().include=include;lua.globals().LoadPanel=panel
        panel()
        lua.execute((R/'tools/tests/triumphal_cases.lua').read_text(encoding='utf-8'))
        results.append({'speed':speed,'assertions':lua.globals().CHECK_COUNT})
        print('PASS shipped Lua 5.1 contracts:',speed,lua.globals().CHECK_COUNT,'assertions (mock)')
    return results

def assets(d):
    for path in V.rglob('*.xml'):ET.parse(path)
    lua=LuaRuntime();compile=lua.eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
    for path in V.rglob('*.lua'):compile(path.read_text(encoding='utf-8'),str(path))
    textures=list((V/'Art').glob('*.dds'))
    for path in textures:
        raw=path.read_bytes();assert raw[:4]==b'DDS '
        with Image.open(path) as im:
            im.load();assert struct.unpack_from('<I',raw,28)[0]==math.floor(math.log2(max(im.size)))+1
    for r in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'TRI_%'"):
        with Image.open(V/'Art'/r['Filename']) as im:assert im.size==(r['IconSize']*int(r['IconsPerRow']),r['IconSize']*int(r['IconsPerColumn'])),r['Filename']
    assert len(textures)==40
    print('PASS XML/Lua syntax, 40 decoded full-mip DDS textures and atlas references')

def validate():
    report={'database':inspect_database(),'source_pin':source(),'in_game':'NOT RUN'}
    d=sql();report['lua_contracts']=runtime(d);assets(d)
    report['result']='PASS static/database/Lua-mock validation; native gameplay/rendering acceptance outstanding'
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return report

if __name__=='__main__':validate()
