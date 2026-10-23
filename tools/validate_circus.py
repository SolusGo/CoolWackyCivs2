"""Actual-schema SQL, pinned CP source, DDS and shipped Lua 5.1 simulations."""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, json, re, sqlite3, sys, urllib.request
from lupa.lua51 import LuaRuntime
from PIL import Image
from database import database, quote, is_cp_cache
from generate_circus import R,V,CIV,LEADER,UNIT,OFFICE,DUMMIES,TEXT,CITIES
from validate_twelfth import inherited
SUITES=['circus_timing.lua','circus_lifecycle.lua','circus_persistence.lua','circus_audit.lua']
SPEEDS=['QUICK','STANDARD','EPIC','MARATHON','CUSTOM']
STARTS=[0,150]

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
    if cache.exists() and is_cp_cache(cache):
        source=sqlite3.connect(cache.resolve().as_uri()+'?mode=ro',uri=True);active=sqlite3.connect(':memory:');source.backup(active);source.close()
        active.row_factory=sqlite3.Row
        active.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
        if not active.execute('SELECT 1 FROM Civilizations WHERE Type=?',(CIV,)).fetchone():
            apply(active);check_inheritance(active)
            print('PASS Circus activation on read-only copy of actual active CP cache')
        else: print('SKIP active-cache activation: Circus already present')
    else: print('SKIP Circus raw active-cache activation: no cache with Community Patch loaded')
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
    for speed in SPEEDS:
        for start in STARTS:
            for name in SUITES:
                lua=LuaRuntime()
                if (speed,start)!=('QUICK',0): lua.globals().print=lambda *args:None
                lua.execute((R/'tools/tests/circus_mock.lua').read_text(encoding='utf-8'))
                lua.globals().startTurn=start
                lua.globals().Game.GetGameSpeedType=lambda:speed
                lua.globals().LoadCircus=lambda:lua.execute(source)
                lua.execute('function Harvest(c) return (c.b[103] or 0)*'+str(values['YIELD_CULTURE'])+'+((c.b[102] or 0)>0 and '+str(officeCulture)+' or 0), (c.b[103] or 0)*'+str(values['YIELD_GOLD'])+', (c.b[104] or 0)*'+str(prod)+' end')
                lua.execute((R/'tools/tests'/name).read_text(encoding='utf-8'))
    print('PASS',len(SUITES)*len(SPEEDS)*len(STARTS),'Circus shipped-Lua 5.1 suite runs: split economics, lifecycle, snapshots/autosaves, 5 speeds, 2 start turns; NOT native engine tests')

