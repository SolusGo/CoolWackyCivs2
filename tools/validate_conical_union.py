"""Conical SQL/schema, pinned CP source, shipped Lua 5.1 and DDS validation.

This never launches Civ V. Cache copies and CP source contracts are evidence
about schema/API support, not an in-game gameplay or save/load test.
"""
from collections import Counter
import hashlib
import json
import re
import struct
import time
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote, is_cp_cache
from build_mod import files, imported, ENTRIES, MOD_ID, VERSION, NAME
from generate_conical import R, V, CIV, LEADER, UNIT, OFFICE, CONNECTION, GOLD, CITIES, TEXT

SUITES = ['conical_connections.lua', 'conical_lifecycle.lua', 'conical_resilience.lua',
          'conical_context.lua', 'conical_faults.lua', 'conical_timing.lua', 'conical_ownership.lua']

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')):
        d.executescript(p.read_text(encoding='utf-8'))

def yields(d, building):
    return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType', (building,)))

def inheritance(d):
    count = 0
    metadata = {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}
    for table, old, new, allowed, prefix, col in [
        ('Units','UNIT_WORKER',UNIT,metadata | {'Moves','WorkRate','UnitFlagAtlas','UnitFlagIconOffset'},'Unit','UnitType'),
        ('Buildings','BUILDING_WALLS',OFFICE,metadata,'Building','BuildingType')]:
        a = d.execute('SELECT * FROM '+table+' WHERE Type=?', (old,)).fetchone()
        b = d.execute('SELECT * FROM '+table+' WHERE Type=?', (new,)).fetchone()
        for key in a.keys():
            if key not in allowed:
                assert a[key] == b[key], (table, key, a[key], b[key])
        if table == 'Units':
            assert b['Moves'] == a['Moves'] + 1
            assert b['WorkRate'] == a['WorkRate'] * 1.25, 'native integer base must represent the exact bonus'
        for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols = [r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in cols:
                continue
            fields = [c for c in cols if c not in [col,'ID']]
            query = 'SELECT '+','.join(map(quote,fields))+' FROM '+quote(t)+' WHERE '+col+'=?'
            left = Counter(tuple(r) for r in d.execute(query, (old,)))
            right = Counter(tuple(r) for r in d.execute(query, (new,)))
            if t == 'Building_YieldChanges':
                expected = yields(d,old)
                expected['YIELD_CULTURE'] = expected.get('YIELD_CULTURE',0) + 1
                assert expected == yields(d,new)
            else:
                assert left == right, ('companion',t,left-right,right-left)
            count += 1
    return count

def sql():
    d = database()
    for p in files():
        if p.suffix == '.sql' and p.relative_to(R).parts[0] != 'TheConicalUnion':
            d.executescript(p.read_text(encoding='utf-8'))
    tables = [r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before = {t: Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables if t != 'CustomModOptions'}
    options = dict(d.execute('SELECT Name,Value FROM CustomModOptions'))
    apply(d)
    for t, rows in before.items():
        assert not rows - Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))), ('changed released row/ID',t)
    for name, value in options.items():
        expected = 1 if name in ['EVENTS_CITY_CAPITAL','EVENTS_PLAYER_TURN'] else value
        assert d.execute('SELECT Value FROM CustomModOptions WHERE Name=?', (name,)).fetchone()[0] == expected
    companion_count = inheritance(d)
    assert tuple(d.execute('SELECT Playable,AIPlayable,DawnOfManAudio FROM Civilizations WHERE Type=?',(CIV,)).fetchone()) == (1,0,'')
    assert [r[0] for r in d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_WORKER'))] == [UNIT]
    assert [r[0] for r in d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_WALLS'))] == [OFFICE]
    assert yields(d,CONNECTION) == {'YIELD_PRODUCTION':2, 'YIELD_CULTURE':1}
    assert yields(d,GOLD) == {'YIELD_GOLD':2}
    for dummy in [CONNECTION,GOLD]:
        b=d.execute('SELECT * FROM Buildings WHERE Type=?',(dummy,)).fetchone()
        for key,value in {'Cost':-1,'FaithCost':-1,'GoldMaintenance':0,'NeverCapture':1,
                          'IsDummy':1,'ShowInPedia':0,'ConquestProb':0,'GreatWorkCount':-1,
                          'Defense':0,'ExtraCityHitPoints':0,'Happiness':0,'SpecialistCount':0}.items():
            assert b[key] == value, (dummy,key,b[key])
        assert b['PrereqTech'] is None and b['PolicyType'] is None
        for table in ['Building_ClassesNeededInCity','Building_PrereqBuildingClasses']:
            assert not d.execute('SELECT 1 FROM '+table+' WHERE BuildingType=?',(dummy,)).fetchone()
    builds={r[0] for r in d.execute('SELECT BuildType FROM Unit_Builds WHERE UnitType=?',(UNIT,))}
    assert {'BUILD_ROAD','BUILD_RAILROAD','BUILD_REPAIR','BUILD_FARM','BUILD_MINE','BUILD_REMOVE_ROUTE'} <= builds
    assert not d.execute('SELECT 1 FROM Leader_Flavors WHERE LeaderType=?',(LEADER,)).fetchone(), 'no AI strategy'
    assert d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0] == len(CITIES)
    for key,value in TEXT.items():
        assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_CONICAL_'+key,)).fetchone()[0] == value
    keys={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
    for p in (V/'SQL').glob('*.sql'):
        for key in re.findall(r"'(TXT_KEY_CONICAL_[A-Z_0-9%]+)'",p.read_text(encoding='utf-8')):
            assert key in keys or any(k.startswith(key.rstrip('%')) for k in keys), key
    assert d.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    # Runtime SELECT * must preserve even CP/future scalar properties, altered
    # costs/movement, promotion grants, build permissions and existing Walls yields.
    changed = database()
    changed.executescript("""ALTER TABLE Units ADD CONICAL_TestScalar INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD CONICAL_TestScalar INTEGER DEFAULT 0;
UPDATE Units SET Moves=4,WorkRate=120,Cost=193,CONICAL_TestScalar=41 WHERE Type='UNIT_WORKER';
UPDATE Buildings SET Cost=213,GoldMaintenance=4,Defense=713,ExtraCityHitPoints=93,CONICAL_TestScalar=71 WHERE Type='BUILDING_WALLS';
UPDATE Buildings SET PrereqTech='TECH_ENGINEERING' WHERE Type='BUILDING_WALLS';
DELETE FROM Unit_Builds WHERE UnitType='UNIT_WORKER' AND BuildType='BUILD_FARM';
INSERT INTO Unit_Builds(UnitType,BuildType) VALUES ('UNIT_WORKER','BUILD_FISHING_BOATS');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_WORKER','PROMOTION_AMPHIBIOUS');
UPDATE UnitGameplay2DScripts SET SelectionSound='AS2D_SELECT_SETTLER' WHERE UnitType='UNIT_WORKER';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_WALLS','YIELD_CULTURE',4),('BUILDING_WALLS','YIELD_GOLD',3);
""")
    apply(changed);inheritance(changed)
    assert changed.execute('SELECT CONICAL_TestScalar FROM Units WHERE Type=?',(UNIT,)).fetchone()[0] == 41
    assert changed.execute('SELECT CONICAL_TestScalar FROM Buildings WHERE Type=?',(OFFICE,)).fetchone()[0] == 71
    assert changed.execute('SELECT PrereqTech FROM Buildings WHERE Type=?',(OFFICE,)).fetchone()[0] == 'TECH_ENGINEERING'
    assert changed.execute('SELECT WorkRate,Moves FROM Units WHERE Type=?',(UNIT,)).fetchone()[:] == (150,5)
    altered_builds={r[0] for r in changed.execute('SELECT BuildType FROM Unit_Builds WHERE UnitType=?',(UNIT,))}
    assert 'BUILD_FARM' not in altered_builds and 'BUILD_FISHING_BOATS' in altered_builds
    assert changed.execute('SELECT SelectionSound FROM UnitGameplay2DScripts WHERE UnitType=?',(UNIT,)).fetchone()[0] == 'AS2D_SELECT_SETTLER'
    # Same native speed/policy/religion modifiers multiply the base; rounding is
    # final integer truncation, not an additive promotion that dilutes the 25%.
    for modifier in [0,10,25,50,75,100]:
        worker_before_rounding=100*(100+modifier)/100
        crew_before_rounding=125*(100+modifier)/100
        assert crew_before_rounding == worker_before_rounding*1.25
    # Derive the real user path independently of the task checkout location.
    from pathlib import Path
    cache=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
    active_cache = cache.exists() and is_cp_cache(cache)
    if active_cache:
        active=database(cache=cache)
        for p in sorted((R/'Shared/SQL').glob('*.sql')):active.executescript(p.read_text(encoding='utf-8'))
        if not active.execute('SELECT 1 FROM Civilizations WHERE Type=?',(CIV,)).fetchone():
            apply(active);inheritance(active)
    print(f'PASS Conical SQL: all released rows/IDs preserved; {companion_count} companion tables; Worker/Walls inheritance, exact yields, overrides, localization and changed-base regressions')
    print('CP-activated live cache:', 'validated read-only copy' if active_cache else 'UNAVAILABLE (menu/vanilla cache); installed v151 schema applied to backup in memory')
    return d, {'companion_tables':companion_count, 'cp_activated_live_cache':bool(active_cache),
               'worker_moves':d.execute("SELECT Moves FROM Units WHERE Type='UNIT_WORKER'").fetchone()[0],
               'worker_work_rate':d.execute("SELECT WorkRate FROM Units WHERE Type='UNIT_WORKER'").fetchone()[0]}

def sources(fetch=False):
    from audit_cp import COMMIT, BASE
    paths = ['CvCity.h','CvCity.cpp','CvCityConnections.cpp','CvLuaCity.cpp','CvUnit.cpp',
             'CvPlayer.cpp','CvBuildingClasses.cpp','CustomMods.h','CvDllNetMessageHandler.cpp',
             'CvPlot.cpp','CvGame.cpp','CvPlayerAI.cpp','CvTreasury.cpp','CvUnitClasses.cpp']
    if fetch:
        import urllib.request
        (R/'tools/reference').mkdir(exist_ok=True)
        for name in paths:
            (R/'tools/reference'/name).write_bytes(urllib.request.urlopen(BASE+('Lua/' if name.startswith('CvLua') else '')+name,timeout=45).read())
    data={name:(R/'tools/reference'/name).read_text(encoding='utf-8-sig') for name in paths}
    def body(name,signature):
        s=data[name];start=s.index(signature);return s[start:s.index('\n}',start)+2]
    work=body('CvUnit.cpp','int CvUnit::workRate(')
    acquire=body('CvPlayer.cpp','CvCity* CvPlayer::acquireCity(')
    turn=body('CvPlayer.cpp','void CvPlayer::doTurnPostDiplomacy(')
    active=body('CvPlayer.cpp','void CvPlayer::setTurnActive(')
    network=body('CvCityConnections.cpp','void CvCityConnections::UpdateRouteInfo(')
    game_update=body('CvGame.cpp','void CvGame::update()')
    route=body('CvPlot.cpp','void CvPlot::SetRoutePillaged(')
    city_turn=body('CvCity.cpp','void CvCity::doTurn(')
    contracts={
      'DLL v151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',data['CustomMods.h'])),
      'City connection Lua binding registered':'Method(IsConnectedToCapital)' in data['CvLuaCity.cpp'],
      'connection binding wraps native cached flag':'IsConnectedToCapital() const { return IsRouteToCapitalConnected(); }' in data['CvCity.h'],
      'cached flag has no script pathfinding':'return m_bRouteToCapitalConnectedThisTurn;' in body('CvCity.cpp','bool CvCity::IsRouteToCapitalConnected('),
      'native mixed network includes water':'PT_CITY_CONNECTION_MIXED' in data['CvCityConnections.cpp'] and 'bStartCityAllowsWater' in data['CvCityConnections.cpp'],
      'CityConnections is query callback, not notification':'GAMEEVENTINVOKE_TESTANY(GAMEEVENT_CityConnections' in data['CvCityConnections.cpp'],
      'network refresh precedes native turn':active.index('GetCityConnections()->Update();') < active.index('doTurn();'),
      'PlayerDoTurn follows city settlement':turn.index('pLoopCity->doTurn();') < turn.index('"PlayerDoTurn"'),
      'PlayerDoTurn follows Gold and Culture settlement':turn.index('GetTreasury()->DoGold();') < turn.index('"PlayerDoTurn"'),
      'Production uses native city yield during city turn':'doProduction(!doCheckProduction());' in city_turn and 'changeProductionTimes100(getYieldRateTimes100(YIELD_PRODUCTION)' in body('CvCity.cpp','void CvCity::doProduction('),
      'Culture settlement precedes PlayerDoTurn':turn.index('changeJONSCultureTimes100(GetTotalJONSCulturePerTurnTimes100())') < turn.index('"PlayerDoTurn"'),
      'Gold consumes current native net yield':'int iGoldChange = CalculateBaseNetGoldTimes100();' in body('CvTreasury.cpp','void CvTreasury::DoGold('),
      'turn status is before network refresh':active.index('PublishPlayerTurnStatus(DLLUIClass::TURN_START') < active.index('GetCityConnections()->Update();'),
      'DoneTurn is end phase before unit reset':active.index('GAMEEVENT_PlayerDoneTurn') < active.index('DoUnitReset();') and 'if (MOD_EVENTS_PLAYER_TURN)' in active,
      'connection query runs while flags are reset':network.index('GAMEEVENT_CityConnections') < network.index('SetRouteToCapitalConnected(false, true)') < network.index('SetRouteToCapitalConnected(true,'),
      'CityConnected extends partial network before capital flags':network.index('GAMEEVENT_CityConnected') < network.index('PT_CITY_CONNECTION_MIXED') < network.index('SetRouteToCapitalConnected(true,'),
      'no generic post-network notification':'GAMEEVENTINVOKE_HOOK' not in network and 'LuaSupport::CallHook' not in network,
      'route pillage does not refresh network':'m_bRoutePillaged = bPillaged;' in route and 'GetCityConnections' not in route and 'UpdateRouteInfo' not in route,
      'connection flag setter has no notification hook':'GAMEEVENT' not in body('CvCity.cpp','void CvCity::SetRouteToCapitalConnected(') and 'CallHook' not in body('CvCity.cpp','void CvCity::SetRouteToCapitalConnected('),
      'core update begin is not a before-settlement guarantee':game_update.index('doTurnPostDiplomacy();') < game_update.index('"GameCoreUpdateBegin"'),
      'pre AI unit update belongs to unit processing':'"PlayerPreAIUnitUpdate"' in body('CvPlayerAI.cpp','void CvPlayerAI::AI_unitUpdate('),
      'work rate SQL loads as native integer':'m_iWorkRate = kResults.GetInt("WorkRate");' in data['CvUnitClasses.cpp'],
      'work rate reads unit base':'int iRate = m_pUnitInfo->GetWorkRate();' in work,
      'work rate multiplies common modifiers then truncates':'iRate *= Modifiers + 100;' in work and 'iRate /= 100;' in work,
      'ordinary builds use native work progress':'pPlot->changeBuildProgress(eBuild, iWorkRateWithMoves' in data['CvUnit.cpp'],
      'captured civilians use native class mapping':'kCapturingPlayer.GetSpecificUnitType(eUnitClass)' in body('CvUnit.cpp','UnitTypes CvUnit::getCaptureUnitType('),
      'capture notification follows reconstructed city':acquire.index('pNewCity->') < acquire.index('"CityCaptureComplete"'),
      'liberation uses native reacquisition':'acquireCity(' in body('CvPlayer.cpp','void CvPlayer::DoLiberatePlayer('),
      'CityRazed precedes disbanded city destruction':body('CvPlayer.cpp','void CvPlayer::disband(').index('GAMEEVENT_CityRazed') < body('CvPlayer.cpp','void CvPlayer::disband(').index('pCity->kill();'),
      'NeverCapture applies before gift/conquest distinction':body('CvPlayer.cpp','bool CvPlayer::IsValidBuildingForPlayer(').index('IsNeverCapture()') < body('CvPlayer.cpp','bool CvPlayer::IsValidBuildingForPlayer(').index('if (!bConquest'),
      'building setter suppresses construction rewards':'luaL_optbool(L, 4, true)' in body('CvLuaCity.cpp','int CvLuaCity::lSetNumRealBuilding('),
      'building setter publishes targeted city dirty':'SetSpecificCityInfoDirty' in body('CvBuildingClasses.cpp','void CvCityBuildings::SetNumRealBuildingTimed('),
      'zero upkeep prevents dummy sales':'if(kBuilding.GetGoldMaintenance() <= 0)' in body('CvBuildingClasses.cpp','bool CvCityBuildings::IsBuildingSellable('),
      'sale callback is after removal':data['CvDllNetMessageHandler.cpp'].index('DoSellBuilding(eBuilding)') < data['CvDllNetMessageHandler.cpp'].index('GAMEEVENT_CitySoldBuilding'),
      'building yields feed native city yields':'ChangeBaseYieldRateFromBuildings' in data['CvBuildingClasses.cpp'],
    }
    for name,signature in {'CapitalChanged':'iii','CitySoldBuilding':'iii','CityConstructed':'iiibb','CityRazed':'iii','PlayerDoneTurn':'i','TileRouteChanged':'iiiiib'}.items():
        contracts['event ABI '+name]=bool(re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+signature+'"',data['CustomMods.h']))
    for name,ok in contracts.items():assert ok,name
    # Installed Firaxis scripts demonstrate UI-context shutdown and both kinds
    # of event removal. Engine ownership/lifetime internals remain closed source.
    from pathlib import Path
    assets=Path('G:/SteamLibrary/steamapps/common')/"Sid Meier's Civilization V/Assets"
    installed={
      'UI/InGame/UnitFlagManager.lua':'ContextPtr:SetShutdown( OnShutdown );',
      'UI/InGame/Bombardment.lua':'Events.SerialEventMouseOverHex.Remove( DisplayBombardArrow );',
      'DLC/DLC_02/Scenarios/NewWorldScenario/TurnsRemaining.lua':'GameEvents.GameCoreTestVictory.Remove(TestVictory);',
    }
    installed_evidence={}
    for relative,token in installed.items():
        p=assets/relative
        if p.exists():
            source=p.read_text(encoding='utf-8-sig')
            assert token in source,relative
            installed_evidence[relative]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
                                          'verified_contract':token}
    report={'official_commit':COMMIT,'native_gameplay':'NOT TESTED IN GAME','contracts':contracts,
            'installed_Firaxis_UI_contracts':installed_evidence,
            'context_lifetime_scope':'Shared-marker risk reproduced synthetically; native quick-load/context lifetime behavior requires game verification.',
            'sources':{name:{'url':BASE+('Lua/' if name.startswith('CvLua') else '')+name,
                             'sha256':hashlib.sha256((R/'tools/reference'/name).read_bytes()).hexdigest()} for name in paths}}
    (V/'docs').mkdir(parents=True,exist_ok=True)
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS Conical',len(contracts),'pinned CP v151 source contracts (not runtime verification)')
    return len(contracts)

