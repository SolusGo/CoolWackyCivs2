"""Real-schema SQL, pinned source contracts and Lua 5.1 models; NOT game tests."""
from pathlib import Path
from collections import Counter
import hashlib, json, re, sqlite3
from xml.etree import ElementTree as ET
from lupa.lua51 import LuaRuntime
from database import database, quote
from generate_twelfth import R, V, CIV, LEADER, UNIT, TOWER, TEXT, CITIES

def apply(d):
    for path in sorted((V/'SQL').glob('*.sql')):
        d.executescript(path.read_text(encoding='utf-8'))

def inherited(d,table,old,new,allowed):
    a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
    b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
    for col in a.keys():
        if col not in allowed: assert a[col]==b[col],(table,col,a[col],b[col])
    prefix,owner=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
    for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
        cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
        if not name.startswith(prefix) or owner not in cols: continue
        fields=[c for c in cols if c not in [owner,'ID']]
        query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(name)+' WHERE '+quote(owner)+'=?'
        original=Counter(tuple(r) for r in d.execute(query,(old,)))
        unique=Counter(tuple(r) for r in d.execute(query,(new,)))
        if name=='Building_YieldChanges':
            def noCulture(rows): return Counter({r:n for r,n in rows.items() if r[fields.index('YieldType')]!='YIELD_CULTURE'})
            original,unique=noCulture(original),noCulture(unique)
        if name=='Unit_FreePromotions':
            unique=Counter({r:n for r,n in unique.items() if r[fields.index('PromotionType')]!='PROMOTION_TWELFTH_PENDULUM'})
        assert original==unique,('companion inheritance',name,original-unique,unique-original)

