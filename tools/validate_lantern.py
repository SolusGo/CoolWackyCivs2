"""Lantern SQL, active inheritance, Lua51 scenarios, art and source evidence.

This validator does NOT certify executable event dispatch or economic payouts.
"""
from collections import Counter
import hashlib
import json
import math
import re
import struct
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote
from build_mod import files, imported, NAME, NS
from generate_lantern import R, V, CIV, LEADER, UNIT, LIGHTHOUSE, DUMMIES, TEXT, CITIES
from validation_prerequisites import inspect_database, require_sources, inspect_game, CP_COMMIT


def apply(d):
    for path in sorted((V/'SQL').glob('*.sql')):
        d.executescript(path.read_text(encoding='utf-8'))


def yields(d, building):
    return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType',(building,)))


def inheritance(d):
    count = 0
    metadata = {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}
    for table,old,new,prefix,key,allowed in [
        ('Units','UNIT_TRIREME',UNIT,'Unit','UnitType',metadata|{'UnitFlagAtlas','UnitFlagIconOffset'}),
        ('Buildings','BUILDING_LIGHTHOUSE',LIGHTHOUSE,'Building','BuildingType',metadata)]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for field in a.keys():
            if field not in allowed: assert a[field]==b[field],(table,field,a[field],b[field])
        for companion, in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            columns=[r[1] for r in d.execute('PRAGMA table_info('+quote(companion)+')')]
            if not companion.startswith(prefix) or key not in columns: continue
            fields=[c for c in columns if c not in [key,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(companion)+' WHERE '+key+'=?'
            left=Counter(tuple(r) for r in d.execute(query,(old,)))
            right=Counter(tuple(r) for r in d.execute(query,(new,)))
            if companion=='Unit_FreePromotions':
                assert right[('PROMOTION_LANTERN_FRIENDLY_WATERS',)]==1
                right.subtract({('PROMOTION_LANTERN_FRIENDLY_WATERS',):1});right=+right
            if companion=='Building_YieldChanges':
                expected=yields(d,old);expected['YIELD_CULTURE']=expected.get('YIELD_CULTURE',0)+1
                assert yields(d,new)==expected
            else: assert left==right,(companion,left-right,right-left)
            count+=1
    return count


def sql_checks():
    d=database()
    for path in files():
        if path.suffix=='.sql' and path.relative_to(R).parts[0]!='TheLanternFleet':
            d.executescript(path.read_text(encoding='utf-8'))
    before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t)))
            for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall()}
    apply(d)
    for table,rows in before.items():
        assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(table))),('released row changed',table)
    count=inheritance(d)
    assert d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[:]==(1,0)
    assert d.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0]=='TRAIT_LANTERN_NO_HARBOR_DARK'
    assert d.execute('SELECT COUNT(*) FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0]==1
    assert d.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0]==LEADER
    assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_TRIREME')).fetchone()[0]==UNIT
    assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_LIGHTHOUSE')).fetchone()[0]==LIGHTHOUSE
    assert d.execute('SELECT StartAlongOcean FROM Civilization_Start_Along_Ocean WHERE CivilizationType=?',(CIV,)).fetchone()[0]==1
    assert d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]==len(CITIES)
    assert not d.execute("SELECT 1 FROM Civilization_FreeUnits WHERE CivilizationType=? AND UnitClassType='UNITCLASS_TRIREME'",(CIV,)).fetchone()
    promotion=d.execute("SELECT VisibilityChange,FriendlyLandsModifier,OutsideFriendlyLandsModifier,LostWithUpgrade,CannotBeChosen FROM UnitPromotions WHERE Type='PROMOTION_LANTERN_FRIENDLY_WATERS'").fetchone()
    assert promotion[:]==(1,15,0,0,1),tuple(promotion)
    assert list(d.execute("SELECT UnitType FROM Unit_FreePromotions WHERE PromotionType='PROMOTION_LANTERN_FRIENDLY_WATERS'"))[0][0]==UNIT
    for dummy,expected in zip(DUMMIES,[{'YIELD_SCIENCE':2,'YIELD_CULTURE':1},{'YIELD_GOLD':2}]):
        row=d.execute('SELECT * FROM Buildings WHERE Type=?',(dummy,)).fetchone()
        for key,value in {'Cost':-1,'FaithCost':-1,'GreatWorkCount':-1,'NeverCapture':1,'NukeImmune':1,
                          'IsDummy':1,'ShowInPedia':0,'ConquestProb':0,'GoldMaintenance':0,'SpecialistCount':0,'Defense':0,'Happiness':0}.items():
            assert row[key]==value,(dummy,key,row[key])
        assert yields(d,dummy)==expected
    base=yields(d,'BUILDING_LIGHTHOUSE');combined=yields(d,LIGHTHOUSE)
    for dummy in DUMMIES:
        for key,value in yields(d,dummy).items():combined[key]=combined.get(key,0)+value
    for key,value in {'YIELD_SCIENCE':2,'YIELD_CULTURE':2,'YIELD_GOLD':2}.items():
        assert combined.get(key,0)-base.get(key,0)==value
    for key,value in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_LANTERN_'+key,)).fetchone()[0]==value
    for path in (V/'SQL').glob('*.sql'):
        for key in re.findall(r"'(TXT_KEY_LANTERN_[A-Z_0-9%]+)'",path.read_text(encoding='utf-8')):
            assert key.rstrip('%') in {'TXT_KEY_LANTERN_CIV5','TXT_KEY_LANTERN_MAREN'} or any(('TXT_KEY_LANTERN_'+k)==key or ('TXT_KEY_LANTERN_'+k).startswith(key.rstrip('%')) for k in TEXT),key
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    # Mutating unknown scalar and companion values proves runtime SELECT * and
    # additive Culture instead of a clone of hardcoded BNW values.
    altered=database()
    altered.executescript("""ALTER TABLE Units ADD LANTERN_TestScalar INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD LANTERN_TestScalar INTEGER DEFAULT 0;
UPDATE Units SET Combat=27,Moves=7,Cost=123,LANTERN_TestScalar=17 WHERE Type='UNIT_TRIREME';
UPDATE Buildings SET Cost=333,GoldMaintenance=4,LANTERN_TestScalar=23 WHERE Type='BUILDING_LIGHTHOUSE';
INSERT INTO Building_YieldChanges VALUES ('BUILDING_LIGHTHOUSE','YIELD_CULTURE',4);
INSERT INTO Unit_ResourceQuantityRequirements VALUES ('UNIT_TRIREME','RESOURCE_IRON',2);
""")
    apply(altered);inheritance(altered)
    assert altered.execute('SELECT Combat,Moves,Cost,LANTERN_TestScalar FROM Units WHERE Type=?',(UNIT,)).fetchone()[:]==(27,7,123,17)
    assert yields(altered,LIGHTHOUSE)['YIELD_CULTURE']==5
    print('PASS Lantern database, exact yields, active inheritance, changed-baseline probe and unchanged released rows')
    return d,count