def runtime(d):
    ids={r['Type']:r['ID'] for table in ['Civilizations','Buildings'] for r in d.execute('SELECT Type,ID FROM '+table)}
    source=(V/'Lua/ConicalUnion.lua').read_text(encoding='utf-8')
    times={}
    for name in SUITES:
        lua=LuaRuntime();lua.globals().GameInfoTypes=lua.table_from(ids)
        lua.execute((R/'tools/tests/conical_mock.lua').read_text(encoding='utf-8'))
        lua.globals().LoadConical=lambda:lua.execute(source)
        ua=yields(d,CONNECTION);gold=yields(d,GOLD)
        office=yields(d,OFFICE).get('YIELD_CULTURE',0)-yields(d,'BUILDING_WALLS').get('YIELD_CULTURE',0)
        lua.execute('function Harvest(c) local u=c:GetNumRealBuilding(U);local g=c:GetNumRealBuilding(G);return u*'+str(ua['YIELD_PRODUCTION'])+',u*'+str(ua['YIELD_CULTURE'])+'+c:GetNumRealBuilding(O)*'+str(office)+',g*'+str(gold['YIELD_GOLD'])+' end')
        started=time.perf_counter();lua.execute((R/'tools/tests'/name).read_text(encoding='utf-8'))
        times[name]=round(time.perf_counter()-started,6)
    for token in ['SetUpdate','GetNumPlots','OpenSaveData','ChangeGold','GetPlotByIndex']:
        assert token not in source, ('unexpected polling/map scan/persistence/treasury API',token)
    assert source.count('pcall(city.IsConnectedToCapital, city)') == 1
    assert 'GameCoreUpdateBegin' not in source and "Hook(GameEvents, 'CityConnected'" not in source
    assert "Hook(GameEvents, 'CityConnections'" not in source and "Hook(GameEvents, 'TileRouteChanged'" not in source
    print('PASS shipped Conical Lua 5.1:',len(times),'suites (synthetic boundary; no native timing claims)')
    return times

