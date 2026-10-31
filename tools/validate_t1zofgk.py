"""T1 ZOFGK: actual SQL, pinned CP contracts, shipped Lua, assets and integration.

Mock checks explicitly do not constitute native Civilization V acceptance.
"""
from collections import Counter
import hashlib,json,re,sqlite3,struct,time,io,subprocess,unittest
from xml.etree import ElementTree as ET
from validation_prerequisites import main_check,require_packages
require_packages()
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from build_mod import files,ENTRIES,NAME,NS,imported,MOD_ID,VERSION
from generate_t1zofgk import R,V,CIV,LEADER,TRAIT,UNIT,HQ,TEXT,DEVELOPMENT_TIERS
from audit_cp import COMMIT

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')):d.executescript(p.read_text(encoding='utf-8'))

def inheritance(d):
    allowed={'ID','Type','Description','Help','Civilopedia','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}
    for table,old,new in [('Units','UNIT_WARRIOR',UNIT),('Buildings','BUILDING_BARRACKS',HQ)]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for key in a.keys():
            if key not in allowed:assert a[key]==b[key],('base inheritance',table,key)
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in cols:continue
            cols=[c for c in cols if c not in (col,'ID')]
            query='SELECT '+','.join(map(quote,cols))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
            before=Counter(tuple(r) for r in d.execute(query,(old,)))
            after=Counter(tuple(r) for r in d.execute(query,(new,)))
            if t=='Unit_FreePromotions':before[('PROMOTION_T1Z_SCOUTED',)]+=1
            if t=='Building_YieldChanges':
                before=Counter({(row[0],row[1]+1) if row[0]=='YIELD_CULTURE' else row:n for row,n in before.items()})
                if not any(row[0]=='YIELD_CULTURE' for row in before):before[('YIELD_CULTURE',1)]+=1
            assert before==after,('companion inheritance',t,before-after,after-before)
    # This CP companion references the building from a Unit_ table.
    inherited=dict(d.execute("SELECT UnitType,ProductionModifier FROM Unit_ProductionModifierBuildings WHERE BuildingType='BUILDING_BARRACKS'"))
    actual=dict(d.execute('SELECT UnitType,ProductionModifier FROM Unit_ProductionModifierBuildings WHERE BuildingType=?',(HQ,)))
    for unit in d.execute('SELECT * FROM Units'):
        defensive=d.execute('''SELECT 1 FROM Unit_FreePromotions f JOIN UnitPromotions p ON p.Type=f.PromotionType
            WHERE f.UnitType=? AND p.OnlyDefensive=1''',(unit['Type'],)).fetchone()
        eligible=unit['Domain']=='DOMAIN_LAND' and unit['Combat']>0 and (unit['RangedCombat'] or 0)==0 and not defensive
        expected=inherited.get(unit['Type'],0)+(10 if eligible else 0)
        assert actual.get(unit['Type'],0)==expected,('per-unit local production',unit['Type'],expected)

def upgrade_graph(d):
    # Resolve all upgrade edges to this civilization's actual class overrides.
    targets=dict(d.execute('SELECT Type,DefaultUnit FROM UnitClasses'))
    targets.update(dict(d.execute('SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,))))
    graph={}
    for old,cls in d.execute('SELECT UnitType,UnitClassType FROM Unit_ClassUpgrades'):
        if targets.get(cls):graph.setdefault(old,set()).add(targets[cls])
    for old,cls in d.execute('SELECT Type,GoodyHutUpgradeUnitClass FROM Units WHERE GoodyHutUpgradeUnitClass IS NOT NULL'):
        if targets.get(cls):graph.setdefault(old,set()).add(targets[cls])
    memo={}
    def longest(node,path):
        assert node not in path,('upgrade cycle',path,node)
        if node in memo:return memo[node]
        memo[node]=max((1+longest(n,path+(node,)) for n in graph.get(node,[])),default=0)
        return memo[node]
    maximum=longest(UNIT,())
    assert maximum>=7 and maximum<=DEVELOPMENT_TIERS,(maximum,DEVELOPMENT_TIERS)
    return maximum

def sql():
    d=database()
    before={t:[tuple(r) for r in d.execute('SELECT * FROM '+t+' ORDER BY ID')] for t in ['Civilizations','Units','Buildings','Traits','Leaders','UnitPromotions']}
    apply(d);inheritance(d)
    for t,rows in before.items():
        assert rows==[tuple(r) for r in d.execute('SELECT * FROM '+t+" WHERE Type NOT LIKE '%T1Z_%' ORDER BY ID")],('existing rows changed',t)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    assert d.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0]==LEADER
    assert d.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchall()[0][0]==TRAIT
    assert d.execute('SELECT count(*) FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0]==1
    assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_WARRIOR')).fetchone()[0]==UNIT
    assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_BARRACKS')).fetchone()[0]==HQ
    for key,column,value in [('ZEUS','CityAttack',15),('ONER','VisibilityChange',1),('GUMAYUSI','AttackWoundedMod',15),('SCOUTED','ExperiencePercent',15),('SYNERGY_10','CombatPercent',10),('SYNERGY_15','CombatPercent',15),('PRESSURE','CombatPercent',-10)]:
        row=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',('PROMOTION_T1Z_'+key,)).fetchone()
        assert row[column]==value and row['CannotBeChosen']==1 and row['LostWithUpgrade']==0
    assert set(tuple(r) for r in d.execute("SELECT FeatureType,DoubleMove FROM UnitPromotions_Features WHERE PromotionType='PROMOTION_T1Z_ONER'"))=={('FEATURE_FOREST',1),('FEATURE_JUNGLE',1)}
    heal=d.execute("SELECT FriendlyHealChange,NeutralHealChange,EnemyHealChange,FlatHealRate,AlwaysHeal FROM UnitPromotions WHERE Type='PROMOTION_T1Z_SUPPORT'").fetchone()
    assert tuple(heal)==(5,5,5,0,0)
    for i in range(1,DEVELOPMENT_TIERS+1):
        assert d.execute('SELECT CombatPercent FROM UnitPromotions WHERE Type=?',('PROMOTION_T1Z_DEVELOPMENT_'+str(i),)).fetchone()[0]==i*4
    for key in ['ZEUS','ONER','FAKER','GUMAYUSI','KERIA','SYNERGY_10','SYNERGY_15','PRESSURE','SUPPORT']:
        assert d.execute('SELECT LostOnGifting FROM UnitPromotions WHERE Type=?',('PROMOTION_T1Z_'+key,)).fetchone()[0]==1
    for key in ['SCOUTED']+['DEVELOPMENT_'+str(i) for i in range(1,DEVELOPMENT_TIERS+1)]:
        assert d.execute('SELECT LostOnGifting,LostWithUpgrade FROM UnitPromotions WHERE Type=?',('PROMOTION_T1Z_'+key,)).fetchone()[:]==(0,0)
    marker=d.execute("SELECT CombatPercent,ExperiencePercent,ShowInUnitPanel,CannotBeChosen,LostOnGifting,LostWithUpgrade FROM UnitPromotions WHERE Type='PROMOTION_T1Z_ACQUIRED'").fetchone()
    assert tuple(marker)==(0,0,0,1,0,0),'acquisition provenance has no bonus and survives native gifting/upgrade'
    maximum=upgrade_graph(d)
    for key,text in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_T1Z_'+key,)).fetchone()[0]==text
    for p in V.rglob('*'):
        if p.suffix in ['.lua','.xml','.sql']:
            for key in set(re.findall(r'TXT_KEY_T1Z_[A-Z0-9_]+',p.read_text(encoding='utf-8'))):
                # Lua composes namespace prefixes; only complete literal keys.
                if key.endswith('_') or key=='TXT_KEY_T1Z_CIV5':continue
                assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(key,)).fetchone(),key
    altered=database()
    altered.execute("UPDATE Units SET Combat=33,Cost=151,Moves=4 WHERE Type='UNIT_WARRIOR'")
    altered.execute("UPDATE Buildings SET Cost=171,GoldMaintenance=3 WHERE Type='BUILDING_BARRACKS'")
    altered.execute("INSERT INTO Building_YieldChanges VALUES ('BUILDING_BARRACKS','YIELD_CULTURE',2)")
    altered.execute("INSERT INTO Unit_ProductionModifierBuildings VALUES ('UNIT_WARRIOR','BUILDING_BARRACKS',3)")
    altered.executescript("""INSERT INTO Units(Type,Class,Domain,Combat,CombatClass,Cost,RangedCombat) VALUES
        ('UNIT_T1Z_TEST_MELEE','UNITCLASS_WARRIOR','DOMAIN_LAND',20,'UNITCOMBAT_CUSTOM_T1Z',90,0),
        ('UNIT_T1Z_TEST_HYBRID','UNITCLASS_ARCHER','DOMAIN_LAND',20,'UNITCOMBAT_GUN',90,25),
        ('UNIT_T1Z_TEST_DEFENDER','UNITCLASS_WARRIOR','DOMAIN_LAND',20,'UNITCOMBAT_MELEE',90,0);
        INSERT INTO Unit_FreePromotions VALUES ('UNIT_T1Z_TEST_DEFENDER','PROMOTION_ONLY_DEFENSIVE');""")
    apply(altered);inheritance(altered)
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    print('PASS T1 SQL: human-only, distinct leader/trait, complete active replacements, isolation, exact numbers, text, per-unit local production; longest upgrade path',maximum)
    return d,maximum

def source():
    paths=['CustomMods.h','CvUnit.cpp','CvCity.cpp','CvPlayer.cpp','CvPromotionClasses.cpp','CvUnitClasses.cpp','CvMinorCivAI.cpp','CvLuaUnit.cpp','CvLuaPlayer.cpp','CvLuaCity.cpp','CvLuaTeam.cpp','CvLuaGame.cpp']
    s={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in paths}
    def body(name,signature):
        start=s[name].index(signature);return s[name][start:s[name].index('\n}',start)+2]
    u=s['CvUnit.cpp'];h=s['CustomMods.h'];conversion=body('CvUnit.cpp','void CvUnit::convert(')
    heal=body('CvUnit.cpp','bool CvUnit::canHeal(');rate=body('CvUnit.cpp','int CvUnit::ActualHealRate(')
    capture=body('CvUnit.cpp','/* static */ CvUnit* CvUnit::createCaptureUnit(')
    capture_definition=body('CvUnit.cpp','bool CvUnit::getCaptureDefinition(')
    sending=body('CvPlayer.cpp','void CvPlayer::AddIncomingUnit(')
    snapshot=body('CvMinorCivAI.cpp','void CvMinorCivIncomingUnitGift::init(')
    arrival=body('CvMinorCivAI.cpp','void CvMinorCivAI::doIncomingUnitGifts(')
    returning=body('CvMinorCivAI.cpp','void CvMinorCivAI::returnIncomingUnitGift(')
    applying=body('CvMinorCivAI.cpp','void CvMinorCivIncomingUnitGift::applyToUnit(')
    morph=body('CvUnit.cpp','void CvUnit::DoConvertOnDamageThreshold(')
    replacement=body('CvPlayer.cpp','void CvPlayer::SetUnitClassReplacement(')
    normal_upgrade=body('CvUnit.cpp','CvUnit* CvUnit::DoUpgradeTo(')
    goody_upgrade=body('CvPlayer.cpp','void CvPlayer::receiveGoody(')
    checks={
      'v151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',h)),
      'native start-turn binding':'Method(GetStartTurn);' in s['CvLuaGame.cpp'],
      'converted exact signature':'"UnitConverted",' in h and '"iiiib"' in h,
      'city trained exact signature':'"CityTrained",' in h and '"iiibb"' in h,
      'conversion after promotion copying':conversion.index('setHasPromotion(ePromotion, bGivePromotion)')<conversion.index('GAMEEVENT_UnitConverted'),
      'conversion before source death':conversion.index('GAMEEVENT_UnitConverted')<conversion.index('pUnit->kill(true'),
      'original owner set before conversion hook':conversion.index('SetOriginalOwner(')<conversion.index('GAMEEVENT_UnitConverted'),
      'ScriptData not natively copied':'setScriptData(' not in conversion,
      'ScriptData saved':'visitor(unit.m_strScriptData)' in u,
      'permanent promotions copied':'(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in conversion,
      'attack wounded uses preattack damage':'if (pDefender->getDamage() + iAssumeExtraOtherDamage > 0)\n\t\t\tiModifier += attackWoundedModifier();' in u,
      'attack wounded absent from defense':'attackWoundedModifier()' not in body('CvUnit.cpp','int CvUnit::GetMaxDefenseStrength('),
      'healing rejects forbidden movement':'bCheckMovement && hasMoved() && !isAlwaysHeal()' in heal,
      'healing rejects embarkation':'pPlot->needsEmbarkation(this)' in heal,
      'healing rejects blockaded cities':'IsBlockadedWaterAndLand()' in heal,
      'healing gates normal rate':'if (canHeal(pPlot, bCheckMovement))' in rate,
      'moved fallback is flat healing only':'return GetFlatHealRate();' in rate,
      'heal territory additions':'getExtraFriendlyHeal()' in body('CvUnit.cpp','int CvUnit::healRate(') and 'getExtraEnemyHeal()' in body('CvUnit.cpp','int CvUnit::healRate('),
      'city-local per-unit production':'GetCityBuildings()->GetNumBuilding(eBuilding) > 0' in s['CvCity.cpp'] and 'pkUnitInfo->GetBuildingProductionModifier(eBuilding)' in s['CvCity.cpp'],
      'per-unit production table':'"Unit_ProductionModifierBuildings"' in s['CvUnitClasses.cpp'],
      'native forest/jungle mechanic':'"DoubleMove"' in s['CvPromotionClasses.cpp'],
      'direct capture has no source promotion snapshot':'isHasPromotion(' not in capture_definition and 'getNumPromotionInfos' not in capture_definition,
      'direct capture has no source promotion copy loop':'initUnit(' in capture and 'getNumPromotionInfos' not in capture and '->convert(' not in capture,
      'direct capture final identity after Created':capture.index('initUnit(')<capture.index('SetOriginalOwner('),
      'distance gift snapshot before source prekill':sending.index('unitGift.init(')<sending.index('pUnit->kill(true)'),
      'distance snapshot retains promotions':'setHasPromotion(ePromotion, true)' in snapshot,
      'distance arrival copies after Created':arrival.index('initUnit(')<arrival.index('unitGift.applyToUnit('),
      'distance return copies after Created':returning.index('initUnit(')<returning.index('unitGift.applyToUnit('),
      'return bypasses native gifting loss':'bReturn || !pkPromotionInfo->IsLostOnGifting()' in applying,
      'distance copies no unit ScriptData':'setScriptData' not in applying,
      'distance copies bypass UnitConverted':'GAMEEVENT_UnitConverted' not in applying and '->convert(' not in applying,
      'gift notification follows copy':arrival.index('unitGift.applyToUnit(')<arrival.index('DoUnitGiftFromMajor('),
      'gift notification before optional relocation':arrival.index('DoUnitGiftFromMajor(')<arrival.index('jumpToNearestValidPlot('),
      'minor gift callback after spawn':'GAMEEVENT_MinorGiftUnit' in body('CvMinorCivAI.cpp','void CvMinorCivAI::DoUnitSpawnTurn('),
      'damage/health transforms reuse upgrade flag':'convert(this, true, false)' in morph and 'GAMEEVENT_UnitUpgraded' not in morph,
      'class replacement reuses upgrade flag':'convert(pLoopUnit, true, false)' in replacement and 'GAMEEVENT_UnitUpgraded' not in replacement,
      'genuine upgrade emits proof before copying':normal_upgrade.index('GAMEEVENT_UnitUpgraded')<normal_upgrade.index('pNewUnit->convert('),
      'goody upgrade emits proof before copying':goody_upgrade.index('GAMEEVENT_UnitUpgraded')<goody_upgrade.index('pNewUnit->convert('),
      'minor bookkeeping before player boundary':s['CvPlayer.cpp'].index('GetMinorCivAI()->DoTurn();')<s['CvPlayer.cpp'].index('"PlayerDoTurn"'),
    }
    for event,signature in [('UnitUpgraded','iiib'),('PlayerGifted','iiiiii'),('MinorGiftUnit','iii')]:
        checks['event ABI '+event]=bool(re.search(r'GAMEEVENT_'+event+r'\s+"'+event+r'",\s+"'+signature+'"',h))
    for kind,methods in {'Player':'GetID GetScriptData SetScriptData IsHuman GetCivilizationType Units GetUnitByID GetCityByID AddNotification GetTeam IsAlive',
                         'Unit':'GetOwner GetID GetUnitType GetX GetY GetGameTurnCreated GetScriptData SetScriptData GetOriginalOwner IsCombatUnit IsHasPromotion SetHasPromotion IsRanged IsOnlyDefensive IsDead IsDelayedDeath GetDomainType GetName',
                         'City':'GetOwner GetNumRealBuilding','Team':'IsAtWar'}.items():
        for name in methods.split():checks[kind+':'+name]=bool(re.search(r'Method\(\s*'+name+r'\s*\)',s['CvLua'+kind+'.cpp']))
    for key,condition in checks.items():assert condition,('CP source contract',key)
    hashes={n:hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest() for n in paths}
    assert hashes['CvUnit.cpp']=='54ea19c86652cc814784e084337dda3a9e47a9e7c4d70d6d7e7e83511b43a875'
    assert hashes['CvMinorCivAI.cpp']=='a525e9b5c2dc760c92cd6894e7c4a1c756ba73534bc97ea39b48ce97fdc99fd9'
    print('PASS',len(checks),'pinned CP v151 source/API contracts (static)')
    return {'commit':COMMIT,'checks':len(checks),'sha256':hashes}

def simulation(d,speed,controller=None):
    lua=LuaRuntime();g=lua.globals();g.SPEED=speed;g.ASSERTIONS=0
    types={row['Type']:row['ID'] for table in ['Civilizations','Units','Buildings','UnitPromotions'] for row in d.execute('SELECT Type,ID FROM '+table)}
    g.GameInfoTypes=lua.table_from(types)
    g.NativePromotions=lua.table_from({row['ID']:lua.table_from(dict(row)) for row in d.execute("SELECT * FROM UnitPromotions WHERE Type LIKE 'PROMOTION_T1Z_%'")})
    g.Translations=lua.table_from(dict(d.execute('SELECT Tag,Text FROM Language_en_US')))
    code=controller if controller is not None else (V/'Lua/T1Z_Controller.lua').read_text(encoding='utf-8')
    g.LoadController=lambda:lua.execute(code)
    lua.execute((R/'tools/tests/t1zofgk_mock.lua').read_text(encoding='utf-8'))
    return lua

def runtime(d):
    total=0;runs=[]
    for speed in [67,100,150,300]:
        lua=simulation(d,speed);g=lua.globals()
        lua.execute((R/'tools/tests/t1zofgk_assertions.lua').read_text(encoding='utf-8'))
        count=g.ASSERTIONS;total+=count;runs.append({'train_percent':speed,'assertions':count})
        print('PASS shipped T1 controller, Lua 5.1, speed',speed,':',count,'runtime assertions (mock)')
    return {'runs':runs,'assertions':total}

def hardening(d,controller=None,speeds=(67,100,150,300),require_pass=True):
    definition=(R/'tools/tests/t1zofgk_hardening.lua').read_text(encoding='utf-8')
    probe=simulation(d,100,controller);probe.execute(definition)
    names=sorted(probe.globals().HardeningCases.keys());runs=[];failures=[];assertions=0
    for speed in speeds:
        for name in names:
            lua=simulation(d,speed,controller);lua.execute(definition)
            result={'case':name,'train_percent':speed}
            try:
                lua.globals().HardeningCases[name]()
                result['status']='PASS';result['assertions']=int(lua.globals().ASSERTIONS)
                assertions+=result['assertions']
            except Exception as exc:
                result.update(status='FAIL',error=str(exc).split('stack traceback:')[0].strip())
                failures.append(result)
            runs.append(result)
    if require_pass:assert not failures,failures
    print(('PASS' if not failures else 'BASELINE'),len(runs),'isolated T1 hardening cases,',assertions,'assertions,',len(failures),'failures (mock)')
    return {'cases':len(names),'runs':runs,'assertions':assertions,'failures':len(failures)}

def assets(d):
    lua=LuaRuntime();parse=lua.eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
    for p in list(V.rglob('*.lua'))+list((R/'tools/tests').glob('t1zofgk*.lua')):parse(p.read_text(encoding='utf-8'),str(p))
    for p in V.rglob('*.xml'):ET.parse(p)
    textures=list((V/'Art').glob('*.dds'));assert len(textures)==49
    for p in textures:
        data=p.read_bytes();assert data[:4]==b'DDS '
        with Image.open(p) as im:
            im.load();w,h=im.size
            levels=1;pixels=w*h*4
            while (w,h)!=(1,1):w,h=max(1,w//2),max(1,h//2);levels+=1;pixels+=w*h*4
            assert struct.unpack_from('<I',data,28)[0]==levels and len(data)==128+pixels,p
    with Image.open(V/'Art/T1Z_Dawn.dds') as im:assert im.size==(1024,768)
    with Image.open(V/'Art/T1Z_Icon256.dds') as im:
        assert im.convert('RGBA').getpixel((0,0))[3]==0
        pixels=im.convert('RGBA').tobytes()
        assert any(pixels[i]>150 and pixels[i+1]<30 and pixels[i+2]<80 and pixels[i+3]>200 for i in range(0,len(pixels),4))
    frozen=json.loads((V/'docs/ArtInventory.json').read_text(encoding='utf-8'))
    for name,digest in frozen['sha256'].items():assert hashlib.sha256((R/name).read_bytes()).hexdigest()==digest,('working v19 art changed',name)
    for table,where in [('Civilizations',"Type='"+CIV+"'"),('Leaders',"Type='"+LEADER+"'"),
                        ('Units',"Type='"+UNIT+"'"),('Buildings',"Type='"+HQ+"'"),('UnitPromotions',"Type LIKE 'PROMOTION_T1Z_%'")]:
        for atlas,index in d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE '+where):
            rows=d.execute('SELECT Filename,IconSize,IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas=?',(atlas,)).fetchall()
            # Civ V's stock atlas table stores these numeric fields as TEXT.
            assert rows and all(0<=int(index)<int(r[2])*int(r[3]) for r in rows),(table,atlas,index)
            for filename,size,columns,rows_count in rows:
                with Image.open(V/'Art'/filename) as im:assert im.size==(int(size)*int(columns),int(size)*int(rows_count))
    civ=d.execute('SELECT IconAtlas,AlphaIconAtlas,DawnOfManImage,MapImage FROM Civilizations WHERE Type=?',(CIV,)).fetchone()
    assert tuple(civ)==('T1Z_CIV_ATLAS','T1Z_ALPHA_ATLAS','T1Z_Dawn.dds','T1Z_Map.dds')
    for name in civ[2:]:assert (V/'Art'/name).is_file()
    leader=d.execute('SELECT IconAtlas,ArtDefineTag FROM Leaders WHERE Type=?',(LEADER,)).fetchone()
    assert leader['IconAtlas']=='T1Z_LEADER_ATLAS'
    scene=ET.parse(V/'Art'/leader['ArtDefineTag']).getroot()
    assert scene.get('FallbackImage')=='T1Z_Leader.dds' and (V/'Art'/scene.get('FallbackImage')).is_file()
    assert d.execute('SELECT UnitFlagAtlas FROM Units WHERE Type=?',(UNIT,)).fetchone()[0]=='T1Z_FLAG_ATLAS'
    root=ET.parse(R/(NAME+'.modinfo')).getroot()
    actual={p.relative_to(R).as_posix():p for p in files() if V in p.parents}
    declared={e.text:e for e in root.findall('Files/File')}
    for name,p in actual.items():
        assert declared[name].get('md5')==hashlib.md5(p.read_bytes()).hexdigest().upper(),('stale manifest: run tools/build_mod.py --manifest-only --preserve-art',name)
        assert declared[name].get('import')==str(int(imported(p))),('VFS flag',name)
    assert root.get('id')==MOD_ID and root.get('version')==VERSION=='19'
    project=ET.parse(R/'CoolWackyCivs2.civ5proj');prefix='{'+NS+'}'
    registered={e.get('Include'):e.findtext(prefix+'ImportIntoVFS') for e in project.iter(prefix+'Content') if e.get('Include')}
    for name,p in actual.items():assert registered[name]==str(imported(p)),('project/VFS registration',name)
    sql_order=[e.text for e in root.findall('Actions/OnModActivated/UpdateDatabase') if e.text.startswith('T1ZOFGK/')]
    assert sql_order==[p.relative_to(R).as_posix() for p in sorted((V/'SQL').glob('*.sql'))]
    entries=[e for e in root.findall('EntryPoints/EntryPoint') if e.get('file','').startswith('T1ZOFGK/')]
    assert len(entries)==1 and entries[0].get('type')=='InGameUIAddin' and entries[0].get('file')=='T1ZOFGK/UI/T1Z_Roster.xml'
    assert sum(e[0].startswith('T1ZOFGK/') for e in ENTRIES)==1
    ui=ET.parse(V/'UI/T1Z_Roster.xml');ids={e.get('ID') for e in ui.iter() if e.get('ID')}
    from validate_urgal import support_source
    styles={e.tag for e in ET.parse(support_source().with_name('Styles.xml')).iter()}
    assert {e.get('Style') for e in ui.iter() if e.get('Style')}<=styles,'undefined native UI style'
    assert set(re.findall(r'Controls\.([A-Za-z0-9_]+)',(V/'UI/T1Z_Roster.lua').read_text()))<=ids
    for scroll in ui.iter('ScrollPanel'):assert scroll.find('ScrollBar') is not None
    for node in ui.iter('Image'):
        if node.get('Texture'):assert (V/'Art'/node.get('Texture')).is_file()
    assert ':SetUpdate(' not in (V/'Lua/T1Z_Controller.lua').read_text()
    print('PASS 49 decoded complete-mip DDS, frozen v19 art, Lua 5.1, native XML styles, project/modinfo/VFS, SQL order and single addin')

def prerequisite_regressions():
    output=io.StringIO()
    suite=unittest.defaultTestLoader.discover(str(R/'tools/tests'),pattern='test_validation_prerequisites.py')
    result=unittest.TextTestRunner(stream=output,verbosity=0).run(suite)
    assert result.wasSuccessful(),output.getvalue()
    print('PASS',result.testsRun,'synthetic prerequisite/read-only tests')
    return {'tests':result.testsRun,'status':'PASS','scope':'synthetic setup failures and read-only SQLite fixtures'}

def compare_baseline(ref):
    if not re.fullmatch(r'[0-9a-fA-F]{7,40}',ref):raise SystemExit('--compare-baseline expects a Git commit hash')
    commit=subprocess.check_output(['git','rev-parse','--verify',ref+'^{commit}'],cwd=R,text=True).strip()
    d=database()
    for path in sorted((V/'SQL').glob('*.sql')):
        source=subprocess.check_output(['git','show',commit+':'+path.relative_to(R).as_posix()],cwd=R).decode('utf-8')
        d.executescript(source)
    current=database();apply(current)
    for table in ['Civilizations','Units','Buildings','Traits','Leaders','UnitPromotions']:
        ids=dict(current.execute('SELECT Type,ID FROM '+table))
        for typ,number in d.execute('SELECT Type,ID FROM '+table):
            assert ids.get(typ)==number,('released type/ID changed',table,typ,number,ids.get(typ))
    current.close()
    controller=subprocess.check_output(['git','show',commit+':T1ZOFGK/Lua/T1Z_Controller.lua'],cwd=R).decode('utf-8')
    return {'commit':commit,'controller_sha256':hashlib.sha256(controller.encode('utf-8')).hexdigest(),
            'released_type_ids_preserved':True,
            'scope':'original SQL and production controller; current independent cases; Standard-speed Lua 5.1 simulation',
            **hardening(d,controller=controller,speeds=(100,),require_pass=False)}

def validate():
    environment=main_check()
    started=time.perf_counter();setup=prerequisite_regressions();d,maximum=sql();audit=source();sim=runtime(d);regressions=hardening(d);assets(d)
    report={'date':'2026-10-31','scope':'actual SQL / pinned CP source / Lua 5.1 simulation / decoded assets',
            'native_Civ_V':'NOT RUN','artwork':'complete; official T1 mark and original generated paintings',
            'textures':49,'longest_recruit_upgrade_path':maximum,'development_tiers':DEVELOPMENT_TIERS,
            'source':audit,'environment':environment,'prerequisites':setup,'hardening':regressions,**sim,'elapsed_seconds':round(time.perf_counter()-started,3)}
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    return report

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compare-baseline',help='Replay the isolated regressions against an earlier Git commit, including its original SQL')
    args=parser.parse_args()
    main_check()
    baseline=compare_baseline(args.compare_baseline) if args.compare_baseline else None
    report=validate()
    if baseline:
        hardening_report={'date':'2026-10-31','native_Civ_V':'NOT RUN','before':baseline,
                          'after':report['hardening'],'prerequisites':report['prerequisites'],
                          'source_checks':report['source']['checks'],'art_preserved':True,
                          'controller_sha256':hashlib.sha256((V/'Lua/T1Z_Controller.lua').read_bytes()).hexdigest()}
        (V/'docs/HardeningValidation.json').write_text(json.dumps(hardening_report,indent=2)+'\n',encoding='utf-8',newline='\n')
