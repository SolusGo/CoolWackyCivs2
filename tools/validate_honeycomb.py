"""HCC actual-schema inheritance, isolation, pinned CP source, shipped Lua and DDS validation."""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib, json, re, struct
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote
from build_mod import files, imported, ENTRIES, NAME
from generate_honeycomb import R, V, CIV, LEADER, UNIT, EXCHANGE, PROMOTION, DUMMIES, TEXT
from audit_cp import COMMIT, BASE

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
        for field,value in [('Cost',-1),('FaithCost',-1),('IsDummy',1),('ShowInPedia',0),('NeverCapture',1),('ConquestProb',0),('NukeImmune',1),('GoldMaintenance',0),('SpecialistCount',0),('Happiness',0)]:
            assert row[field]==value,(b,field,row[field])
        assert row['PrereqTech'] is None
        assert yields(d,b)=={'YIELD_'+suffix.split('_')[0]:1}
        cls=d.execute('SELECT * FROM BuildingClasses WHERE Type=?',(row['BuildingClass'],)).fetchone()
        assert cls['DefaultBuilding']==b
        assert (cls['MaxGlobalInstances'],cls['MaxPlayerInstances'],cls['MaxTeamInstances'])==(-1,-1,-1)
    p=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',(PROMOTION,)).fetchone()
    assert (p['VisibilityChange'],p['MovesChange'],p['CombatPercent'],p['CannotBeChosen'],p['LostWithUpgrade'])==(1,0,0,1,1)
    assert [r[0] for r in d.execute('SELECT UnitType FROM Unit_FreePromotions WHERE PromotionType=?',(PROMOTION,))]==[UNIT]
    assert not d.execute('SELECT 1 FROM UnitPromotions_UnitCombats WHERE PromotionType=?',(PROMOTION,)).fetchone()
    for key,value in TEXT.items(): assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_HCC_'+key,)).fetchone()[0]==value
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
    names=['CustomMods.h','CvPlayer.cpp','CvPlayerAI.cpp','CvGame.cpp','CvCity.cpp','CvCityCitizens.cpp','CvDllNetMessageHandler.cpp','CvLuaCity.cpp','CvLuaPlot.cpp','CvLuaPlayer.cpp','CvLuaGame.cpp','CvLuaUnit.cpp']
    data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    turn=body(data['CvPlayer.cpp'],'void CvPlayer::doTurnPostDiplomacy(')
    phase=body(data['CvPlayer.cpp'],'void CvPlayer::setTurnActive(')
    acquire=body(data['CvPlayer.cpp'],'CvCity* CvPlayer::acquireCity(')
    sale=body(data['CvDllNetMessageHandler.cpp'],'void CvDllNetMessageHandler::ResponseSellBuilding(')
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
      'Sight lost on upgrade native support':'IsLostWithUpgrade' in data['CvLuaUnit.cpp'] or 'IsLostWithUpgrade' in (R/'tools/reference/CvUnit.cpp').read_text(encoding='utf-8-sig'),
    }
    for kind,methods in {'City':'GetOwner GetID GetX GetY GetNumBuilding GetNumRealBuilding SetNumRealBuilding GetNumCityPlots GetCityIndexPlot IsWorkingPlot', 'Plot':'GetOwner GetX GetY GetPlotIndex GetPlotCity GetImprovementType IsImprovementPillaged GetWorkingCity', 'Player':'GetID GetCivilizationType IsAlive GetCityByID Cities GetScriptData SetScriptData', 'Game':'GetGameTurn IsFinalInitialized'}.items():
        for method in methods.split(): checks[kind+':'+method]=bool(re.search(r'Method\s*\(\s*'+method+r'\s*\)',data['CvLua'+kind+'.cpp']))
    for name,passed in checks.items(): assert passed,name
    report={'commit':COMMIT,'checks':checks,'timing_result':'Exact pre-economic start-of-owner-turn snapshot not guaranteed by exposed audited hooks. PlayerDoneTurn stages next payout from end-turn assignments; interturn changes wait until next snapshot. Native gameplay not run.',
            'files':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS HCC',len(checks),'pinned CP v151 source contracts; exact beginning snapshot limitation explicitly retained')

def runtime():
    lua=LuaRuntime()
    for p in list(V.rglob('*.lua'))+[R/'tools/tests/honeycomb_assertions.lua']:
        lua.eval('function(s,n) local f,e=loadstring(s,n);assert(f,e) end')(p.read_text(encoding='utf-8'),str(p))
    lua.globals().LoadHCC=lambda:lua.execute((V/'Lua/HCC_Commonwealth.lua').read_text(encoding='utf-8'))
    lua.execute((R/'tools/tests/honeycomb_assertions.lua').read_text(encoding='utf-8'))

def art(d):
    for p in V.rglob('*.xml'): ET.parse(p)
    for p in (V/'Art').glob('*.dds'):
        raw=p.read_bytes(); assert raw[:4]==b'DDS ' and struct.unpack_from('<I',raw,4)[0]==124
        assert struct.unpack_from('<I',raw,28)[0]>1,'missing mipmaps'
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
    d=sql(); sources(); runtime(); art(d)

if __name__=='__main__': validate()