def runtime():
    code=(V/'Lua/LANTERN_Harbors.lua').read_text(encoding='utf-8')
    def vm():
        lua=LuaRuntime();lua.globals().LF_LoadSource=lambda:lua.execute(code)
        lua.execute((R/'tools/tests/lantern_mock.lua').read_text(encoding='utf-8'))
        lua.execute((R/'tools/tests/lantern_assertions.lua').read_text(encoding='utf-8'))
        return lua
    names=sorted(vm().globals().LF_Tests.keys())
    for name in names:
        lua=vm()
        try:lua.globals().LF_Tests[name]()
        except Exception as exc:raise AssertionError('Lantern Lua scenario '+name+': '+str(exc)) from exc
    first=vm();first.execute('LF_Load();LF_Guard();LF_Harbor.buildings[2]=1;LF_Start()')
    saved=(first.globals().Players[0].data,dict(first.globals().LF_Harbor.buildings))
    second=vm();second.globals().Players[0].data=saved[0]
    for key,value in saved[1].items():second.globals().LF_Harbor.buildings[key]=value
    second.execute('LF_Turn=11;Players[0].active=true;LF_Load();Events.AIProcessingStartedForPlayer.Fire(0);LF_Counts(1,1);assert(LF_Writes==0);LF_Start();LF_Counts(0,0)')
    names.append('full_VM_restart_only_native_saved_state')
    print('PASS Lantern',len(names),'Lua 5.1 scenarios (simulation, not native timing)')
    return names


