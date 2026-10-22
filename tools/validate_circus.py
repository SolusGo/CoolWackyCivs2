"""Actual-schema SQL, pinned CP source, DDS and shipped Lua 5.1 simulations."""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, json, re, sqlite3, sys, urllib.request
from lupa.lua51 import LuaRuntime
from PIL import Image
from database import database, quote
from generate_circus import R,V,CIV,LEADER,UNIT,OFFICE,DUMMIES,TEXT,CITIES
from validate_twelfth import inherited

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')): d.executescript(p.read_text(encoding='utf-8'))

UNIT_ALLOWED={'ID','Type','Moves','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}
BUILDING_ALLOWED={'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}

def culture(d,building):
    return d.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_CULTURE'",(building,)).fetchone()[0]

def check_inheritance(d):
    inherited(d,'Units','UNIT_WORKER',UNIT,UNIT_ALLOWED)
    inherited(d,'Buildings','BUILDING_MARKET',OFFICE,BUILDING_ALLOWED)
    a=d.execute('SELECT * FROM Units WHERE Type=?',('UNIT_WORKER',)).fetchone()
    b=d.execute('SELECT * FROM Units WHERE Type=?',(UNIT,)).fetchone()
    assert b['Moves']==a['Moves']+1 and b['WorkRate']==a['WorkRate'] and b['Combat']==a['Combat']
    assert culture(d,OFFICE)==culture(d,'BUILDING_MARKET')+1
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)

def sql():
    d=database()
    # Apply the complete previously released SQL inventory first. Snapshot EVERY row.
    from build_mod import files
    for p in files():
        if p.suffix=='.sql' and V not in p.parents: d.executescript(p.read_text(encoding='utf-8'))
    tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before={t:Counter(tuple(row) for row in d.execute('SELECT * FROM '+quote(t))) for t in tables if t!='CustomModOptions'}
    apply(d);check_inheritance(d)
    for t,rows in before.items():
        assert not rows-Counter(tuple(row) for row in d.execute('SELECT * FROM '+quote(t))),('changed existing gameplay',t)
    assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_WORKER')).fetchone()[0]==UNIT
    assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_MARKET')).fetchone()[0]==OFFICE
    assert [r[0] for r in d.execute('SELECT CityName FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,))]==[f'TXT_KEY_WCIRCUS_CITY_{i}' for i in range(1,25)]
    assert d.execute('SELECT COUNT(*) FROM Civilization_SpyNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]==10
    assert d.execute("SELECT COUNT(*) FROM Civilization_FreeUnits WHERE CivilizationType=? AND UnitClassType='UNITCLASS_SETTLER' AND Count=1",(CIV,)).fetchone()[0]==1
    assert dict(d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_WCIRCUS_FESTIVAL_YIELDS'"))=={'YIELD_CULTURE':3,'YIELD_GOLD':2}
    assert dict(d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_WCIRCUS_TICKET_PRODUCTION'"))=={'YIELD_PRODUCTION':2}
    for suffix in DUMMIES:
        typ='BUILDING_WCIRCUS_'+suffix
        row=d.execute('SELECT * FROM Buildings WHERE Type=?',(typ,)).fetchone()
        assert tuple(row[k] for k in ['Cost','FaithCost','GreatWorkCount','NeverCapture','IsDummy','ShowInPedia','ConquestProb','GoldMaintenance'])==(-1,-1,-1,1,1,0,0,0)
        assert row['PrereqTech'] is None and row['ObsoleteTech'] is None
        if suffix not in DUMMIES[:2]:
            for (table,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'Building_%'").fetchall():
                if 'BuildingType' in [r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')]:
                    assert not d.execute('SELECT 1 FROM '+quote(table)+' WHERE BuildingType=?',(typ,)).fetchone(),('marker has companion effects',table)
    for key,value in TEXT.items(): assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_WCIRCUS_'+key,)).fetchone()[0]==value
    refs=set(re.findall(r"['\"](TXT_KEY_WCIRCUS_[A-Z_0-9%]+)['\"]",'\n'.join(p.read_text(encoding='utf-8') for p in V.rglob('*') if p.suffix in ['.sql','.lua'])))
    for key in refs-{'TXT_KEY_WCIRCUS_CIV5','TXT_KEY_WCIRCUS_AURELIO'}:
        assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(key,)).fetchone(),key
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    # Activation-time scalar SELECT * must retain even columns added after generation.
    changed=database();changed.executescript("ALTER TABLE Units ADD WCIRCUS_TestScalar INTEGER DEFAULT 0; ALTER TABLE Buildings ADD WCIRCUS_TestScalar INTEGER DEFAULT 0; UPDATE Units SET Moves=5,WorkRate=147,WCIRCUS_TestScalar=37 WHERE Type='UNIT_WORKER'; UPDATE Buildings SET Cost=191,GoldMaintenance=3,SpecialistCount=2,WCIRCUS_TestScalar=73 WHERE Type='BUILDING_MARKET'; DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_MARKET' AND YieldType='YIELD_CULTURE'; INSERT INTO Building_YieldChanges VALUES ('BUILDING_MARKET','YIELD_CULTURE',4);")
    apply(changed);check_inheritance(changed)
    assert tuple(changed.execute('SELECT Moves,WorkRate,WCIRCUS_TestScalar FROM Units WHERE Type=?',(UNIT,)).fetchone())==(6,147,37)
    assert tuple(changed.execute('SELECT Cost,GoldMaintenance,SpecialistCount,WCIRCUS_TestScalar FROM Buildings WHERE Type=?',(OFFICE,)).fetchone())==(191,3,2,73)
    assert culture(changed,OFFICE)==5
    # The current actual game cache is a second, independently populated CP baseline.
    cache=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
    if cache.exists():
        source=sqlite3.connect(cache.resolve().as_uri()+'?mode=ro',uri=True);active=sqlite3.connect(':memory:');source.backup(active);source.close()
        active.row_factory=sqlite3.Row
        active.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
        if not active.execute('SELECT 1 FROM Civilizations WHERE Type=?',(CIV,)).fetchone():
            apply(active);check_inheritance(active)
            print('PASS Circus activation on read-only copy of actual active CP cache')
        else: print('SKIP active-cache activation: Circus already present')
    print('PASS Circus actual-schema SQL: all six prior civilizations preserved, complete Worker/Market inheritance, additive Culture, exact yields and localization')
    return d

def art(d):
    for atlas,size,filename,cols,rows in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'WCIRCUS_%'"):
        with Image.open(V/'Art'/filename) as im: im.load();assert im.size==(size*int(cols),size*int(rows)),filename
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',OFFICE)]:
        row=d.execute('SELECT * FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(row['IconAtlas'],row['PortraitIndex'])).fetchone()
    row=d.execute('SELECT UnitFlagAtlas,UnitFlagIconOffset FROM Units WHERE Type=?',(UNIT,)).fetchone()
    assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=32 AND IconsPerRow*IconsPerColumn>?',tuple(row)).fetchone()
    assert ET.parse(V/'Art/WCIRCUS_LeaderScene.xml').getroot().get('FallbackImage')=='WCIRCUS_Leader.dds'
    for stem in ['Leader','Dawn','Map']:
        with Image.open(V/'Art'/f'WCIRCUS_{stem}.dds') as im: im.load()
    print('PASS Circus 40 DDS textures, atlas dimensions/indices, flag and static leader paths')

def gameplay(d):
    values=dict(d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_WCIRCUS_FESTIVAL_YIELDS'"))
    prod=d.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_WCIRCUS_TICKET_PRODUCTION'").fetchone()[0]
    officeCulture=culture(d,OFFICE)-culture(d,'BUILDING_MARKET')
    source=(V/'UI/WanderingCircus.lua').read_text(encoding='utf-8')
    for speed in ['QUICK','STANDARD','EPIC','MARATHON','CUSTOM']:
        for start in [0,150]:
            for name in ['circus_timing.lua','circus_lifecycle.lua','circus_persistence.lua']:
                lua=LuaRuntime()
                if (speed,start)!=('QUICK',0): lua.globals().print=lambda *args:None
                lua.execute((R/'tools/tests/circus_mock.lua').read_text(encoding='utf-8'))
                lua.globals().startTurn=start
                lua.globals().Game.GetGameSpeedType=lambda:speed
                lua.globals().LoadCircus=lambda:lua.execute(source)
                lua.execute('function Harvest(c) return (c.b[103] or 0)*'+str(values['YIELD_CULTURE'])+'+((c.b[102] or 0)>0 and '+str(officeCulture)+' or 0), (c.b[103] or 0)*'+str(values['YIELD_GOLD'])+', (c.b[104] or 0)*'+str(prod)+' end')
                lua.execute((R/'tools/tests'/name).read_text(encoding='utf-8'))
    print('PASS 30 Circus shipped-Lua 5.1 suite runs: 3 suites x 5 speeds x 2 start turns; simulations, NOT native engine tests')

def sources(fetch=False):
    from audit_cp import COMMIT,BASE
    names=['CustomMods.h','CvPlayer.cpp','CvCity.cpp','CvUnit.cpp','CvBuildingClasses.cpp','CvGame.cpp','CvDllNetMessageHandler.cpp','CvLuaCity.cpp','CvLuaUnit.cpp','CvLuaPlot.cpp']
    if fetch:
        for name in names:
            (R/'tools/reference'/name).write_bytes(urllib.request.urlopen(BASE+('Lua/' if name.startswith('CvLua') else '')+name,timeout=45).read())
    data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    def body(n,sig):
        s=data[n];i=s.index(sig);return s[i:s.index('\n}',i)+2]
    turn=body('CvPlayer.cpp','void CvPlayer::doTurnPostDiplomacy(')
    phase=body('CvPlayer.cpp','void CvPlayer::setTurnActive(')
    acquire=body('CvPlayer.cpp','CvCity* CvPlayer::acquireCity(')
    valid=body('CvPlayer.cpp','bool CvPlayer::IsValidBuildingForPlayer(')
    setter=body('CvBuildingClasses.cpp','void CvCityBuildings::SetNumRealBuildingTimed(')
    checks={
      'DLL v151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',data['CustomMods.h'])),
      'city economics then gold then culture then PlayerDoTurn':turn.index('pLoopCity->doTurn();')<turn.index('GetTreasury()->DoGold();')<turn.index('changeJONSCultureTimes100(')<turn.index('"PlayerDoTurn"'),
      'done before native unit reset':phase.index('GAMEEVENT_PlayerDoneTurn')<phase.index('DoUnitReset();'),
      'done after completed automoves':all(s in body('CvGame.cpp','void CvGame::CheckPlayerTurnDeactivate(') for s in ['kPlayer.isEndTurn()','kPlayer.hasProcessedAutoMoves()','kPlayer.setTurnActive(false)']),
      'done hook gated by enabled option':'if (MOD_EVENTS_PLAYER_TURN)' in phase,
      'done ABI':bool(re.search(r'GAMEEVENT_PlayerDoneTurn\s+"PlayerDoneTurn",\s+"i"',data['CustomMods.h'])),
      'raw turn advances once':'setGameTurn(getGameTurn() + 1);' in body('CvGame.cpp','void CvGame::incrementGameTurn('),
      'native int real counts not capped':'m_paiNumRealBuilding[eIndex] = iNewValue;' in setter,
      'native getter does not cap counts':'std::max(GetNumRealBuilding(eIndex), GetNumFreeBuilding(eIndex))' in body('CvBuildingClasses.cpp','int CvCityBuildings::GetNumBuilding('),
      'real counts serialized':'visitor(MakeConstSpan(cityBuildings.m_paiNumRealBuilding, iNumBuildings));' in data['CvBuildingClasses.cpp'],
      'dummy excluded from normal building totals':'if(!buildingEntry->IsDummy())' in setter,
      'set real supports no construction rewards':'const bool bNoBonus = luaL_optbool(L, 4, true)' in data['CvLuaCity.cpp'],
      'real setter processes native yields':'m_pCity->processBuilding(eIndex, iChangeNumRealBuilding' in setter,
      'flat yields enter native base':'GetBaseYieldRateFromBuildings(eYield) * 100' in body('CvCity.cpp','int CvCity::getBaseYieldRateTimes100('),
      'NeverCapture applies before nonconquest exception':valid.index('pkBuildingInfo->IsNeverCapture()')<valid.index('if (!bConquest'),
      'acquisition validates transferred buildings':'IsValidBuildingForPlayer(pNewCity, eBuilding, (bConquest && !bGift))' in acquire,
      'capture callback follows building reconstruction':acquire.index('SetNumRealBuildingTimed(')<acquire.index('"CityCaptureComplete"'),
      'capture new owner fifth argument':bool(re.search(r'args->Push\(eOldOwner\);\s*args->Push\(bCapital\);\s*args->Push\(iCityX\);\s*args->Push\(iCityY\);\s*args->Push\(GetID\(\)\);',acquire)),
      'city constructed after creation':body('CvCity.cpp','void CvCity::produce(BuildingTypes').index('CreateBuilding(eConstructBuilding)')<body('CvCity.cpp','void CvCity::produce(BuildingTypes').index('GAMEEVENT_CityConstructed'),
      'sale hook after removal':body('CvDllNetMessageHandler.cpp','void CvDllNetMessageHandler::ResponseSellBuilding(').index('DoSellBuilding(eBuilding)')<body('CvDllNetMessageHandler.cpp','void CvDllNetMessageHandler::ResponseSellBuilding(').index('GAMEEVENT_CitySoldBuilding'),
      'prekill ABI':bool(re.search(r'GAMEEVENT_UnitPrekill\s+"UnitPrekill",\s+"iiiiibi"',data['CustomMods.h'])),
      'prekill passes dying identity':'GAMEEVENT_UnitPrekill, eUnitOwner, GetID(), getUnitType(), getX(), getY(), bDelay, ePlayer' in data['CvUnit.cpp'],
      'relocation hook exists':'"UnitSetXY"' in data['CvUnit.cpp'],
      'city center unit iteration bindings':all('Method('+s+');' in data['CvLuaPlot.cpp'] for s in ['GetNumUnits','GetUnit','GetPlotCity']),
      'captured worker resolves captor replacement':'return kCapturingPlayer.GetSpecificUnitType(eUnitClass);' in body('CvUnit.cpp','UnitTypes CvUnit::getCaptureUnitType('),
      'capture preserves original owner':'pkCapturedUnit->SetOriginalOwner(kCaptureDef.eOriginalOwner);' in data['CvUnit.cpp'],
      'original owner and death bindings':all('Method('+s+');' in data['CvLuaUnit.cpp'] for s in ['GetOriginalOwner','IsDead','IsDelayedDeath']),
      'autosave precedes Done hook':phase.index('gDLL->AutoSave(false, true)')<phase.index('GAMEEVENT_PlayerDoneTurn'),
      'load does not rerun economics':'doTurn();' not in body('CvPlayer.cpp','void CvPlayer::Read('),
    }
    assert all(checks.values()),[k for k,v in checks.items() if not v]
    report={'commit':COMMIT,'dll_version':151,'scope':'Pinned native source contracts; not engine execution','checks':checks,
            'sources':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}
    # The UI event bridge is engine-owned: use its shipped Firaxis consumers
    # alongside the corresponding inspected DLL publisher, not a guessed event.
    native_ui=Path("G:/SteamLibrary/steamapps/common/Sid Meier's Civilization V/Assets/DLC/Expansion2/UI/InGame/CityBannerManager.lua")
    if native_ui.is_file():
        raw=native_ui.read_bytes();text=raw.decode('utf-8-sig')
        assert 'Events.SpecificCityInfoDirty.Add(OnSpecificCityInfoDirty)' in text
        assert 'Events.SerialEventCityInfoDirty.Add(OnCityUpdate)' in text
        assert 'SetSpecificCityInfoDirty(pCity.get(), CITY_UPDATE_TYPE_BANNER)' in setter
        report['installed_ui_evidence']={'path':str(native_ui),'sha256':hashlib.sha256(raw).hexdigest(),
            'scope':'Shipped Firaxis UI subscriptions and native post-setter publisher; not engine dispatch execution'}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS',len(checks),'Circus pinned CP v151 source contracts')

def validate(fetch=False):
    d=sql();art(d);gameplay(d);sources(fetch)
    report={'scope':'SQL/static/source checks and Lua 5.1 mocks; Civ V was NOT launched',
            'lua_suite_runs':30,'speeds':['Quick','Standard','Epic','Marathon','custom'],
            'start_turns':[0,150],'source_contracts':29,'native_tests':'Pending: docs/Testing.md'}
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')

if __name__=='__main__': validate('--fetch' in sys.argv)