def sources(fetch=False):
    from audit_cp import COMMIT,BASE
    names=['CustomMods.h','CvPlayer.cpp','CvPlayerAI.cpp','CvCity.cpp','CvUnit.cpp','CvUnitCombat.cpp','CvTreasury.cpp','CvBuildingClasses.cpp','CvGame.cpp','CvDllNetMessageHandler.cpp','CvLuaCity.cpp','CvLuaUnit.cpp','CvLuaPlot.cpp','CvLuaPlayer.cpp','CvLuaGame.cpp']
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
    city_turn=body('CvCity.cpp','void CvCity::doTurn(')
    deactivate=body('CvGame.cpp','void CvGame::CheckPlayerTurnDeactivate(')
    moves=body('CvGame.cpp','void CvGame::updateMoves(')
    rate=body('CvCity.cpp','int CvCity::getYieldRateTimes100(YieldTypes eYield, bool bIgnoreTrade, bool bIgnoreProcess, int iAssumeExtraModifier')
    kill=body('CvUnit.cpp','void CvUnit::kill(')
    relocation=body('CvUnit.cpp','void CvUnit::setXY(')
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
      'owner-active state precedes attrition and economics':phase.index('m_bTurnActive = bNewValue')<phase.index('DoUnitAttrition();')<phase.index('doTurn();'),
      'IsTurnActive bound to native flag':'Method(IsTurnActive);' in data['CvLuaPlayer.cpp'] and '&CvPlayerAI::isTurnActive' in body('CvLuaPlayer.cpp','int CvLuaPlayer::lIsTurnActive('),
      'Game.GetGameTurn reads native absolute turn':'&CvGame::getGameTurn' in body('CvLuaGame.cpp','int CvLuaGame::lGetGameTurn('),
      'autosave precedes serialized active-flag transition':phase.index('gDLL->AutoSave(false, true)')<phase.index('m_bTurnActive = bNewValue'),
      'active/end/automove flags serialized':all('visitor(player.'+s+');' in data['CvPlayer.cpp'] for s in ['m_bTurnActive','m_bEndTurn','m_bAutoMoves']),
      'processed automoves rebuilt after load':'visitor(player.m_bProcessedAutoMoves)' not in data['CvPlayer.cpp'] and 'm_bProcessedAutoMoves = false;' in data['CvPlayer.cpp'] and 'player.setProcessedAutoMoves(true)' in moves and 'player.isAutoMoves()' in moves,
      'deactivation gates precede Done dispatch':deactivate.index('kPlayer.isAlive() && kPlayer.isTurnActive()')<deactivate.index('kPlayer.isEndTurn()')<deactivate.index('kPlayer.hasProcessedAutoMoves()')<deactivate.index('kPlayer.setTurnActive(false)'),
      'sequential next player follows old deactivation':deactivate.index('kPlayer.setTurnActive(false)')<deactivate.index('kNextPlayer.setTurnActive(true)'),
      'rollover precedes next sequential round activation':body('CvGame.cpp','void CvGame::doTurn(').index('incrementGameTurn();')<body('CvGame.cpp','void CvGame::doTurn(').index('GET_PLAYER((PlayerTypes)iI).setTurnActive(true)'),
      'city Production precedes meltdown':city_turn.index('doProduction(')<city_turn.index('doMeltdown();'),
      'meltdown can invoke native unit damage':'CvUnitCombat::ApplyNuclearExplosionDamage(plot(), 1);' in body('CvCity.cpp','void CvCity::doMeltdown('),
      'nuclear damage can kill civilians before Gold/Culture':'pkUnit->kill(false, eAttackerOwner);' in body('CvUnitCombat.cpp','uint CvUnitCombat::ApplyNuclearExplosionDamage(const CvCombatMemberEntry*'),
      'real Production credits rate and overflow':'changeProductionTimes100(getYieldRateTimes100(YIELD_PRODUCTION) + getTotalOverflowProductionTimes100());' in body('CvCity.cpp','void CvCity::doProduction('),
      'treasury credits net ordinary Gold':'int iGoldChange = CalculateBaseNetGoldTimes100();' in body('CvTreasury.cpp','void CvTreasury::DoGold(') and 'ChangeGoldTimes100(iGoldChange);' in body('CvTreasury.cpp','void CvTreasury::DoGold('),
      'treasury Gold includes city rate':'GetGoldFromCitiesTimes100()' in body('CvTreasury.cpp','int CvTreasury::CalculateGrossGoldTimes100(') and 'pLoopCity->getYieldRateTimes100(YIELD_GOLD, bExcludeTradeRoutes)' in body('CvTreasury.cpp','int CvTreasury::GetGoldFromCitiesTimes100('),
      'player Culture includes native city rates':'GetYieldRateFromCitiesTimes100(YIELD_CULTURE)' in body('CvPlayer.cpp','int CvPlayer::GetTotalJONSCulturePerTurnTimes100('),
      'building flat changes refresh native rates':'UpdateCityYields(eIndex);' in body('CvCity.cpp','void CvCity::ChangeBaseYieldRateFromBuildings('),
      'ordinary rate suppresses anarchy resistance razing':'IsAnarchy() || IsResistance() || IsRazing()' in rate,
      'ordinary rate applies integer modifiers once':'iBaseYield * getBaseYieldRateModifier' in rate and 'iModifiedYield /= 100;' in rate,
      'post modifiers precede trade additions':rate.index('iModifiedYield /= 100;')<rate.index('GetPostModifierYieldRateTimes100')<rate.index('GetTradeValuesAtCityTimes100'),
      'city Culture contributes to local borders':'getYieldRateTimes100(YIELD_CULTURE);' in body('CvCity.cpp','int CvCity::getBaseYieldRateTimes100(') and 'ChangeJONSCultureStoredTimes100(iBorderGrowth)' in city_turn,
      'prekill precedes delayed-death flag':kill.index('GAMEEVENT_UnitPrekill')<kill.index('startDelayedDeath();'),
      'UnitSetXY exact owner ID x y ABI':bool(re.search(r'args->Push\(getOwner\(\)\);\s*args->Push\(GetID\(\)\);\s*args->Push\(getX\(\)\);\s*args->Push\(getY\(\)\);\s*bool bResult = false;\s*LuaSupport::CallHook\(pkScriptSystem, "UnitSetXY"',relocation)),
      'UnitSetXY follows native relocation':relocation.index('m_iX = pNewPlot->getX();')<relocation.index('"UnitSetXY"'),
      'unit original owner serialized':'visitor(unit.m_eOriginalOwner);' in data['CvUnit.cpp'],
      'capture samples original identity':'kCaptureDef.eOriginalOwner = GetOriginalOwner();' in data['CvUnit.cpp'],
      'CityConstructed ABI':bool(re.search(r'GAMEEVENT_CityConstructed\s+"CityConstructed",\s+"iiibb"',data['CustomMods.h'])),
      'CitySoldBuilding ABI':bool(re.search(r'GAMEEVENT_CitySoldBuilding\s+"CitySoldBuilding",\s+"iii"',data['CustomMods.h'])),
      'gold and faith purchases report post-creation':all(bool(re.search(r'CreateBuilding\(eBuildingType\).*?GAMEEVENT_CityConstructed, getOwner\(\), GetID\(\), eBuildingType, '+flags,data['CvCity.cpp'],re.S)) for flags in ['true, false','false, true']),
      'founding callback ABI owner x y':bool(re.search(r'args->Push\(GetID\(\)\);\s*args->Push\(pCity->getX\(\)\);\s*args->Push\(pCity->getY\(\)\);\s*bool bResult = false;\s*LuaSupport::CallHook\(pkScriptSystem, "PlayerCityFounded"',data['CvPlayer.cpp'])),
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
    return len(checks)

