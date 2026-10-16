"""Actual-schema inheritance, isolated Lua gameplay simulations and CP source contracts."""
from pathlib import Path
from collections import Counter
import hashlib,json,re
from database import database,quote
from build_mod import R,files
from generate_pigeons import CIV,LEADER,UNIT,ROOST,TEXT
from lupa.lua51 import LuaRuntime

V=R/'TheRepublicOfPigeons'

def apply(d):
    # Use the same cross-civilization SQL order as the generated manifest.
    for path in files():
        if path.suffix=='.sql':d.executescript(path.read_text(encoding='utf-8'))

def companions(d,table,column,old,new):
    for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
        columns=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
        if not name.startswith(table) or column not in columns:continue
        fields=[c for c in columns if c not in [column,'ID']]
        query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(name)+' WHERE '+quote(column)+'=?'
        expected=Counter(tuple(r) for r in d.execute(query,(old,)))
        if name=='Building_YieldChanges':
            original=sum(row[1]*n for row,n in expected.items() if row[0]=='YIELD_CULTURE')
            expected=Counter({row:n for row,n in expected.items() if row[0]!='YIELD_CULTURE'})
            expected[('YIELD_CULTURE',original+1)]=1
        actual=Counter(tuple(r) for r in d.execute(query,(new,)))
        if name=='Unit_FreePromotions':expected[('PROMOTION_PIGEON_LOOKOUT',)]=1
        assert actual==expected,('companion inheritance',name,expected,actual)