def static(d):
    lua=LuaRuntime();check=lua.eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
    for p in list(V.rglob('*.lua'))+list((R/'tools/tests').glob('lantern_*.lua')):check(p.read_text(encoding='utf-8'),str(p))
    for p in V.rglob('*.xml'):ET.parse(p)
    root=ET.parse(R/(NAME+'.modinfo')).getroot()
    assert sum(e.get('file')=='TheLanternFleet/Lua/LANTERN_Harbors.xml' for e in root.findall('EntryPoints/EntryPoint'))==1
    declared={e.text:e for e in root.findall('Files/File')}
    project=ET.parse(R/'CoolWackyCivs2.civ5proj').getroot()
    project_files={e.get('Include') for e in project.findall('{'+NS+'}ItemGroup/{'+NS+'}Content')}
    for p in V.rglob('*'):
        if p.suffix not in ['.sql','.lua','.xml','.dds']:continue
        name=p.relative_to(R).as_posix()
        assert name in declared and name in project_files,name
        assert declared[name].get('import')==str(int(imported(p)))
        assert declared[name].get('md5')==hashlib.md5(p.read_bytes()).hexdigest().upper()
    order=[e.text for e in root.findall('Actions/OnModActivated/UpdateDatabase')]
    assert order[-5:]==[p.relative_to(R).as_posix() for p in sorted((V/'SQL').glob('*.sql'))]
    basenames=Counter(p.name.casefold() for p in files() if imported(p));assert max(basenames.values())==1
    for filename, in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'LANTERN_%'"):assert (V/'Art'/filename).is_file(),filename
    for p in (V/'Art').glob('*.dds'):
        header=p.read_bytes()[:128];assert header[:4]==b'DDS ' and header[84:88]==b'DXT5',p
        with Image.open(p) as im:
            im.load();assert struct.unpack_from('<I',header,28)[0]==int(math.log2(max(im.size)))+1,p
    assert len(list((V/'Art').glob('*.dds')))==40
    for name in ['Leader','Dawn','Map']:assert (V/'Art'/('LANTERN_'+name+'.dds')).is_file()
    print('PASS Lantern Lua syntax, XML, 40 decoded mipmapped DDS textures, registration and localization')


def source_contract():
    names=['CvPlayer.cpp','CvUnit.cpp','CvLuaCity.cpp','CvLuaUnit.cpp','CvCity.cpp','CvPlot.cpp','CvPromotionClasses.cpp']
    evidence=require_sources(names)
    sources={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    p=sources['CvPlayer.cpp']
    activation=p.split('void CvPlayer::setTurnActive(',1)[1].split('void CvPlayer::',1)[0]
    economy=p.split('void CvPlayer::doTurnPostDiplomacy()',1)[1].split('void CvPlayer::',1)[0]
    assert activation.index('PublishPlayerTurnStatus(DLLUIClass::TURN_START') < activation.index('doTurn();')
    positions=[economy.index(s) for s in ['pLoopCity->doTurn();','GetTreasury()->DoGold();','changeJONSCultureTimes100(GetTotalJONSCulturePerTurnTimes100());','doResearch();','"PlayerDoTurn"']]
    assert positions==sorted(positions)
    for method in ['IsCoastal','Plot']:assert 'Method('+method+');' in sources['CvLuaCity.cpp']
    for method in ['IsCombatUnit','IsEmbarked','GetDomainType','IsDead','IsDelayedDeath']:assert 'Method('+method+');' in sources['CvLuaUnit.cpp']
    assert 'return plot()->isCoastalLand(iMinWaterSize);' in sources['CvCity.cpp']
    unit=sources['CvUnit.cpp']
    for method in ['GetMaxAttackStrength','GetMaxDefenseStrength']:
        part=unit.split('int CvUnit::'+method+'(',1)[1].split('\nint CvUnit::',1)[0]
        assert 'GetGenericMeleeStrengthModifier(' in part
    generic=unit.split('int CvUnit::GetGenericMeleeStrengthModifier(',1)[1].split('\nint CvUnit::',1)[0]
    assert 'pBattlePlot->IsFriendlyTerritory(getOwner())' in generic and 'iModifier += getFriendlyLandsModifier();' in generic
    assert '(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in unit
    assert 'thisPromotion.GetVisibilityChange()' in unit
    promotion=sources['CvPromotionClasses.cpp']
    for column in ['VisibilityChange','FriendlyLandsModifier','LostWithUpgrade']:
        assert 'kResults.Get' in promotion and '"'+column+'"' in promotion
    assert 'visitor(player.m_strScriptData);' in p
    game=inspect_game()
    ui=(__import__('pathlib').Path(game['directory'])/'Assets/UI/InGame/TurnProcessing.lua').read_text(encoding='utf-8-sig')
    assert 'Events.AIProcessingStartedForPlayer.Add( OnAITurnStart );' in ui
    print('PASS Lantern pinned CP151 API, promotion and publication-order evidence; executable dispatch UNVERIFIED')
    return {'sources':evidence,'publication_before_economy':True,'PlayerDoTurn_after_economy':True,
            'executable_event_mapping_and_synchronous_dispatch':'NOT VERIFIED; candidate AIProcessingStartedForPlayer requires native acceptance',
            'source_url':f'https://github.com/LoneGazebo/Community-Patch-DLL/blob/{CP_COMMIT}/CvGameCoreDLL_Expansion2/CvPlayer.cpp'}


def validate():
    source=source_contract();d,count=sql_checks();static(d);scenarios=runtime()
    result={'date':'2026-11-01','baseline':inspect_database(),'source_evidence':source,
            'companion_tables':count,'lua51_scenarios':scenarios,'result':'PASS static/simulation checks',
            'native_acceptance':'PENDING: executable start dispatch, same-turn payout, combat, upgrade, rendering and save serialization'}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/Validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    return result


if __name__=='__main__':validate()