def yield_models(d):
    """CP-derived ordinary base-yield arithmetic; not native Treasury/City execution."""
    yields=dict(d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_WCIRCUS_FESTIVAL_YIELDS'"))
    production=d.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_WCIRCUS_TICKET_PRODUCTION'").fetchone()[0]
    def rate(base100,bonus,mods=(),post100=0,trade100=0,suppressed=False):
        return 0 if suppressed else (base100+bonus*100)*max(0,100+sum(mods))//100+post100+trade100
    assert rate(2000,production,[25,15,20])-rate(2000,0,[25,15,20])==320
    assert rate(1000,yields['YIELD_GOLD'],[25])-rate(1000,0,[25])==250
    assert rate(400,yields['YIELD_CULTURE']+1,[50])-rate(400,0,[50])==600
    assert rate(1001,production,[25])==1501 # (1001 + 200) * 125 / 100 truncates
    for state in ['resistance','anarchy','razing']:
        assert rate(2000,production,[25],post100=100,trade100=300,suppressed=True)==0,state
    assert rate(2000,production,[25],post100=100,trade100=300)==3150
    print('PASS CP-derived Circus yield arithmetic: SQL-backed base yields, ordinary modifiers, suppression, post/trade additions and hundredth rounding; NOT native execution')

def validate(fetch=False):
    d=sql();art(d);gameplay(d);contracts=sources(fetch);yield_models(d)
    report={'scope':'SQL/static/source checks and Lua 5.1 mocks; Civ V was NOT launched',
            'lua_suite_runs':len(SUITES)*len(SPEEDS)*len(STARTS),'suites':SUITES,'speeds':SPEEDS,
            'start_turns':STARTS,'source_contracts':contracts,'native_tests':'Pending: docs/Testing.md'}
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')

if __name__=='__main__': validate('--fetch' in sys.argv)