def sql():
    d=database()
    # Snapshot the other civ as well: Pigeons may not change its database records.
    for path in sorted((R/'TheBoundlessCity/SQL').glob('*.sql')):d.executescript(path.read_text(encoding='utf-8'))
    snapshot={}
    for table in ['Civilizations','Leaders','Units','Buildings','Traits']:
        snapshot[table]=[tuple(r) for r in d.execute('SELECT * FROM '+table+' ORDER BY ID')]
    for path in sorted((V/'SQL').glob('*.sql')):d.executescript(path.read_text(encoding='utf-8'))
    for table,old,new,allowed in [
        ('Units','UNIT_SCOUT',UNIT,{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}),
        ('Buildings','BUILDING_CARAVANSARY',ROOST,{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        assert b is not None
        for key in a.keys():
            if key not in allowed:assert a[key]==b[key],(table,key,a[key],b[key])
        if table=='Units':companions(d,'Unit_','UnitType',old,new)
        else:companions(d,'Building_','BuildingType',old,new)
    for table,rows in snapshot.items():
        current=[tuple(r) for r in d.execute('SELECT * FROM '+table+" WHERE Type NOT LIKE '%PIGEON_%' ORDER BY ID")]
        assert current==rows,('unexpected native/Boundless mutation',table)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,1)
    assert d.execute('SELECT CivilizationType FROM Civilization_UnitClassOverrides WHERE UnitType=?',(UNIT,)).fetchone()[0]==CIV
    assert d.execute('SELECT CivilizationType FROM Civilization_BuildingClassOverrides WHERE BuildingType=?',(ROOST,)).fetchone()[0]==CIV
    assert d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]==24
    assert d.execute("SELECT Count FROM Civilization_FreeUnits WHERE CivilizationType=? AND UnitClassType='UNITCLASS_SETTLER'",(CIV,)).fetchone()[0]==1
    promotions=d.execute('SELECT p.* FROM Unit_FreePromotions f JOIN UnitPromotions p ON p.Type=f.PromotionType WHERE f.UnitType=?',(UNIT,)).fetchall()
    base=d.execute("SELECT SUM(p.VisibilityChange) FROM Unit_FreePromotions f JOIN UnitPromotions p ON p.Type=f.PromotionType WHERE f.UnitType='UNIT_SCOUT'").fetchone()[0]
    assert sum(p['VisibilityChange'] for p in promotions)==(base or 0)+1
    assert sum(p['IgnoreTerrainCost'] for p in promotions)==1,'redundant ignore-terrain promotions'
    for suffix,yield_type,value in [('ROUTE_SCIENCE','SCIENCE',1),('ROUTE_CULTURE','CULTURE',1),('ROOST_PRODUCTION','PRODUCTION',2)]:
        row=d.execute('SELECT * FROM Buildings WHERE Type=?',('BUILDING_PIGEON_'+suffix,)).fetchone()
        assert (row['Cost'],row['FaithCost'],row['GreatWorkCount'],row['NeverCapture'],row['IsDummy'],row['ShowInPedia'],row['ConquestProb'])==(-1,-1,-1,1,1,0,0)
        assert row['GoldMaintenance']==0 and row['PrereqTech'] is None and row['ObsoleteTech'] is None
        assert d.execute('SELECT Yield FROM Building_YieldChanges WHERE BuildingType=? AND YieldType=?',(row['Type'],'YIELD_'+yield_type)).fetchone()[0]==value
    for key,value in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_PIGEON_'+key,)).fetchone()[0]==value
    # Check every exact Pigeon TXT_KEY reference and diplomacy wildcard against actual text.
    for path in (V/'SQL').glob('*.sql'):
        for key in set(re.findall(r"'(TXT_KEY_PIGEON_[^']+)'",path.read_text())):
            if key in ['TXT_KEY_PIGEON_CIV5','TXT_KEY_PIGEON_COO']:continue # Civilopedia prefixes
            assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(key,)).fetchone(),key
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',ROOST)]:
        row=d.execute('SELECT * FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(row['IconAtlas'],row['PortraitIndex'])).fetchone()
    for (name,) in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'PIGEON_%'"):assert (V/'Art'/name).is_file(),name
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    # Future scalar CP changes are copied at activation, and supported companion data stays intact.
    modified=database()
    modified.executescript("ALTER TABLE Buildings ADD PIGEON_TestScalar INTEGER DEFAULT 0; ALTER TABLE Units ADD PIGEON_TestScalar INTEGER DEFAULT 0; UPDATE Buildings SET Cost=177,GoldMaintenance=3,TradeRouteLandDistanceModifier=83,PIGEON_TestScalar=71 WHERE Type='BUILDING_CARAVANSARY'; UPDATE Units SET Moves=4,BaseSightRange=5,PIGEON_TestScalar=23 WHERE Type='UNIT_SCOUT'; INSERT INTO Building_YieldChanges VALUES ('BUILDING_CARAVANSARY','YIELD_CULTURE',4);")
    apply(modified)
    assert tuple(modified.execute('SELECT Cost,GoldMaintenance,TradeRouteLandDistanceModifier,PIGEON_TestScalar FROM Buildings WHERE Type=?',(ROOST,)).fetchone())==(177,3,83,71)
    assert tuple(modified.execute('SELECT Moves,BaseSightRange,PIGEON_TestScalar FROM Units WHERE Type=?',(UNIT,)).fetchone())==(4,5,23)
    assert modified.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_CULTURE'",(ROOST,)).fetchone()[0]==5
    print('PASS Pigeon actual-schema SQL, full inheritance, extra CP scalar fields, additive Culture, isolated identifiers, localization, art and dummy safeguards')
    return d

def gameplay(d):
    lua=LuaRuntime()
    module=(V/'UI/PigeonTrade.lua').read_text(encoding='utf-8')
    lua.execute((R/'tools/tests/pigeon_mock.lua').read_text(encoding='utf-8'))
    lua.globals().LoadPigeons=lambda:lua.execute(module)
    lua.execute((R/'tools/tests/pigeon_assertions.lua').read_text(encoding='utf-8'))
    # Connect counts from the running module to actual SQL yield definitions.
    city=lua.globals().Players[1].cities[1]
    actual={}
    for building,index in [('ROUTE_SCIENCE',101),('ROUTE_CULTURE',102),('ROOST_PRODUCTION',103)]:
        for row in d.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',('BUILDING_PIGEON_'+building,)):
            actual[row[0]]=actual.get(row[0],0)+row[1]*city.buildings[index]
    assert actual=={'YIELD_SCIENCE':6,'YIELD_CULTURE':6,'YIELD_PRODUCTION':0}
    for speed in ['GAMESPEED_QUICK','GAMESPEED_STANDARD','GAMESPEED_EPIC','GAMESPEED_MARATHON','GAMESPEED_PIGEON_TEST_CUSTOM']:
        runtime=LuaRuntime();runtime.execute((R/'tools/tests/pigeon_mock.lua').read_text())
        runtime.execute('Game={GetGameSpeedType=function() return "'+speed+'" end}')
        runtime.globals().LoadPigeons=lambda:runtime.execute(module)
        runtime.execute((R/'tools/tests/pigeon_assertions.lua').read_text())
    print('PASS Pigeon Lua 5.1 simulations: stacking, domestic/international/sea, owner/ID collisions, AI, era, capture, razing, elimination, route lifecycle, building removal, save/load, dirty storms and 5 speeds')

def sources():
    reference=R/'tools/reference'
    names=['CvLuaPlayer.cpp','CvLuaCity.cpp','CvTradeClasses.cpp','CvBuildingClasses.cpp','CvCity.cpp','CvUnit.cpp','CustomMods.h']
    if not all((reference/name).is_file() for name in names):
        print('SKIP Pigeon source contracts: run tools/audit_cp.py --fetch first');return
    source={name:(reference/name).read_text(encoding='utf-8-sig') for name in names}
    def body(name,signature):
        text=source[name];start=text.index(signature)
        return text[start:text.index('\n}',start)+2]
    routes=body('CvLuaPlayer.cpp','int CvLuaPlayer::lGetTradeRoutes(')
    checks={
        'outgoing ownership filter':'pConnection->m_eOriginOwner != pkPlayer->GetID()' in routes,
        'integer domain':bool(re.search(r'lua_pushinteger\(L, pConnection->m_eDomain\);\s*lua_setfield\(L, t, "Domain"\)',routes)),
        'FromID is owner':bool(re.search(r'lua_pushinteger\(L\s*, pkPlayer->GetID\(\)\);\s*lua_setfield\(L, t, "FromID"\)',routes)),
        'FromCity is userdata':'CvLuaCity::Push(L, pFromCity);' in routes,
        'no count clamp':'return std::max(GetNumRealBuilding(eIndex), GetNumFreeBuilding(eIndex));' in body('CvBuildingClasses.cpp','int CvCityBuildings::GetNumBuilding('),
        'count delta processed':'processBuilding(eIndex, iChangeNumRealBuilding' in body('CvBuildingClasses.cpp','void CvCityBuildings::SetNumRealBuildingTimed('),
        'yield times count':'pBuildingInfo->GetYieldChange(eYield) + m_pCityBuildings->GetBuildingYieldChange(eBuildingClass, eYield)) * iChange' in source['CvCity.cpp'],
        'no-bonus Lua argument':'const bool bNoBonus = luaL_optbool(L, 4, true)' in source['CvLuaCity.cpp'],
        'completion before clear':bool(re.search(r'GAMEEVENTINVOKE_HOOK\(GAMEEVENT_PlayerTradeRouteCompleted.*?ClearTradeRoute\(ui\)',source['CvTradeClasses.cpp'],re.S)),
        'plunder signature':'GAMEEVENT_PlayerPlunderedTradeRoute, pUnit->getOwner(), pUnit->GetID(), iPlunderGoldValue, pOriginCity->getOwner()' in source['CvTradeClasses.cpp'],
        'route established before unit consumed':bool(re.search(r'CreateTradeRoute\(pFromCity.*?if \(bResult\)\s*kill\(true\)',body('CvUnit.cpp','bool CvUnit::makeTradeRoute('),re.S)),
        'UnitPrekill signature':'GAMEEVENT_UnitPrekill, eUnitOwner, GetID(), getUnitType()' in source['CvUnit.cpp'],
        'correct completion event name':'"PlayerTradeRouteCompleted"' in source['CustomMods.h'],
        'dummy excluded from building total':'if(!buildingEntry->IsDummy())' in source['CvBuildingClasses.cpp'],
    }
    assert all(checks.values()),[name for name,value in checks.items() if not value]
    result={'commit':'44c1e14ff75d80c1dba5c8a71e8289439a53aafb','checks':checks,
            'sha256':{name:hashlib.sha256((reference/name).read_bytes()).hexdigest() for name in names}}
    (V/'docs').mkdir(parents=True,exist_ok=True)
    (V/'docs/SourceAudit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('PASS',len(checks),'Pigeon pinned CP v151 route/building/event source contracts')

def validate():
    d=sql();gameplay(d);sources()

if __name__=='__main__':validate()