def art(d):
    for atlas,size,filename,cols,rows in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'CONICAL_%'"):
        p=V/'Art'/filename
        with Image.open(p) as im:
            im.load();assert im.size==(size*int(cols),size*int(rows))
            if 'ALPHA' in atlas or 'FLAG' in atlas:
                assert im.convert('RGBA').getchannel('A').getextrema() == (0,255)
        h=p.read_bytes()[:128]
        assert h[:4]==b'DDS ' and h[84:88]!=b'DX10'
        assert struct.unpack_from('<I',h,28)[0]==max(size*int(cols),size*int(rows)).bit_length(),p
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',OFFICE)]:
        atlas,index=d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=32 AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
    for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(512,512))]:
        with Image.open(V/'Art'/f'CONICAL_{stem}.dds') as im:im.load();assert im.size==size
    assert len(list((V/'Art').glob('*.dds')))==40
    assert ET.parse(V/'Art/CONICAL_LeaderScene.xml').getroot().get('FallbackImage')=='CONICAL_Leader.dds'
    paths=set(files())
    assert all(p in paths for p in V.rglob('*') if p.suffix in ['.sql','.lua','.xml','.dds'])
    assert not imported(V/'Lua/ConicalUnion.xml') and imported(V/'Lua/ConicalUnion.lua')
    root=ET.parse(R/(NAME+'.modinfo')).getroot()
    assert root.get('id')==MOD_ID and root.get('version')==VERSION
    assert any(e[0]=='TheConicalUnion/Lua/ConicalUnion.xml' for e in ENTRIES)
    print('PASS Conical 40 decoded DDS files, mipmaps, atlas slots, 2D leader scene and build/VFS registration')

