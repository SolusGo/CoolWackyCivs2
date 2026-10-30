"""HCC actual-schema inheritance, isolation, pinned CP source, shipped Lua and DDS validation."""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, json, re, struct, math, time
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote
from build_mod import files, imported, ENTRIES, NAME
from generate_honeycomb import R, V, CIV, LEADER, UNIT, EXCHANGE, PROMOTION, DUMMIES, TEXT
from audit_cp import COMMIT, BASE

# Independently downloaded from the official pinned commit during this audit.
REMOTE_SHA256={
 'CustomMods.h':'7b7de803c983122ab90d6495480bd93569211fd1036385f5b0f60c6c59a80a11',
 'CvPlayer.cpp':'893bb58411b5a9b0f8af60f9eaa760c8766590c440ae6bd52c7736b88df56b87',
 'CvPlayerAI.cpp':'a4fb3ae925db892dc4c0106780b00438d06aa39df885845affb48044064a8ec1',
 'CvGame.cpp':'6dad41a144c98a15d94d59ee0d4effb0ff92190586074adb7e5c03bb1815b205',
 'CvCity.cpp':'2e2cf69b58d2dcd585f6a534bb3a436699be3f976f020a30202e83f809f61bd2',
 'CvBuildingClasses.cpp':'44959390632ce9646dbfc77752c22d965fadc53ff049098594a18477e3dd8a25',
 'CvTreasury.cpp':'c6f466557b239da4fee84e115ff8d05d3e99fa5774277c312dd55c64f09bd818',
 'CvLuaCity.cpp':'2b3b947c94e16457636ae9c5e1a3c675f692434d2dac40d92f66e81f0a850e24',
 'CvLuaPlayer.cpp':'515e4080f98f4a120235722de646c366fb2fd77b90fce02a9d3bdc516a3b482a',
 'CvUnit.cpp':'54ea19c86652cc814784e084337dda3a9e47a9e7c4d70d6d7e7e83511b43a875',
}

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')): d.executescript(p.read_text(encoding='utf-8'))

def yields(d, building):
    return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType',(building,)))

