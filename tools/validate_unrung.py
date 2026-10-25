"""Real-schema SQL + shipped Lua 5.1 lifecycle simulations. Never launches Civ V."""
from collections import Counter
import hashlib
import json
import math
import re
import struct
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote, is_cp_cache
from build_mod import files, ENTRIES, imported, NAME
from generate_unrung import R, V, CIV, LEADER, UNIT, BELFRY, GUARD, TIERS, TEXT, CITIES

SUITES = ['unrung_quietude.lua','unrung_wars.lua','unrung_timing.lua','unrung_lifecycle.lua','unrung_safety.lua','unrung_recovery.lua']

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')): d.executescript(p.read_text(encoding='utf-8'))

def yields(d,building):
    return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType',(building,)))

def inheritance(d):
    count=0
    metadata={'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'}
    for table,old,new,prefix,col in [('Units','UNIT_PIKEMAN',UNIT,'Unit','UnitType'),('Buildings','BUILDING_TEMPLE',BELFRY,'Building','BuildingType')]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for key in a.keys():
            if key not in metadata: assert a[key]==b[key],(table,key,a[key],b[key])
        for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in cols: continue
            fields=[c for c in cols if c not in [col,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(t)+' WHERE '+col+'=?'
            left=Counter(tuple(r) for r in d.execute(query,(old,)))
            right=Counter(tuple(r) for r in d.execute(query,(new,)))
            if t=='Building_YieldChanges':
                expected=yields(d,old);expected['YIELD_CULTURE']=expected.get('YIELD_CULTURE',0)+1
                assert expected==yields(d,new)
            elif t=='Unit_FreePromotions':
                assert right-left==Counter({(GUARD,):1}) and not left-right
            else: assert left==right,('companion',t,left-right,right-left)
            count+=1
    return count

def sql():
    d=database()
    for p in files():
        if p.suffix=='.sql' and V not in p.parents: d.executescript(p.read_text(encoding='utf-8'))
    tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables if t!='CustomModOptions'}
    options=dict(d.execute('SELECT Name,Value FROM CustomModOptions'))
    apply(d)
    for t,rows in before.items(): assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('modified released row',t)
    enabled={'EVENTS_PLAYER_TURN','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES','EVENTS_CITY','EVENTS_CITY_FOUNDING'}
    for name,value in options.items(): assert d.execute('SELECT Value FROM CustomModOptions WHERE Name=?',(name,)).fetchone()[0]==(1 if name in enabled else value)
    companion_count=inheritance(d)
    assert d.execute('SELECT Playable,AIPlayable,DawnOfManAudio FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[:]==(1,0,'')
    assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_PIKEMAN')).fetchone()[0]==UNIT
    assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_TEMPLE')).fetchone()[0]==BELFRY
    for i,tier in enumerate(TIERS,1):
        p=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',('PROMOTION_UNRUNG_GREAT_TOLL_'+tier,)).fetchone()
        assert (p['FriendlyLandsModifier'],p['CombatPercent'],p['FriendlyLandsAttackModifier'],p['CannotBeChosen'],p['LostWithUpgrade'])==(i*5,0,0,1,1)
        for kind,y in [('QUIETUDE','CULTURE'),('SCIENCE','SCIENCE')]:
            name=f'BUILDING_UNRUNG_{kind}_{tier}';b=d.execute('SELECT * FROM Buildings WHERE Type=?',(name,)).fetchone()
            for key,val in {'Cost':-1,'FaithCost':-1,'GoldMaintenance':0,'IsDummy':1,'ShowInPedia':0,'NeverCapture':1,'ConquestProb':0,'GreatWorkCount':-1,'Defense':0,'Happiness':0,'SpecialistCount':0}.items(): assert b[key]==val,(name,key)
            assert b['PrereqTech'] is None and yields(d,name)=={'YIELD_'+y:1}
    p=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',(GUARD,)).fetchone()
    assert (p['FriendlyLandsModifier'],p['VisibilityChange'],p['LostWithUpgrade'],p['CombatPercent'],p['FriendlyLandsAttackModifier'])==(15,1,0,0,0)
    assert len(CITIES)==len(set(CITIES))==d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]
    keys={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
    for key,value in TEXT.items(): assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_UNRUNG_'+key,)).fetchone()[0]==value
    for path in (V/'SQL').glob('*.sql'):
        for key in re.findall(r"'(TXT_KEY_UNRUNG_[A-Z_0-9%]+)'",path.read_text(encoding='utf-8')):
            assert key in keys or any(k.startswith(key.rstrip('%')) for k in keys),key
    changed=database()
    changed.executescript("""ALTER TABLE Units ADD UNRUNG_Test INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD UNRUNG_Test INTEGER DEFAULT 0;
UPDATE Units SET Combat=33,Moves=4,Cost=321,UNRUNG_Test=41 WHERE Type='UNIT_PIKEMAN';
UPDATE Buildings SET Cost=213,GoldMaintenance=4,UNRUNG_Test=71 WHERE Type='BUILDING_TEMPLE';
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_PIKEMAN','PROMOTION_AMPHIBIOUS');
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_TEMPLE','YIELD_CULTURE',4),('BUILDING_TEMPLE','YIELD_SCIENCE',2);
UPDATE UnitGameplay2DScripts SET SelectionSound='AS2D_SELECT_SETTLER' WHERE UnitType='UNIT_PIKEMAN';
""")
    apply(changed);inheritance(changed)
    assert changed.execute('SELECT Combat,Moves,Cost,UNRUNG_Test FROM Units WHERE Type=?',(UNIT,)).fetchone()[:]==(33,4,321,41)
    assert changed.execute('SELECT UNRUNG_Test FROM Buildings WHERE Type=?',(BELFRY,)).fetchone()[0]==71
    assert changed.execute('SELECT SelectionSound FROM UnitGameplay2DScripts WHERE UnitType=?',(UNIT,)).fetchone()[0]=='AS2D_SELECT_SETTLER'
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    cache=R.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
    active=cache.exists() and is_cp_cache(cache)
    print('PASS Unrung SQL: human-only, all released rows preserved,',companion_count,'companion tables, changed-baseline inheritance, exact yields/promotions/text')
    return d,{'companion_tables':companion_count,'cp_activated_live_cache':bool(active)}

def sources(fetch=False):
    from audit_cp import COMMIT,BASE
    names=['CustomMods.h','CvUnit.cpp','CvTeam.cpp','CvPlayer.cpp','CvPlot.cpp','CvPromotionClasses.cpp','CvLuaUnit.cpp','CvLuaPlayer.cpp']
    if fetch:
        import urllib.request
        from concurrent.futures import ThreadPoolExecutor
        def download(name):
            url=BASE+('Lua/' if name.startswith('CvLua') else '')+name
            (R/'tools/reference'/name).write_bytes(urllib.request.urlopen(url,timeout=45).read())
        (R/'tools/reference').mkdir(exist_ok=True)
        with ThreadPoolExecutor(max_workers=4) as pool: list(pool.map(download,names))
    data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    def body(name,signature):
        text=data[name];start=text.index(signature);return text[start:text.index('\n}',start)+2]
    war=body('CvTeam.cpp','void CvTeam::setAtWar(')
    melee=body('CvUnit.cpp','int CvUnit::GetGenericMeleeStrengthModifier(')
    ranged=body('CvUnit.cpp','int CvUnit::GetMaxRangedCombatStrength(')
    friendly=body('CvPlot.cpp','bool CvPlot::IsFriendlyTerritory(')
    contracts={
      'DLL v151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',data['CustomMods.h'])),
      'war notification after native one-side flag write':war.index('m_abAtWar[eIndex] = bNewValue')<war.index('GameplayWarStateChanged(GetID(), eIndex, bNewValue)'),
      'prechange declaration hook is not used':'GAMEEVENT_DeclareWar' in data['CvTeam.cpp'],
      'melee modifier checks battle plot':'pBattlePlot->IsFriendlyTerritory(getOwner())' in melee and 'iModifier += getFriendlyLandsModifier();' in melee,
      'ranged modifier checks shooter plot':'pMyPlot->IsFriendlyTerritory(getOwner())' in ranged and 'iModifier += getFriendlyLandsModifier();' in ranged,
      'friendly territory includes open borders':'IsAllowsOpenBordersToTeam' in friendly and 'IsPlayerHasOpenBorders' in friendly,
      'promotion modifiers accumulate additively':'m_iFriendlyLandsModifier += iChange;' in data['CvUnit.cpp'],
      'promotion field loaded':'GetInt("FriendlyLandsModifier")' in data['CvPromotionClasses.cpp'],
      'permanent promotion upgrade flag read':'IsLostWithUpgrade()' in data['CvUnit.cpp'],
      'conversion event follows promotion copy':body('CvUnit.cpp','void CvUnit::convert(').index('setHasPromotion(ePromotion, bGivePromotion)') < body('CvUnit.cpp','void CvUnit::convert(').index('GAMEEVENT_UnitConverted'),
      'turn-active Lua binding':'Method(IsTurnActive)' in data['CvLuaPlayer.cpp'],
    }
    for name,sig in {'PlayerDoneTurn':'i','UnitCreated':'iiiii','UnitConverted':'iiiib','UnitUpgraded':'iiib','CityConstructed':'iiibb','CitySoldBuilding':'iii','CityRazed':'iii'}.items():
        contracts['ABI '+name]=bool(re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+sig+'"',data['CustomMods.h']))
    for key,ok in contracts.items(): assert ok,key
    report={'official_commit':COMMIT,'native_gameplay':'NOT TESTED IN GAME','contracts':contracts,
            'verified_limitations':['FriendlyLandsModifier includes same-team and open-border territory, not exclusive player ownership.','Ranged friendly-land strength uses shooter plot, not target plot. Exact requested combat semantics require a DLL change.'],
            'sources':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS',len(contracts),'pinned CP v151 source contracts; ownership/ranged limitations confirmed')

def runtime():
    for suite in SUITES:
        lua=LuaRuntime()
        source=(V/'Lua/UnrungBell.lua').read_text(encoding='utf-8')
        lua.globals().LoadUnrung=lambda:lua.execute(source)
        lua.execute((R/'tools/tests/unrung_mock.lua').read_text(encoding='utf-8'))
        lua.execute((R/'tools/tests'/suite).read_text(encoding='utf-8'))

def art(d):
    for p in V.rglob('*.xml'): ET.parse(p)
    lua=LuaRuntime();check=lua.eval('function(s) local f,e=loadstring(s);assert(f,e) end')
    for p in list(V.rglob('*.lua'))+list((R/'tools/tests').glob('unrung_*.lua')):check(p.read_text(encoding='utf-8'))
    for row in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'UNRUNG_%'"):
        p=V/'Art'/row['Filename']
        with Image.open(p) as im:
            im.load();assert im.size==(row['IconSize']*int(row['IconsPerRow']),row['IconSize']*int(row['IconsPerColumn'])),(p,im.size,tuple(row))
    for p in (V/'Art').glob('*.dds'):
        with Image.open(p) as im: im.load()
        header=p.read_bytes()[:128]
        height,width=struct.unpack_from('<II',header,12)
        assert struct.unpack_from('<I',header,28)[0]==1+int(math.log2(max(width,height))),(p,'missing mip chain')
    for table in ['Civilizations','Leaders','Units','Buildings','UnitPromotions']:
        for atlas,index in d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+" WHERE Type LIKE '%UNRUNG%'"):
            assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND CAST(IconsPerRow AS INTEGER)*CAST(IconsPerColumn AS INTEGER)>?',(atlas,index)).fetchone(),(table,atlas,index)
    scene=ET.parse(V/'Art/UNRUNG_LeaderScene.xml').getroot()
    assert (V/'Art'/scene.get('FallbackImage')).is_file()
    assert sum(e[0]=='KingdomOfTheUnrungBell/Lua/UnrungBell.xml' for e in ENTRIES)==1
    assert not imported(V/'Lua/UnrungBell.xml') and imported(V/'Lua/UnrungBell.lua')
    source=(V/'Lua/UnrungBell.lua').read_text(encoding='utf-8')
    for token in ['SetUpdate','GetNumPlots','GetPlotByIndex','ChangeJONSCulture','ChangeResearchProgress']:
        assert token not in source,token
    assert 'PROMOTION_UNRUNG_BELLWARDEN' not in source.replace('-- Never touch PROMOTION_UNRUNG_BELLWARDEN or any other permanent promotion.','')
    print('PASS Lua 5.1 syntax, XML, every DDS decode/atlas size, single entry and VFS policy; no frame/map polling')

def validate():
    import sys
    d,report=sql();sources('--fetch' in sys.argv);runtime();art(d)
    report.update(static='PASS',lua51_mock_suites=SUITES,native_gameplay='NOT TESTED IN GAME',
                  status='Implementation preview; exact owned-target combat semantics blocked by native CP modifier behavior',
                  manual='Native yields, saves/autosaves, event timing, combat previews, strategic view and selection/rendering remain pending.')
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__': validate()