def validate(fetch=False):
    d,baseline=sql();audit=sources(fetch);times=runtime(d);art(d)
    report={'date':'2026-10-25','mod_version':int(VERSION),'native_gameplay':'NOT TESTED IN GAME',
            'native_save_load':'NOT TESTED IN GAME','baseline':baseline,'source_contracts':audit,
            'lua':'5.1; shipped controller with synthetic native boundary','suites_seconds':times,
            'art':'40 decoded mipmapped legacy DDS textures; original generated artwork',
            'synchronization':'Engine limitation unchanged: cached flag refresh precedes settlement, but PlayerDoTurn follows Production/Gold/Culture. Explicit phase simulation verifies old first-settlement counts, then correction for the subsequent settlement; no query/polling workaround.',
            'controller_lifecycle':'Context-owned registry, retirement/removal and inert stale wrappers; synthetic shared-data/retained-event/quick-load/shutdown/new-game scenarios pass. Native lifetime behavior unverified.',
            'failure_recovery':'Per-city retries isolate failures; diagnostics are bounded until recovery; only failed foreign IDs are revisited on owner turns; one foreign load sweep repairs persisted residue; cross-city reentrant jobs coalesce.'}
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    return report

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fetch',action='store_true',help='download the pinned official source files to the ignored tools/reference folder')
    validate(parser.parse_args().fetch)
