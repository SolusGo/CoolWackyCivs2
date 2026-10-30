"""Actual-schema SQL, shipped Lua 5.1, CP source contracts and decoded art checks.

These are static/simulated checks. They do not claim native Civ V acceptance.
"""
from collections import Counter
from pathlib import Path
import hashlib,json,re,struct,sys,time
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
    }
    for kind,methods in {'Player':'GetScriptData SetScriptData GetCurrentEra GetUnitByID Cities Units GetCivilizationType IsAlive IsHuman IsGoldenAge IsAnarchy HasPolicy SetHasPolicy GetGoldenAgeProgressMeterTimes100 ChangeGoldenAgeProgressMeter AddNotification GetCityByID GetID',
                         'Unit':'GetScriptData SetScriptData IsGreatPerson IsCombatUnit GetOriginalOwner IsHasPromotion SetHasPromotion IsDead IsDelayedDeath GetLevel GetID GetUnitType GetName GetX GetY',
                         'City':'GetOwner GetNumBuilding GetNumActiveBuilding IsResistance IsRazing GetX GetY'}.items():
        for method in methods.split(): checks[kind+':'+method]=bool(re.search(r'Method\(\s*'+method+r'\s*\)',s['CvLua'+kind+'.cpp']))
    for name,valid in checks.items(): assert valid,('CP source contract',name)
    hashes={n:hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest() for n in names}
    print(f'PASS {len(checks)} pinned CP v151 source contracts (static, not engine execution)')
    return {'commit':COMMIT,'contracts':len(checks),'sha256':hashes}

def runtime(d):
    count=0
    for speed, in d.execute('SELECT GreatPeoplePercent FROM GameSpeeds'):
        lua=LuaRuntime();g=lua.globals();g.SPEED=speed
        policy=d.execute('SELECT GreatPeopleRateModifier,ExpModifier FROM Policies WHERE Type=?',(POLICY,)).fetchone()
        g.POLICY_GP,g.POLICY_XP=policy
        lua.execute((R/'tools/tests/laureate_mock.lua').read_text())
        controller=(V/'Lua/LC_Commonwealth.lua').read_text()
        g.LoadController=lambda:lua.execute(controller)
        g.LoadController();lua.execute((R/'tools/tests/laureate_assertions.lua').read_text());count+=1
    return count

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

def validate():
    start=time.perf_counter();d=sql();audit=source();speeds=runtime(d);assets()
    report={'date':'2026-10-30','scope':'static schema/source and Lua simulation; native gameplay pending',
            'source':audit,'speeds':speeds,'textures':40,'elapsed_seconds':round(time.perf_counter()-start,3)}
    (V/'docs').mkdir(exist_ok=True)
    (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return report

if __name__=='__main__': validate()
