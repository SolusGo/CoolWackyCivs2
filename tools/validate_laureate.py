"""Actual-schema SQL, shipped Lua 5.1, CP source contracts and decoded art checks.

These are static/simulated checks. They do not claim native Civ V acceptance.
"""
from collections import Counter
from pathlib import Path
import hashlib,json,re,sqlite3,struct,sys,time
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from build_mod import files,ENTRIES,NAME
from generate_laureate import R,V,CIV,LEADER,UNIT,HALL,TRAIT,CROWN,VETERAN,GP,POLICY,TEXT
from audit_cp import COMMIT,BASE

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')): d.executescript(p.read_text(encoding='utf-8'))

def inheritance(d):
    for table,old,new,allowed in [
        ('Units','UNIT_SWORDSMAN',UNIT,{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}),
        ('Buildings','BUILDING_AMPHITHEATER',HALL,{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','Happiness'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        for key in a.keys():
            if key not in allowed: assert a[key]==b[key],(table,key,a[key],b[key])
        if table=='Buildings': assert b['Happiness']==a['Happiness']+1
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in cols: continue
            cols=[c for c in cols if c not in (col,'ID')]
            query='SELECT '+','.join(map(quote,cols))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
            before=Counter(tuple(r) for r in d.execute(query,(old,)))
            after=Counter(tuple(r) for r in d.execute(query,(new,)))
            if t=='Unit_FreePromotions': after.subtract({(CROWN,):1});after=+after
            assert before==after,(t,before-after,after-before)

def sql():
    d=database()
    for p in files():
        if p.suffix=='.sql' and p.relative_to(R).parts[0]!='TheLaureateCommonwealth':
            d.executescript(p.read_text(encoding='utf-8'))
    tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables}
    apply(d)
    for t,rows in before.items():
        if t=='CustomModOptions': continue # explicit hook opt-ins, no balance changes
        assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('changed existing content',t)
    inheritance(d)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    assert [r[0] for r in d.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,))]==[TRAIT]
    assert not d.execute('SELECT 1 FROM Leader_SharedTraits WHERE LeaderType=?',(LEADER,)).fetchone()
    assert [tuple(r) for r in d.execute('SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,))]==[('UNITCLASS_SWORDSMAN',UNIT)]
    assert [tuple(r) for r in d.execute('SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?',(CIV,))]==[('BUILDINGCLASS_AMPHITHEATER',HALL)]
    crown=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',(CROWN,)).fetchone()
    assert (crown['AttackWoundedMod'],crown['HPHealedIfDestroyEnemy'],crown['LostWithUpgrade'],crown['CannotBeChosen'],crown['CombatPercent'],crown['MovesChange'])==(15,15,0,1,0,0)
    for promotion in [VETERAN,GP]:
        marker=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',(promotion,)).fetchone()
        assert (marker['LostWithUpgrade'],marker['LostOnGifting'],marker['CannotBeChosen'],marker['ShowInUnitPanel'])==(0,0,1,0)
        assert (marker['CombatPercent'],marker['MovesChange'],marker['ExperiencePercent'])==(0,0,0)
    for promotion in [CROWN,VETERAN,GP]:
        assert not d.execute('SELECT 1 FROM UnitPromotions_UnitCombats WHERE PromotionType=?',(promotion,)).fetchone()
    pedia_types=('PEDIA_MELEE','PEDIA_RANGED','PEDIA_NAVAL','PEDIA_HEAL','PEDIA_SCOUTING','PEDIA_AIR','PEDIA_SHARED','PEDIA_ATTRIBUTES')
    bad=d.execute('SELECT Type FROM UnitPromotions WHERE PediaType IN ('+','.join('?' for _ in pedia_types)+') AND (PediaEntry IS NULL OR Description IS NULL)',pedia_types).fetchall()
    assert not bad,('Civilopedia initialization would fail on promotion text',list(map(tuple,bad)))
    assert [r[0] for r in d.execute('SELECT UnitType FROM Unit_FreePromotions WHERE PromotionType=?',(CROWN,))]==[UNIT]
    policy=d.execute('SELECT * FROM Policies WHERE Type=?',(POLICY,)).fetchone()
    assert (policy['GreatPeopleRateModifier'],policy['ExpModifier'],policy['IsDummy'],policy['PolicyBranchType'])==(15,15,1,None)
    for k,v in TEXT.items(): assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_LC_'+k,)).fetchone()[0]==v
    for path in (V/'SQL').glob('*.sql'):
        for tag in re.findall(r"'(TXT_KEY_LC_[A-Z_0-9]+)'",path.read_text()):
            if tag in ('TXT_KEY_LC_CIV5','TXT_KEY_LC_LAUREA'): continue
            assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(tag,)).fetchone(),tag
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    altered=database()
    altered.execute("UPDATE Units SET Combat=29,Cost=137,Moves=3 WHERE Type='UNIT_SWORDSMAN'")
    altered.execute("UPDATE Buildings SET Cost=159,GoldMaintenance=4,GreatWorkCount=1,Happiness=2 WHERE Type='BUILDING_AMPHITHEATER'")
    apply(altered);inheritance(altered)
    print('PASS Laureate SQL: installed schema, isolation, dynamic replacement/companion inheritance, Iron, Writing slot, exact native modifiers and localization')
    return d

def source():
    def read(name): return (R/'tools/reference'/name).read_text(encoding='utf-8-sig')
    names=['CustomMods.h','CvCity.cpp','CvPlayer.cpp','CvUnit.cpp','CvUnitCombat.cpp','CvLuaPlayer.cpp','CvLuaCity.cpp','CvLuaUnit.cpp','CvPolicyClasses.cpp','CvPromotionClasses.cpp']
    s={n:read(n) for n in names}
    def body(n,signature):
        start=s[n].index(signature);return s[n][start:s[n].index('\n}',start)+2]
    h=s['CustomMods.h'];p=s['CvPlayer.cpp'];u=s['CvUnit.cpp'];combat=s['CvUnitCombat.cpp']
    kill=body('CvUnit.cpp','void CvUnit::kill(')
    capture=body('CvUnit.cpp','/* static */ CvUnit* CvUnit::createCaptureUnit(')
    definition=body('CvUnit.cpp','bool CvUnit::getCaptureDefinition(')
    movement=body('CvUnit.cpp','void CvUnit::setXY(')
    conversion=body('CvUnit.cpp','void CvUnit::convert(')
    civilian_return=body('CvPlayer.cpp','void CvPlayer::DoCivilianReturnLogic(')
    checks={
      'v151 pin':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',h)),
      'city constructed exact event':'"CityConstructed",' in h and '"iiibb"' in h,
      'construction completion':'GAMEEVENT_CityConstructed' in body('CvCity.cpp','void CvCity::produce(BuildingTypes'),
      'capture does not emit completion':'GAMEEVENT_CityConstructed' not in body('CvPlayer.cpp','CvCity* CvPlayer::acquireCity('),
      'creation at native init':'GAMEEVENT_UnitCreated' in body('CvUnit.cpp','void CvUnit::initWithNameOffset('),
      'conversion event before source death':body('CvUnit.cpp','void CvUnit::convert(').index('GAMEEVENT_UnitConverted')<body('CvUnit.cpp','void CvUnit::convert(').index('pUnit->kill(true'),
      'capture original owner assigned after init':body('CvUnit.cpp','/* static */ CvUnit* CvUnit::createCaptureUnit(').index('initUnit(')<body('CvUnit.cpp','/* static */ CvUnit* CvUnit::createCaptureUnit(').index('SetOriginalOwner'),
      'promotions increment level before hook':body('CvUnit.cpp','void CvUnit::promote(').index('changeLevel(1)')<body('CvUnit.cpp','void CvUnit::promote(').index('GAMEEVENT_UnitPromoted'),
      'setLevel has no event':'GAMEEVENT' not in body('CvUnit.cpp','void CvUnit::setLevel('),
      'persistent upgrade markers':'pUnit->isHasPromotion(ePromotion) && (!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in u,
      'gift persistence':'(!bIsGift || !pkPromotionInfo->IsLostOnGifting())' in u,
      'attack wounded requires defender damage':'if (pDefender->getDamage() + iAssumeExtraOtherDamage > 0)\n\t\t\tiModifier += attackWoundedModifier();' in u,
      'melee defense excludes attackWoundedModifier':'attackWoundedModifier()' not in body('CvUnit.cpp','int CvUnit::GetMaxDefenseStrength('),
      'native HP cap':'pkWinner->changeDamage(-pkWinner->getDamage());' in body('CvUnitCombat.cpp','void CvUnitCombat::ApplyPostKillTraitEffects('),
      'native 15 HP healing field':'changeHPHealedIfDefeatEnemy(thisPromotion.GetHPHealedIfDefeatEnemy() * iChange)' in u,
      'native policy XP applied':'changeExpModifier(pkPolicyInfo->GetExpModifier() * iChange)' in p,
      'native policy excludes dummy counts':'IsDummy()' in body('CvPolicyClasses.cpp','int CvPlayerPolicies::GetNumPoliciesOwned('),
      'native kill healing loads exact DB column':'kResults.GetInt("HPHealedIfDestroyEnemy")' in s['CvPromotionClasses.cpp'],
      'native wounded modifier loads exact DB column':'kResults.GetInt("AttackWoundedMod")' in s['CvPromotionClasses.cpp'],
      'combat-only XP policy bonus':'if(bFromCombat)' in body('CvUnit.cpp','void CvUnit::changeExperienceTimes100(') and '(iChangeTimes100 * kPlayer.getExpModifier()) / 100' in u,
      'native GP policy applied':'POLICYMOD_GREAT_PERSON_RATE, pkPolicyInfo->GetGreatPeopleRateModifier() * iChange' in p,
      'native GP city rate uses player rate':'GetPlayer()->getGreatPeopleRateModifier() + GetPlayer()->GetGreatPersonRateModifier(eGreatPerson)' in s['CvCity.cpp'],
      'GA start and end hooks':'GAMEEVENT_PlayerGoldenAge, GetID(), false, 0' in p and 'GAMEEVENT_PlayerGoldenAge, GetID(), true, iChange' in p,
      'threshold uses GP speed':'getGreatPeoplePercent()' in body('CvPlayer.cpp','int CvPlayer::GetGoldenAgeProgressThreshold('),
      'meter binding changes real progress':'pkPlayer->ChangeGoldenAgeProgressMeterTimes100(iValue * 100)' in body('CvLuaPlayer.cpp','int CvLuaPlayer::lChangeGoldenAgeProgressMeter('),
      'native threshold retains overflow':'SetGoldenAgeProgressMeterTimes100(iOverflowTimes100)' in body('CvPlayer.cpp','void CvPlayer::DoProcessGoldenAge('),
      'local building happiness':'iLocalHappiness += GetBaseHappinessFromBuildings()' in s['CvCity.cpp'],
      'combat prekill precedes capture-definition snapshot':kill.index('GAMEEVENT_UnitPrekill')<kill.index('getCaptureDefinition(&kCaptureDef)'),
      'combat capture notice follows the snapshot':kill.index('getCaptureDefinition(&kCaptureDef)')<kill.index('GAMEEVENT_UnitCaptured'),
      'source deletion precedes capture replacement':kill.index('deleteUnit(GetID())')<kill.index('CvUnit::createCaptureUnit(kCaptureDef)'),
      'movement capture notice precedes capture snapshot':movement.index('GAMEEVENT_UnitCaptured')<movement.index('getCaptureDefinition(&kCaptureDef, getOwner())'),
      'movement snapshot precedes forced noncapture death':movement.index('getCaptureDefinition(&kCaptureDef, getOwner())')<movement.index('pLoopUnit->setCapturingPlayer(NO_PLAYER)'),
      'movement replacement occurs after stored snapshots':movement.index('kCaptureUnitList.push_back(kCaptureDef)')<movement.index('createCaptureUnit(kCaptureUnitList[uiCaptureIndex])'),
      'capture definition preserves source ScenarioData':'kCaptureDef.iScenarioData = m_iScenarioData' in definition,
      'replacement ScenarioData set after initialization':capture.index('initUnit(')<capture.index('setScenarioData(kCaptureDef.iScenarioData)'),
      'original owner set before capture identity copy':capture.index('SetOriginalOwner(')<capture.index('setScenarioData('),
      'capture does not copy source level':'setLevel(' not in capture,
      'capture does not copy source ScriptData':'setScriptData(' not in capture,
      'capture does not use native convert':'->convert(' not in capture,
      'conversion copies level before conversion hook':conversion.index('setLevel(')<conversion.index('GAMEEVENT_UnitConverted'),
      'conversion source exists until after hook':conversion.index('GAMEEVENT_UnitConverted')<conversion.index('pUnit->kill('),
      'delayed final death loses original killer argument':'kill(false);' in body('CvUnit.cpp','bool CvUnit::doDelayedDeath('),
      'delayed-death flag set after prekill notice':kill.index('GAMEEVENT_UnitPrekill')<kill.index('startDelayedDeath()'),
      'native ScenarioData setter accepts signed integers':'const int iNewData = lua_tointeger(L, 2)' in body('CvLuaUnit.cpp','int CvLuaUnit::lSetScenarioData('),
      'native ScenarioData is save serialized':'visitor(unit.m_iScenarioData)' in u,
      'native ScriptData is save serialized':'visitor(unit.m_strScriptData)' in u,
      'free policy application processes real modifiers':'processPolicies(eIndex, bNewValue ? 1 : -1)' in body('CvPlayer.cpp','void CvPlayer::setHasPolicy('),
    }
    for kind,methods in {'Player':'GetScriptData SetScriptData GetCurrentEra GetUnitByID Cities Units GetCivilizationType IsAlive IsHuman IsGoldenAge IsAnarchy HasPolicy SetHasPolicy GetGoldenAgeProgressMeterTimes100 ChangeGoldenAgeProgressMeter AddNotification GetCityByID GetID',
                         'Unit':'GetScriptData SetScriptData IsGreatPerson IsCombatUnit GetOriginalOwner IsHasPromotion SetHasPromotion IsDead IsDelayedDeath GetLevel GetID GetOwner GetGameTurnCreated GetScenarioData SetScenarioData GetUnitType GetName GetX GetY',
                         'City':'GetOwner GetNumBuilding GetNumActiveBuilding IsResistance IsRazing GetX GetY'}.items():
        for method in methods.split(): checks[kind+':'+method]=bool(re.search(r'Method\(\s*'+method+r'\s*\)',s['CvLua'+kind+'.cpp']))
    for name,valid in checks.items(): assert valid,('CP source contract',name)
    hashes={n:hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest() for n in names}
    for name,expected in {
        'CustomMods.h':'7b7de803c983122ab90d6495480bd93569211fd1036385f5b0f60c6c59a80a11',
        'CvUnit.cpp':'54ea19c86652cc814784e084337dda3a9e47a9e7c4d70d6d7e7e83511b43a875',
        'CvLuaUnit.cpp':'f652c97d6f5cd6383463fbb9a34a733bb6d373fd6b7512011fe3d69107b268ae',
        'CvPlayer.cpp':'893bb58411b5a9b0f8af60f9eaa760c8766590c440ae6bd52c7736b88df56b87',
    }.items(): assert hashes[name]==expected,('changed pinned event-order source',name)
    print(f'PASS {len(checks)} pinned CP v151 source contracts (static, not engine execution)')
    # This native path provides no correlated identity to Lua. Record the gap;
    # do not turn an incorrect GP award into a passing gameplay assertion.
    assert 'pUnit->kill(true)' in civilian_return and 'GET_PLAYER(eToPlayer).initUnit(' in civilian_return
    assert '->convert(' not in civilian_return and 'GAMEEVENT' not in civilian_return and 'setScenarioData' not in civilian_return
    limitation='Native civilian-return recreates units without an identity/conversion hook; returned Great Prophets can still be recognized as fresh births.'
    print('LIMITATION: '+limitation)
    return {'commit':COMMIT,'contracts':len(checks),'sha256':hashes,'known_limitations':[limitation]}

def runtime(d):
    count=0;cases=0
    for speed, in d.execute('SELECT GreatPeoplePercent FROM GameSpeeds'):
        lua=LuaRuntime();g=lua.globals();g.SPEED=speed
        policy=d.execute('SELECT GreatPeopleRateModifier,ExpModifier FROM Policies WHERE Type=?',(POLICY,)).fetchone()
        g.POLICY_GP,g.POLICY_XP=policy
        lua.execute((R/'tools/tests/laureate_mock.lua').read_text())
        controller=(V/'Lua/LC_Commonwealth.lua').read_text()
        g.LoadController=lambda:lua.execute(controller)
        g.LoadController();lua.execute((R/'tools/tests/laureate_assertions.lua').read_text());count+=1
        assert g.LC_TEST_CASES>=26
        cases+=g.LC_TEST_CASES
    return {'speeds':count,'hardening_runs':cases,'required_veteran_cases_per_speed':14}

def assets():
    for path in V.rglob('*.lua'): LuaRuntime().execute('assert(loadstring(...))',path.read_text())
    manifest=ET.parse(R/(NAME+'.modinfo')).getroot()
    declared={e.text:e for e in manifest.findall('Files/File')}
    all_files=files(); assert set(declared)=={p.relative_to(R).as_posix() for p in all_files}
    for path in all_files:
        e=declared[path.relative_to(R).as_posix()]
        assert e.get('md5')==hashlib.md5(path.read_bytes()).hexdigest().upper(),path
    assert len([e for e in ENTRIES if e[0].startswith('TheLaureateCommonwealth/')])==1
    art=list((V/'Art').glob('*.dds'));assert len(art)==40
    for path in art:
        data=path.read_bytes();assert data[:4]==b'DDS '
        with Image.open(path) as im:
            im.load();w,h=im.size
        assert struct.unpack_from('<I',data,28)[0]==max(w,h).bit_length(),('incomplete mip chain',path)
    with Image.open(V/'Art/LC_Dawn.dds') as im: assert im.size==(1024,768)
    for p in V.rglob('*.xml'): ET.parse(p)
    print('PASS Laureate Lua 5.1, manifest checksums, single simulation owner, 40 decoded mipmapped DDS and XML')

def civilopedia(d):
    from civilopedia import replay_index,support_source
    text=dict(d.execute('SELECT Tag,Text FROM Language_en_US'))
    fixture=sqlite3.connect(':memory:');d.backup(fixture);fixture.row_factory=sqlite3.Row
    repairs=[]
    # The archived test cache lacks Arabia's base leader link. Restore only that
    # fixture row from installed game XML; never change the live cache or SQL.
    if not fixture.execute("SELECT 1 FROM Civilization_Leaders WHERE CivilizationType='CIVILIZATION_ARABIA'").fetchone():
        native_xml=support_source().parent.parent/'Gameplay/XML/Civilizations/CIV5Civilizations.xml'
        row=next(r for r in ET.parse(native_xml).findall('Civilization_Leaders/Row') if r.findtext('CivilizationType')=='CIVILIZATION_ARABIA')
        link=(row.findtext('CivilizationType'),row.findtext('LeaderheadType'))
        assert fixture.execute('SELECT 1 FROM Leaders WHERE Type=?',(link[1],)).fetchone()
        fixture.execute('INSERT INTO Civilization_Leaders(CivilizationType,LeaderheadType) VALUES (?,?)',link)
        fixture.commit();repairs.append({'table':'Civilization_Leaders','row':link,'source':'Assets/Gameplay/XML/Civilizations/CIV5Civilizations.xml'})
    broken=sqlite3.connect(':memory:');fixture.backup(broken);broken.row_factory=sqlite3.Row
    broken.execute('UPDATE UnitPromotions SET PediaEntry=NULL WHERE Type IN (?,?)',(VETERAN,GP))
    before=replay_index(broken,text);broken.close()
    assert before['completed_categories']==[1,2,3,4] and before['failed_category']==5,before
    assert before['search']['jin'] is None
    after=replay_index(fixture,text)
    assert after['completed_categories']==list(range(1,17)) and after['failed_category'] is None,after
    jin=d.execute("SELECT ID FROM Civilizations WHERE Type='CIVILIZATION_JIN_DYNASTY'").fetchone()[0]
    assert after['search']['jin']=={'entryName':'Jin','entryID':jin,'entryCategory':10},after
    assert after['search']['wanyan aguda']['entryCategory']==10
    report={'date':'2026-10-31','scope':'Native BNW indexing functions in Lua 5.1 with SQLite/localization adapters; rendered UI acceptance pending',
            'cause':'Laureate internal markers had PEDIA_ATTRIBUTES but NULL PediaEntry; indexing stopped at category 5 before civilizations',
            'promotions':[VETERAN,GP],'archived_fixture_repairs':repairs,'before':before,'after':after}
    fixture.close()
    (V/'docs/CivilopediaValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS Civilopedia regression: original NULL entries stop category 5; corrected source indexes all 16 categories and exact Jin/Aguda search')
    return {'categories':16,'original_failure_reproduced':True,'exact_jin_search':True}

def validate():
    start=time.perf_counter();d=sql();pedia=civilopedia(d);audit=source();runs=runtime(d);assets()
    report={'date':'2026-10-31','scope':'static schema/source and Lua simulation; native gameplay pending',
            'source':audit,**runs,'civilopedia':pedia,'textures':40,'elapsed_seconds':round(time.perf_counter()-start,3)}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return report

if __name__=='__main__': validate()