def inheritance(d):
    for table,old,new,allowed in [
        ('Units','UNIT_SCOUT',UNIT,{'ID','Type','Moves','Description','Help','Civilopedia','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}),
        ('Buildings','BUILDING_MARKET',EXCHANGE,{'ID','Type','Description','Help','Civilopedia','Strategy','IconAtlas','PortraitIndex'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for k in a.keys():
            if k not in allowed: assert a[k]==b[k],(table,k,a[k],b[k])
        if table=='Units': assert b['Moves']==a['Moves']+1
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            columns=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in columns: continue
            columns=[c for c in columns if c not in (col,'ID')]
            q='SELECT '+','.join(map(quote,columns))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
            before=Counter(tuple(r) for r in d.execute(q,(old,)))
            after=Counter(tuple(r) for r in d.execute(q,(new,)))
            if t=='Unit_FreePromotions': after.subtract({(PROMOTION,):1}); after=+after
            if t=='Building_YieldChanges':
                expected=yields(d,old); expected['YIELD_FOOD']=expected.get('YIELD_FOOD',0)+1
                assert expected==yields(d,new)
            else: assert before==after,(t,before-after,after-before)

def sql():
    d=database()
    for p in files():
        if p.suffix=='.sql' and p.relative_to(R).parts[0]!='TheHoneycombCommonwealth':
            d.executescript(p.read_text(encoding='utf-8'))
    tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables}
    apply(d)
    for t,rows in before.items():
        assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('changed existing rows',t)
    inheritance(d)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    assert [tuple(r) for r in d.execute('SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,))]==[('UNITCLASS_SCOUT',UNIT)]
    assert [tuple(r) for r in d.execute('SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?',(CIV,))]==[('BUILDINGCLASS_MARKET',EXCHANGE)]
    assert [r[0] for r in d.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,))]==['TRAIT_HCC_SMALL_HANDS']
    assert not d.execute('SELECT 1 FROM Leader_SharedTraits WHERE LeaderType=?',(LEADER,)).fetchone()
    trait=d.execute("SELECT * FROM Traits WHERE Type='TRAIT_HCC_SMALL_HANDS'").fetchone()
    defaults={r[1]:r[4] for r in d.execute('PRAGMA table_info(Traits)')}
    for col in trait.keys():
        if col in ('ID','Type','Description','ShortDescription'): continue
        default=d.execute('SELECT '+defaults[col]).fetchone()[0] if defaults[col] is not None else None
        assert trait[col]==default,('unintended trait ability',col,trait[col],default)
    for suffix in DUMMIES:
        b='BUILDING_HCC_'+suffix
        row=d.execute('SELECT * FROM Buildings WHERE Type=?',(b,)).fetchone()
        for field,value in [('Cost',-1),('FaithCost',-1),('IsDummy',1),('ShowInPedia',0),('NeverCapture',1),('ConquestProb',0),('NukeImmune',1),('GoldMaintenance',0),('SpecialistCount',0),('Happiness',0),('GreatWorkCount',-1)]:
            assert row[field]==value,(b,field,row[field])
        assert row['PrereqTech'] is None
        assert yields(d,b)=={'YIELD_'+suffix.split('_')[0]:1}
        cls=d.execute('SELECT * FROM BuildingClasses WHERE Type=?',(row['BuildingClass'],)).fetchone()
        assert cls['DefaultBuilding']==b
        assert (cls['MaxGlobalInstances'],cls['MaxPlayerInstances'],cls['MaxTeamInstances'])==(-1,-1,-1)
        assert row['SpecialistType'] is None
        # No native policy/technology/religion/wonder rules name these new classes.
        for table, in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            if table in ('Buildings','BuildingClasses'): continue
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')]
            for col in ('BuildingClassType','BuildingClass'):
                if col in cols:
                    assert not d.execute('SELECT 1 FROM '+quote(table)+' WHERE '+quote(col)+'=?',(row['BuildingClass'],)).fetchone(),(table,col)
    assert len({d.execute('SELECT BuildingClass FROM Buildings WHERE Type=?',('BUILDING_HCC_'+suffix,)).fetchone()[0] for suffix in DUMMIES})==7
    p=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',(PROMOTION,)).fetchone()
    assert (p['VisibilityChange'],p['MovesChange'],p['CombatPercent'],p['CannotBeChosen'],p['LostWithUpgrade'])==(1,0,0,1,1)
    assert [r[0] for r in d.execute('SELECT UnitType FROM Unit_FreePromotions WHERE PromotionType=?',(PROMOTION,))]==[UNIT]
    assert not d.execute('SELECT 1 FROM UnitPromotions_UnitCombats WHERE PromotionType=?',(PROMOTION,)).fetchone()
    for key,value in TEXT.items(): assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_HCC_'+key,)).fetchone()[0]==value
    # Approved original dialogue/Dawn hashes are independent of the generator.
    for key,digest in {
        'GREETING_1':'de5dad81b4de34ead039c9239e8489512edfbca6d4119b5b99dcfee9a0961103',
        'WAR_1':'1eabe33cdb2fd6199adb51c68b60b1d1ddc416f1d55f167f6968fb5b3ae9a011',
        'DEFEAT_1':'8a0e39d95b01af15ec870329ebe72388f747450530421abe5d2b28cb94cb7cff',
        'DAWN':'11b52235d52bd55e60cb8216ca43037292f2c7ea7e13a52cb1c3e9216846ee32',
    }.items():
        value=d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_HCC_'+key,)).fetchone()[0]
        assert hashlib.sha256(value.encode()).hexdigest()==digest,('changed approved dialogue',key)
    for p in (V/'SQL').glob('*.sql'):
        for tag in re.findall(r"'(TXT_KEY_HCC_[A-Z0-9_]+)'",p.read_text(encoding='utf-8')):
            if tag in ('TXT_KEY_HCC_CIV5','TXT_KEY_HCC_MELLIA'): continue # native Civilopedia prefixes
            assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(tag,)).fetchone(),tag
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    # Runtime SELECT cloning must also respect a changed active baseline.
    altered=database()
    altered.execute("UPDATE Units SET Moves=7,Combat=19,BaseSightRange=5 WHERE Type='UNIT_SCOUT'")
    altered.execute("UPDATE Buildings SET Cost=137,GoldMaintenance=2,TradeRouteRecipientBonus=4 WHERE Type='BUILDING_MARKET'")
    altered.execute("INSERT INTO Building_YieldChanges VALUES ('BUILDING_MARKET','YIELD_FOOD',3)")
    altered.execute("INSERT INTO Leader_SharedTraits(LeaderType,TraitOne,TraitTwo) VALUES ('LEADER_WASHINGTON','POLICY_TRADITION','POLICY_LIBERTY')")
    apply(altered); inheritance(altered)
    assert not altered.execute('SELECT 1 FROM Leader_SharedTraits WHERE LeaderType=?',(LEADER,)).fetchone()
    assert altered.execute('SELECT Moves FROM Units WHERE Type=?',(UNIT,)).fetchone()[0]==8
    print('PASS HCC actual BNW/CP-schema SQL, Scout/Market rows and companions, dynamic inheritance, exact flat yields, promotion, localization and zero changes to preexisting records')
    return d

def body(source,signature):
    pos=source.index(signature); start=source.index('{',pos); depth=1; end=start+1
    while depth:
        if source[end]=='{': depth+=1
        elif source[end]=='}': depth-=1
        end+=1
    return source[start:end]

def sources():
    names=['CustomMods.h','CvPlayer.cpp','CvPlayerAI.cpp','CvGame.cpp','CvCity.cpp','CvCityCitizens.cpp','CvDllNetMessageHandler.cpp','CvLuaCity.cpp','CvLuaPlot.cpp','CvLuaPlayer.cpp','CvLuaGame.cpp','CvLuaUnit.cpp','CvUnit.cpp','CvBuildingClasses.cpp','CvTreasury.cpp']
    data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    turn=body(data['CvPlayer.cpp'],'void CvPlayer::doTurnPostDiplomacy(')
    phase=body(data['CvPlayer.cpp'],'void CvPlayer::setTurnActive(')
    acquire=body(data['CvPlayer.cpp'],'CvCity* CvPlayer::acquireCity(')
    sale=body(data['CvDllNetMessageHandler.cpp'],'void CvDllNetMessageHandler::ResponseSellBuilding(')
    native_set=body(data['CvBuildingClasses.cpp'],'void CvCityBuildings::SetNumRealBuildingTimed(')
    native_process=body(data['CvCity.cpp'],'void CvCity::processBuilding(')
    checks={
      'DLL v151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',data['CustomMods.h'])),
      'city economics then gold then culture then PlayerDoTurn':turn.index('pLoopCity->doTurn();')<turn.index('GetTreasury()->DoGold();')<turn.index('changeJONSCultureTimes100(')<turn.index('"PlayerDoTurn"'),
      'activation calls economics before active UI turn start':phase.index('doTurn();')<phase.index('PublishActivePlayerTurnStart()'),
      'done turn synchronous hook before deactivation completes':'GAMEEVENTINVOKE_HOOK(GAMEEVENT_PlayerDoneTurn, GetID())' in phase and phase.index('GAMEEVENT_PlayerDoneTurn')<phase.index('DoUnitReset()'),
      'done turn gated by EVENTS_PLAYER_TURN':'MOD_EVENTS_PLAYER_TURN' in phase and bool(re.search(r'GAMEEVENT_PlayerDoneTurn\s+"PlayerDoneTurn",\s+"i"',data['CustomMods.h'])),
      'no speculative pre-economy Lua hook in AI_doTurnPre':'CallHook' not in body(data['CvPlayerAI.cpp'],'void CvPlayerAI::AI_doTurnPre(') and 'GAMEEVENT' not in body(data['CvPlayerAI.cpp'],'void CvPlayerAI::AI_doTurnPre('),
      'capture after reconstruction':acquire.index('SetNumRealBuildingTimed(')<acquire.index('"CityCaptureComplete"'),
      'capture ABI new owner fifth':bool(re.search(r'args->Push\(eOldOwner\);\s*args->Push\(bCapital\);\s*args->Push\(iCityX\);\s*args->Push\(iCityY\);\s*args->Push\(GetID\(\)\)',acquire)),
      'sale event after removal':sale.index('DoSellBuilding(eBuilding)')<sale.index('GAMEEVENT_CitySoldBuilding'),
      'native dummy suppresses construction rewards':'pBuildingInfo->IsDummy()' in data['CvCity.cpp'] and 'bNoBonus = true' in data['CvCity.cpp'],
      'never capture enforced':'pkBuildingInfo->IsNeverCapture()' in data['CvPlayer.cpp'],
      'plot working city is effective owning city':'getEffectiveOwningCity()' in body(data['CvLuaPlot.cpp'],'int CvLuaPlot::lGetWorkingCity('),
      'native city working check validates plot index':'m_pabWorkingPlot[iIndex]' in body(data['CvCityCitizens.cpp'],'bool CvCityCitizens::IsWorkingPlot(const CvPlot*'),
      'city plot count uses workable plot count':'GetNumWorkablePlots()' in body(data['CvLuaCity.cpp'],'int CvLuaCity::lGetNumCityPlots('),
      'reading save does not rerun economics':'doTurn();' not in body(data['CvPlayer.cpp'],'void CvPlayer::Read('),
      'Sight lost on upgrade native support':'!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade()' in data['CvUnit.cpp'],
      'real building setter applies delta before returning':'iNewValue - GetNumRealBuilding(eIndex)' in native_set and 'm_pCity->processBuilding(eIndex, iChangeNumRealBuilding' in native_set,
      'real setter no-bonus Lua argument':'luaL_optbool(L, 4, true)' in body(data['CvLuaCity.cpp'],'int CvLuaCity::lSetNumRealBuilding('),
      'building flat yield enters native city base':'pBuildingInfo->GetYieldChange(eYield)' in native_process and 'ChangeBaseYieldRateFromBuildings' in native_process,
      'base building yield updates cached native rates':'UpdateCityYields(eIndex)' in body(data['CvCity.cpp'],'void CvCity::ChangeBaseYieldRateFromBuildings('),
      'city economics includes Production':'doProduction(!doCheckProduction())' in body(data['CvCity.cpp'],'void CvCity::doTurn('),
      'Production payout consumes native Production rate':'changeProductionTimes100(getYieldRateTimes100(YIELD_PRODUCTION)' in body(data['CvCity.cpp'],'void CvCity::doProduction('),
      'treasury payout uses net rate and stored Gold':'CalculateBaseNetGoldTimes100()' in body(data['CvTreasury.cpp'],'void CvTreasury::DoGold(') and 'ChangeGoldTimes100(iGoldChange)' in body(data['CvTreasury.cpp'],'void CvTreasury::DoGold('),
      'treasury city rate includes native Gold yield':'getYieldRateTimes100(YIELD_GOLD' in body(data['CvTreasury.cpp'],'int CvTreasury::GetGoldFromCitiesTimes100('),
      'gross treasury rate includes city yields':'GetGoldFromCitiesTimes100()' in body(data['CvTreasury.cpp'],'int CvTreasury::CalculateGrossGoldTimes100('),
      'player Culture includes city Culture rates':'GetYieldRateFromCitiesTimes100(YIELD_CULTURE)' in body(data['CvPlayer.cpp'],'int CvPlayer::GetTotalJONSCulturePerTurnTimes100('),
      'real and free buildings normally use max':'std::max(GetNumRealBuilding(eIndex), GetNumFreeBuilding(eIndex))' in body(data['CvBuildingClasses.cpp'],'int CvCityBuildings::GetNumBuilding('),
      'zero-maintenance Market cannot be manually sold':'kBuilding.GetGoldMaintenance() <= 0' in body(data['CvBuildingClasses.cpp'],'bool CvCityBuildings::IsBuildingSellable('),
      'dummy excluded from ordinary building count':'if(!buildingEntry->IsDummy())' in native_set,
      'no construction with Cost -1':'pBuildingInfo.GetProductionCost() == -1' in data['CvPlayer.cpp'],
      'native setters publish specific-city dirty':'SetSpecificCityInfoDirty' in native_set,
      'native free building setter publishes dirty':'SetSpecificCityInfoDirty' in body(data['CvBuildingClasses.cpp'],'void CvCityBuildings::SetNumFreeBuilding('),
      'ScriptData serialized natively':'visitor(player.m_strScriptData);' in data['CvPlayer.cpp'],
      'dummy counts serialized natively':'visitor(MakeConstSpan(cityBuildings.m_paiNumRealBuilding, iNumBuildings));' in data['CvBuildingClasses.cpp'],
      'final initialized flag serialized and insufficient as load barrier':'visitor(game.m_bFinalInitialized);' in data['CvGame.cpp'],
      'blocking diplomacy economics can precede GameCoreUpdateBegin':body(data['CvGame.cpp'],'void CvGame::update(').index('doTurnPostDiplomacy();')<body(data['CvGame.cpp'],'void CvGame::update(').index('"GameCoreUpdateBegin"'),
      'pre-AI unit hook is not an owner-economy boundary':'"PlayerPreAIUnitUpdate"' in body(data['CvPlayerAI.cpp'],'void CvPlayerAI::AI_unitUpdate('),
      'autosave precedes owner-end staging':phase.index('AutoSave(false, true)')<phase.index('GAMEEVENT_PlayerDoneTurn'),
      'done turn precedes completed UI publications':phase.index('GAMEEVENT_PlayerDoneTurn')<phase.index('PublishActivePlayerTurnEnd()')<phase.index('"PlayerEndTurnCompleted"'),
    }
    for kind,methods in {'City':'GetOwner GetID GetX GetY GetGameTurnFounded GetNumBuilding GetNumRealBuilding SetNumRealBuilding GetNumCityPlots GetCityIndexPlot IsWorkingPlot', 'Plot':'GetOwner GetX GetY GetPlotIndex GetPlotCity GetImprovementType IsImprovementPillaged GetWorkingCity', 'Player':'GetID GetCivilizationType IsAlive GetCityByID Cities GetScriptData SetScriptData', 'Game':'GetGameTurn IsFinalInitialized'}.items():
        for method in methods.split(): checks[kind+':'+method]=bool(re.search(r'Method\s*\(\s*'+method+r'\s*\)',data['CvLua'+kind+'.cpp']))
    for name,digest in REMOTE_SHA256.items():
        checks['official pinned SHA256 '+name]=hashlib.sha256((R/'tools/reference'/name).read_bytes()).hexdigest()==digest
    for name,passed in checks.items(): assert passed,name
    report={'commit':COMMIT,'checks':checks,'timing_result':'Exact pre-economic start-of-owner-turn snapshot not guaranteed by exposed audited hooks. PlayerDoneTurn stages next payout from end-turn assignments; interturn changes wait until next snapshot. Native gameplay not run.',
            'independent_remote_verification':{'date':'2026-10-30','official_files_matched':10,'method':'Read official raw source over HTTPS and compare SHA-256 with local reference files; pinned digest assertions retained'},
            'files':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS HCC',len(checks),'pinned CP v151 source contracts; exact beginning snapshot limitation explicitly retained')
    return len(checks)

def runtime(d):
    lua=LuaRuntime()
    tests=['honeycomb_assertions.lua','honeycomb_hardening.lua','honeycomb_payout.lua','honeycomb_scale.lua']
    for p in list(V.rglob('*.lua'))+[R/'tools/tests'/name for name in tests]:
        lua.eval('function(s,n) local f,e=loadstring(s,n);assert(f,e) end')(p.read_text(encoding='utf-8'),str(p))
    results=[]
    for speed in ('GAMESPEED_STANDARD','GAMESPEED_MARATHON'):
        lua=LuaRuntime()
        lua.globals().HCC_TEST_SPEED=speed
        lua.globals().LoadHCC=lambda:lua.execute((V/'Lua/HCC_Commonwealth.lua').read_text(encoding='utf-8'))
        payload={30:yields(d,EXCHANGE)}
        payload.update({41+i:yields(d,'BUILDING_HCC_'+suffix) for i,suffix in enumerate(DUMMIES)})
        lua.globals().HCC_DatabaseYields=lua.table_from({n:lua.table_from({y.removeprefix('YIELD_'):v for y,v in ys.items()}) for n,ys in payload.items()})
        lua.globals().HCC_MarketGoldBase=yields(d,'BUILDING_MARKET').get('YIELD_GOLD',0)
        lua.globals().HCC_MarketGoldModifier=d.execute("SELECT SUM(Yield) FROM Building_YieldModifiers WHERE BuildingType='BUILDING_MARKET' AND YieldType='YIELD_GOLD'").fetchone()[0] or 0
        started=time.perf_counter()
        for name in tests: lua.execute((R/'tools/tests'/name).read_text(encoding='utf-8'))
        result=dict(lua.globals().HCC_Performance);result.update(speed=speed,mock_total_ms=round((time.perf_counter()-started)*1000,3))
        results.append(result)
    return results

def art(d):
    for p in V.rglob('*.xml'): ET.parse(p)
    for p in (V/'Art').glob('*.dds'):
        raw=p.read_bytes(); assert raw[:4]==b'DDS ' and struct.unpack_from('<I',raw,4)[0]==124
        width,height=struct.unpack_from('<I',raw,16)[0],struct.unpack_from('<I',raw,12)[0]
        levels=struct.unpack_from('<I',raw,28)[0]
        assert levels==math.floor(math.log2(max(width,height)))+1,'incomplete mip count'
        assert raw[84:88]==b'\0'*4 and struct.unpack_from('<I',raw,88)[0]==32,'unexpected non-legacy DDS encoding'
        assert len(raw)==128+sum(max(1,width>>i)*max(1,height>>i)*4 for i in range(levels)),('truncated mip payload',p)
        with Image.open(p) as im: im.load(); assert im.width>0 and im.height>0
    for atlas,size,filename,cols,rows in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'HCC_%'"):
        with Image.open(V/'Art'/filename) as im: assert im.size==(size*int(cols),size*int(rows))
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',EXCHANGE)]:
        atlas,index=d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=32 AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
    assert len(list((V/'Art').glob('*.dds')))==40
    for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(512,512))]:
        with Image.open(V/'Art'/f'HCC_{stem}.dds') as im: assert im.size==size
    assert ET.parse(V/'Art/HCC_LeaderScene.xml').getroot().get('FallbackImage')=='HCC_Leader.dds'
    root=ET.parse(R/(NAME+'.modinfo')).getroot()
    hcc=[p for p in files() if p.relative_to(R).parts[0]=='TheHoneycombCommonwealth']
    entries={e.text:e for e in root.findall('Files/File')}
    for p in hcc:
        name=p.relative_to(R).as_posix(); assert name in entries
        assert entries[name].get('import')==str(int(imported(p)))
        assert entries[name].get('md5')==hashlib.md5(p.read_bytes()).hexdigest().upper()
    assert len([e for e in root.findall('EntryPoints/EntryPoint') if e.get('file')==ENTRIES[-1][0]])==1
    sql_order=[e.text for e in root.findall('Actions/OnModActivated/UpdateDatabase')]
    assert sql_order[-5:]==[p.relative_to(R).as_posix() for p in sorted((V/'SQL').glob('*.sql'))]
    print('PASS HCC 40 DDS decoded/mipmapped, atlas/leader references, XML, VFS, hashes, single addin and append-only SQL order')

def validate():
    d=sql(); contracts=sources(); performance=runtime(d); art(d)
    (V/'docs/Performance.json').write_text(json.dumps({'runtime':'Lua 5.1 mock; not native DLL profiling','measurements':performance},indent=2)+'\n',encoding='utf-8')
    return contracts

if __name__=='__main__': validate()