def sql():
    d=database()
    # Snapshot EVERY preexisting table row; optional event values are the sole exception.
    tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables if t!='CustomModOptions'}
    apply(d)
    for t,rows in before.items():
        assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('modified existing rows',t)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    inherited(d,'Units','UNIT_PIKEMAN',UNIT,{'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'})
    inherited(d,'Buildings','BUILDING_WORKSHOP',TOWER,{'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'})
    p=d.execute("SELECT * FROM UnitPromotions WHERE Type='PROMOTION_TWELFTH_PENDULUM'").fetchone()
    assert (p['MovesChange'],p['FriendlyLandsModifier'],p['FriendlyLandsAttackModifier'],p['LostWithUpgrade'],p['CannotBeChosen'])==(1,15,0,0,1)
    def bonus(unit,col):
        return d.execute('SELECT COALESCE(SUM(p.'+col+'),0) FROM Unit_FreePromotions f JOIN UnitPromotions p ON p.Type=f.PromotionType WHERE f.UnitType=?',(unit,)).fetchone()[0]
    assert bonus(UNIT,'MovesChange')==bonus('UNIT_PIKEMAN','MovesChange')+1
    assert bonus(UNIT,'FriendlyLandsModifier')==bonus('UNIT_PIKEMAN','FriendlyLandsModifier')+15
    def culture(building):
        return d.execute("SELECT COALESCE(SUM(Yield),0) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_CULTURE'",(building,)).fetchone()[0]
    assert culture(TOWER)==culture('BUILDING_WORKSHOP')+1
    assert dict(d.execute("SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType='BUILDING_TWELFTH_GRAND_CHIME'"))=={'YIELD_PRODUCTION':75,'YIELD_SCIENCE':50}
    assert [tuple(r) for r in d.execute("SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_TWELFTH_CLOCKTOWER_CHIME'")]==[('YIELD_PRODUCTION',2)]
    for suffix in ['GRAND_CHIME','CLOCKTOWER_CHIME']:
        row=d.execute('SELECT * FROM Buildings WHERE Type=?',('BUILDING_TWELFTH_'+suffix,)).fetchone()
        assert tuple(row[k] for k in ['Cost','FaithCost','GreatWorkCount','NeverCapture','IsDummy','ShowInPedia','ConquestProb','GoldMaintenance'])==(-1,-1,-1,1,1,0,0,0)
        assert row['PrereqTech'] is None and row['ObsoleteTech'] is None
    assert [r[0] for r in d.execute('SELECT CityName FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,))]==['TXT_KEY_TWELFTH_CITY_'+str(i) for i in range(1,len(CITIES)+1)]
    assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_PIKEMAN')).fetchone()[0]==UNIT
    assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_WORKSHOP')).fetchone()[0]==TOWER
    for key,value in TEXT.items():
        assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_TWELFTH_'+key,)).fetchone()[0]==value
    refs=set()
    for path in list((V/'SQL').glob('*.sql'))+list(V.rglob('*.lua')):
        refs.update(re.findall(r"['\"](TXT_KEY_TWELFTH_[A-Z_0-9%]+)['\"]",path.read_text(encoding='utf-8')))
    for key in refs-{'TXT_KEY_TWELFTH_CIV5','TXT_KEY_TWELFTH_KEEPER'}:
        assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag LIKE ?',(key,)).fetchone(),key
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    # Activate against changed CP baselines: new scalar fields and existing Culture survive.
    altered=database()
    altered.executescript("ALTER TABLE Buildings ADD TWELFTH_TestScalar INTEGER DEFAULT 0; ALTER TABLE Units ADD TWELFTH_TestScalar INTEGER DEFAULT 0; UPDATE Buildings SET Cost=177,SpecialistCount=3,TWELFTH_TestScalar=71 WHERE Type='BUILDING_WORKSHOP'; UPDATE Units SET Moves=4,TWELFTH_TestScalar=23 WHERE Type='UNIT_PIKEMAN'; INSERT INTO Building_YieldChanges VALUES ('BUILDING_WORKSHOP','YIELD_CULTURE',4);")
    apply(altered)
    assert tuple(altered.execute('SELECT Cost,SpecialistCount,TWELFTH_TestScalar FROM Buildings WHERE Type=?',(TOWER,)).fetchone())==(177,3,71)
    assert tuple(altered.execute('SELECT Moves,TWELFTH_TestScalar FROM Units WHERE Type=?',(UNIT,)).fetchone())==(4,23)
    assert altered.execute("SELECT SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? AND YieldType='YIELD_CULTURE'",(TOWER,)).fetchone()[0]==5
    # A read-only copy of the actual current cache, including all currently active mods.
    cache=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
    if cache.exists():
        source=sqlite3.connect(cache.resolve().as_uri()+'?mode=ro',uri=True)
        active=sqlite3.connect(':memory:');source.backup(active);source.close()
        assert not active.execute('SELECT 1 FROM Civilizations WHERE Type=?',(CIV,)).fetchone(),'cache already includes Twelfth Hour; use a clean cache for activation test'
        # Civ V routes Language_* updates through its localization database;
        # the gameplay cache alone need not contain that table.
        active.execute('CREATE TABLE IF NOT EXISTS Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
        apply(active);active.row_factory=sqlite3.Row
        inherited(active,'Units','UNIT_PIKEMAN',UNIT,{'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'})
        inherited(active,'Buildings','BUILDING_WORKSHOP',TOWER,{'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'})
        print('PASS SQL activation and full replacement inheritance on a read-only copy of the active game cache')
    print('PASS Twelfth SQL: all prior rows preserved, human-only flags, full inheritance, additive Culture, exact modifiers, promotion, safe dummies, localization')
    return d

def gameplay(d):
    modifiers=dict(d.execute("SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType='BUILDING_TWELFTH_GRAND_CHIME'"))
    flat=d.execute("SELECT Yield FROM Building_YieldChanges WHERE BuildingType='BUILDING_TWELFTH_CLOCKTOWER_CHIME'").fetchone()[0]
    source=(V/'Lua/TWELFTH_Chime.lua').read_text(encoding='utf-8')
    for speed in ['QUICK','STANDARD','EPIC','MARATHON','CUSTOM']:
        for start in [0,150]:
            lua=LuaRuntime()
            lua.execute((R/'tools/tests/twelfth_mock.lua').read_text(encoding='utf-8'))
            lua.globals().startTurn=start;lua.globals().rawTurn=start
            lua.globals().Game.GetGameSpeedType=lambda:speed
            lua.globals().LoadTwelfth=lambda:lua.execute(source)
            # Illustration only. No claim this arithmetic replaces native yield behavior.
            lua.globals().Harvest=lua.eval('function(c) return (c.baseProduction+c.buildings[102]*'+str(flat)+')*(1+c.buildings[101]*'+str(modifiers['YIELD_PRODUCTION'])+'/100), c.baseScience*(1+c.buildings[101]*'+str(modifiers['YIELD_SCIENCE'])+'/100) end')
            lua.execute((R/'tools/tests/twelfth_assertions.lua').read_text(encoding='utf-8'))
    print('PASS 10 Twelfth Lua 5.1 runs: five speeds, two saved start turns; SQL-backed harvest model, NOT native gameplay')

def sources():
    from audit_cp import COMMIT, BASE
    names=['CvPlayer.cpp','CvCity.cpp','CvBuildingClasses.cpp','CvUnit.cpp','CvGame.cpp','CvLuaCity.cpp','CvLuaGame.cpp','CustomMods.h']
    data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    def body(n,signature):
        s=data[n];start=s.index(signature);return s[start:s.index('\n}',start)+2]
    turn=body('CvPlayer.cpp','void CvPlayer::doTurnPostDiplomacy(')
    active=body('CvPlayer.cpp','void CvPlayer::setTurnActive(')
    research=body('CvPlayer.cpp','void CvPlayer::doResearch(')
    checks={
     'DLL v151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',data['CustomMods.h'])),
     'city harvest then research then PlayerDoTurn':turn.index('pLoopCity->doTurn();')<turn.index('doResearch();')<turn.index('"PlayerDoTurn"'),
     'PlayerDoneTurn during deactivation':active.index('// TURN IS ENDING')<active.index('GAMEEVENT_PlayerDoneTurn'),
     'PlayerDoneTurn gated by EVENTS_PLAYER_TURN':'if (MOD_EVENTS_PLAYER_TURN)' in active,
     'PlayerDoneTurn ABI':bool(re.search(r'GAMEEVENT_PlayerDoneTurn\s+"PlayerDoneTurn",\s+"i"',data['CustomMods.h'])),
     'city production uses normal yield rate':'changeProductionTimes100(getYieldRateTimes100(YIELD_PRODUCTION) + getTotalOverflowProductionTimes100());' in body('CvCity.cpp','void CvCity::doProduction('),
     'research credits real progress':'GetScienceTimes100() + iOverflowResearch' in research and 'ChangeResearchProgressTimes100(eCurrentTech, iBeakersTowardsTechTimes100' in research,
     'player research includes city yields':'getYieldRateTimes100(YIELD_SCIENCE, bIgnoreTrade)' in body('CvPlayer.cpp','int CvPlayer::GetScienceFromCitiesTimes100('),
     'building yield modifier changes native city modifier':'changeYieldRateModifier(eYield, (pBuildingInfo->GetYieldModifier(eYield) * iChange));' in data['CvCity.cpp'],
     'building changes process native yields':'m_pCity->processBuilding(eIndex, iChangeNumRealBuilding' in body('CvBuildingClasses.cpp','void CvCityBuildings::SetNumRealBuildingTimed('),
     'real building setter supports no construction rewards':'const bool bNoBonus = luaL_optbool(L, 4, true)' in data['CvLuaCity.cpp'],
     'friendly territory strength is common modifier':'if(pBattlePlot->IsFriendlyTerritory(getOwner()))\n\t\t{\n\t\t\tiModifier += getFriendlyLandsModifier();' in data['CvUnit.cpp'],
     'friendly modifier also used in ranged/general strength':'if (pMyPlot->IsFriendlyTerritory(getOwner()))\n\t\t{\n\t\t\tiModifier += getFriendlyLandsModifier();' in data['CvUnit.cpp'],
     'saved raw game turn increments once':'setGameTurn(getGameTurn() + 1);' in body('CvGame.cpp','void CvGame::incrementGameTurn('),
     'start turn bound for advanced starts':'Method(GetStartTurn);' in data['CvLuaGame.cpp'],
     'game start turn initialized from actual turn':'setStartTurn(getGameTurn());' in data['CvGame.cpp'],
     'dummy excluded from normal building totals':'if(!buildingEntry->IsDummy())' in data['CvBuildingClasses.cpp'],
    }
    assert all(checks.values()),[k for k,v in checks.items() if not v]
    report={'commit':COMMIT,'dll_version':151,'scope':'source contracts, NOT launched-game verification','checks':checks,
            'sources':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,
                          'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS',len(checks),'pinned CP v151 Twelfth turn/yield/promotion source contracts')

def art(d):
    from PIL import Image
    for atlas,size,filename,columns,rows in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'TWELFTH_%'"):
        with Image.open(V/'Art'/filename) as im:
            im.load();assert im.size==(size*int(columns),size*int(rows)),(filename,im.size)
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',TOWER),('UnitPromotions','PROMOTION_TWELFTH_PENDULUM')]:
        row=d.execute('SELECT * FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(row['IconAtlas'],row['PortraitIndex'])).fetchone()
    assert ET.parse(V/'Art/TWELFTH_LeaderScene.xml').getroot().get('FallbackImage')=='TWELFTH_Leader.dds'
    for name in ['TWELFTH_Dawn.dds','TWELFTH_Map.dds','TWELFTH_Leader.dds']:
        with Image.open(V/'Art'/name) as im: im.load()
    print('PASS Twelfth DDS decoding, atlas dimensions/capacity, unit flag, leader scene, Dawn of Man and map assets')

def validate():
    d=sql();gameplay(d);sources();art(d)

if __name__=='__main__':
    validate()
