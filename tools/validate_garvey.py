"""Real BNW/CP schema, shipped Lua 5.1 scenarios, source contracts and DDS QA."""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,json,re,struct,time
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from build_mod import files
from generate_garvey import R,V,CIV,LEADER,UNIT,OFFICE,CONFIG,TEXT,CITIES

REQUIRED_EVENTS={'EVENTS_CITY','EVENTS_CITY_FOUNDING','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS',
 'EVENTS_UNIT_PREKILL','EVENTS_UNIT_UPGRADES','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED'}

def apply(d,core=None):
 for p in sorted((V/'SQL').glob('*.sql')):
  d.executescript(core if core is not None and p.name=='00_GARVEY_Core.sql' else p.read_text(encoding='utf-8'))

def enabled(d):
 options=dict(d.execute('SELECT Name,Value FROM CustomModOptions'))
 for name in REQUIRED_EVENTS:assert options.get(name)==1,('missing explicit CP option',name)
 return options

def option_regression():
 # Test GARVEY in isolation: Cats currently enables UnitPrekill too, which would
 # otherwise mask a regression in this module's own generator/SQL statement.
 d=database();d.execute('UPDATE CustomModOptions SET Value=0');apply(d)
 options=enabled(d)
 assert {k for k,v in options.items() if v}==REQUIRED_EVENTS,'unnecessary global CP options enabled'
 core=(V/'SQL/00_GARVEY_Core.sql').read_text(encoding='utf-8')
 mutant=core.replace(",'EVENTS_UNIT_PREKILL'",'');assert mutant!=core
 broken=database();broken.execute('UPDATE CustomModOptions SET Value=0');apply(broken,mutant)
 try:enabled(broken)
 except AssertionError as e:assert 'EVENTS_UNIT_PREKILL' in str(e)
 else:raise AssertionError('missing UnitPrekill option escaped the negative regression')
 print('PASS standalone explicit CP option enablement, exact hook-only scope and missing-UnitPrekill negative regression')

def yields(d,b):
 return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType',(b,)))

def inheritance(d):
 for table,old,new in [('Units','UNIT_PIKEMAN',UNIT),('Buildings','BUILDING_PUBLIC_SCHOOL',OFFICE)]:
  a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone();b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
  allow={'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}
  assert a and b
  for k in a.keys():
   if k not in allow:assert a[k]==b[k],(table,k,a[k],b[k])
  prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
  for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
   cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
   if not t.startswith(prefix) or col not in cols:continue
   fields=[c for c in cols if c not in [col,'ID']]
   q='SELECT '+','.join(map(quote,fields))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
   left=Counter(tuple(r) for r in d.execute(q,(old,)));right=Counter(tuple(r) for r in d.execute(q,(new,)))
   if t=='Unit_FreePromotions':right.subtract({('PROMOTION_GARVEY_HALL',):1});right=+right
   if t=='Building_YieldChanges':
    a,b=yields(d,old),yields(d,new)
    for y,k in [('YIELD_CULTURE','OfficeCulture'),('YIELD_PRODUCTION','OfficeProduction')]:a[y]=a.get(y,0)+CONFIG[k]
    assert a==b,(a,b)
   else:assert left==right,(t,left-right,right-left)

def sql():
 d=database()
 for p in files():
  if p.suffix=='.sql' and p.relative_to(R).parts[0]!='TheSubstituteClassroom':d.executescript(p.read_text(encoding='utf-8'))
 tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name!='CustomModOptions'")]
 before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables}
 apply(d)
 for t,rows in before.items():assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('modified peer row/ID',t)
 assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
 assert dict(d.execute('SELECT Name,Value FROM GARVEY_Config'))==CONFIG
 inheritance(d)
 assert tuple(d.execute('SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?',(CIV,)).fetchone())==('BUILDINGCLASS_PUBLIC_SCHOOL',OFFICE)
 assert tuple(d.execute('SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,)).fetchone())==('UNITCLASS_PIKEMAN',UNIT)
 assert d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]==len(CITIES)
 assert CITIES[0]=='Room 101'
 for name,field,value in [('HALL','FriendlyLandsModifier',15),('BLAKE','CombatPercent',15),('DETENTION','CombatPercent',20),('HALL_DETENTION','CombatPercent',10)]:
  assert tuple(d.execute('SELECT '+field+',LostWithUpgrade,CannotBeChosen FROM UnitPromotions WHERE Type=?',('PROMOTION_GARVEY_'+name,)).fetchone())==(value,1,1)
 for suffix,value in [('FULL',-2),('RELIEF',-1)]:assert d.execute('SELECT ExtraHappiness FROM Policies WHERE Type=?',('POLICY_GARVEY_PENALTY_'+suffix,)).fetchone()[0]==value
 assert d.execute("SELECT MilitaryProductionModifier FROM Buildings WHERE Type='BUILDING_GARVEY_AARON'").fetchone()[0]==15
 assert d.execute("SELECT MilitaryProductionModifier FROM Buildings WHERE Type='BUILDING_GARVEY_DETENTION'").fetchone()[0]==20
 assert d.execute("SELECT CultureRateModifier FROM Buildings WHERE Type='BUILDING_GARVEY_DENISE'").fetchone()[0]==15
 assert d.execute("SELECT CultureRateModifier FROM Buildings WHERE Type='BUILDING_GARVEY_TIMOTHY'").fetchone()[0]==10
 for suffix,expected in [('JACQUELINE',{'YIELD_SCIENCE':15}),('OFFICE_SCIENCE',{'YIELD_SCIENCE':10}),('TIMOTHY',{'YIELD_SCIENCE':10,'YIELD_GOLD':10,'YIELD_PRODUCTION':10,'YIELD_FAITH':10})]:
  assert dict(d.execute('SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType=?',('BUILDING_GARVEY_'+suffix,)))==expected
 for key,value in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_GARVEY_'+key,)).fetchone()[0]==value
 keys={'TXT_KEY_GARVEY_'+k for k in TEXT}
 for path in list(V.rglob('*.sql'))+list(V.rglob('*.xml')):
  for key in re.findall(r'TXT_KEY_GARVEY_[A-Z_0-9%]+',path.read_text(encoding='utf-8')):
   assert key in keys or any(k.startswith(key.rstrip('%')) for k in keys),key
 enabled(d)
 option_regression()
 assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
 altered=database();altered.executescript("""ALTER TABLE Units ADD GARVEY_Test INTEGER DEFAULT 0;
 ALTER TABLE Buildings ADD GARVEY_Test INTEGER DEFAULT 0;
 UPDATE Units SET Cost=197,Combat=27,Moves=3,GARVEY_Test=37 WHERE Type='UNIT_PIKEMAN';
 UPDATE Buildings SET Cost=219,GoldMaintenance=4,SpecialistCount=3,GARVEY_Test=73 WHERE Type='BUILDING_PUBLIC_SCHOOL';
 DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_PUBLIC_SCHOOL' AND YieldType='YIELD_CULTURE';
 INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_PUBLIC_SCHOOL','YIELD_PRODUCTION',4);
 """)
 apply(altered);inheritance(altered)
 assert altered.execute('SELECT GARVEY_Test FROM Units WHERE Type=?',(UNIT,)).fetchone()[0]==37
 assert altered.execute('SELECT GARVEY_Test FROM Buildings WHERE Type=?',(OFFICE,)).fetchone()[0]==73
 assert yields(altered,OFFICE)['YIELD_PRODUCTION']==6
 print('PASS Classroom real-schema SQL, human-only identity, exact configured effects, complete inheritance and preserved peer rows/IDs')
 return d

def runtime(d):
 ids={r['Type']:r['ID'] for table in ['Civilizations','Units','Buildings','UnitPromotions','Policies'] for r in d.execute('SELECT Type,ID FROM '+table)}
 results={}
 for speed in ['QUICK','STANDARD','EPIC','MARATHON']:
  for start in [0,150]:
   for name in ['garvey_lifecycle.lua','garvey_combat.lua','garvey_ui.lua','garvey_persistence.lua','garvey_audit.lua','garvey_faults.lua']:
    lua=LuaRuntime();lua.globals().GameInfoTypes=lua.table_from(ids);lua.globals().Config=lua.table_from(CONFIG)
    lua.globals().Text=lua.table_from({'TXT_KEY_GARVEY_'+k:v for k,v in TEXT.items()});lua.globals().StartTurn=start
    lua.globals().Options=lua.table_from(dict(d.execute('SELECT Name,Value FROM CustomModOptions')))
    lua.globals().GameSpeed=speed
    def include(name):
     path=V/'Lua'/f'{name}.lua'
     lua.execute(path.read_text(encoding='utf-8'))
    lua.globals().include=include
    lua.globals().LoadUI=lambda:lua.execute((V/'UI/GARVEY_RollCall.lua').read_text(encoding='utf-8'))
    lua.execute((R/'tools/tests/garvey_mock.lua').read_text(encoding='utf-8'))
    now=time.perf_counter();lua.execute((R/'tools/tests'/name).read_text(encoding='utf-8'))
    results[f'{speed}:{start}:{name}']=round(time.perf_counter()-now,6)
 print('PASS Classroom 48 shipped-Lua 5.1 scenario runs: timers, persistence/faults, combat matrix, targeted lifecycle repair and large-empire UI storms (mock boundary)')
 return results

def sources():
 from audit_cp import COMMIT
 data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in ['CvPlayer.cpp','CvCity.cpp','CvUnit.cpp','CvUnitCombat.cpp','CvLuaPlayer.cpp','CvLuaCity.cpp','CvLuaUnit.cpp','CvBuildingClasses.cpp','CvDllNetMessageHandler.cpp','CustomMods.h']}
 def body(n,sig):
  s=data[n];i=s.index(sig);return s[i:s.index('\n}',i)+2]
 turn=body('CvPlayer.cpp','void CvPlayer::doTurnPostDiplomacy(')
 combat=data['CvUnitCombat.cpp']
 def args(src,event):
  end=src.index('LuaSupport::CallHook(pkScriptSystem, "'+event+'"')
  start=src.rfind('CvLuaArgsHandle args;',0,end)
  return re.findall(r'args->Push\((.*?)\);',src[start:end])
 cp=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/MODS/(1) Community Patch"
 ui=cp/'LUA/CityBannerManager.lua';ui_source=ui.read_text(encoding='utf-8-sig')
 options=ET.parse(cp/'Database Changes/NewCustomModOptions.xml').getroot()
 set_real=body('CvBuildingClasses.cpp','void CvCityBuildings::SetNumRealBuildingTimed(')
 set_free=body('CvBuildingClasses.cpp','void CvCityBuildings::SetNumFreeBuilding(')
 disband=body('CvPlayer.cpp','void CvPlayer::disband(')
 sale=body('CvDllNetMessageHandler.cpp','void CvDllNetMessageHandler::ResponseSellBuilding(')
 process=body('CvPlayer.cpp','void CvPlayer::processBuilding(')
 city_process=body('CvCity.cpp','void CvCity::processBuilding(')
 abi={'UnitPrekill':'iiiiibi','UnitConverted':'iiiib','UnitCreated':'iiiii',
  'UnitUpgraded':'iiib','CityConstructed':'iiibb','CitySoldBuilding':'iii','CityRazed':'iii'}
 contracts={
  'DLL version is exactly 151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',data['CustomMods.h'])),
  'UnitPrekill default is disabled in installed CP options':options.find(".//Row[@Name='EVENTS_UNIT_PREKILL']").get('Value')=='0',
  'UnitPrekill fallback also emits the seven-argument legacy hook':args(data['CvUnit.cpp'],'UnitPrekill')==['((int)eUnitOwner)','GetID()','getUnitType()','getX()','getY()','bDelay','ePlayer'],
  'all subscribed CP lifecycle ABIs are exact':all(re.search(r'#define GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+sig+r'"',data['CustomMods.h']) for name,sig in abi.items()),
  'CP v151 CombatResult and CombatEnded use 15 arguments':all(x in combat for x in ['args->Push(attackerFinalDamage);','args->Push(defenderFinalDamage);','args->Push(plotX);','args->Push(plotY);','"CombatResult"','"CombatEnded"']),
  'combat callback argument orders match exactly':all(args(combat,event)==['iAttackingPlayer','iAttackingUnit','attackerDamage','attackerFinalDamage','attackerMaxHP','iDefendingPlayer','iDefendingUnit','defenderDamage','defenderFinalDamage','defenderMaxHP','iInterceptingPlayer','iInterceptingUnit','interceptorDamage','plotX','plotY'] for event in ['CombatResult','CombatEnded']),
  'native ordinary UnitKilledInCombat lacks winner ID':'DoUnitKilledCombat(NULL, getOwner(), getUnitType())' in data['CvUnit.cpp'],
  'UnitPrekill exposes lifetime before native removal':'GAMEEVENT_UnitPrekill, eUnitOwner, GetID(), getUnitType(), getX(), getY(), bDelay, ePlayer' in data['CvUnit.cpp'],
  'nuclear military deaths pass attacker owner through damage':'pkUnit->changeDamage(kEntry.GetDamage(), eAttackerOwner)' in combat,
  'native reward uses maximum of base melee and ranged strength':'max(pUnit->GetBaseCombatStrength(), pUnit->GetBaseRangedCombatStrength())' in data['CvPlayer.cpp'],
  'native friendly strength uses battle territory':'pBattlePlot->IsFriendlyTerritory(getOwner())' in data['CvUnit.cpp'],
  'promotions use additive strength accumulation':'iModifier += getFriendlyLandsModifier();' in data['CvUnit.cpp'] and 'thisPromotion.GetCombatPercent() * iChange' in data['CvUnit.cpp'],
  'upgrade loses designated promotions':'(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in data['CvUnit.cpp'],
  'free policy modifier supports signed global happiness':'POLICYMOD_EXTRA_HAPPINESS, pkPolicyInfo->GetExtraHappiness() * iChange' in data['CvPlayer.cpp'],
  'policy ExtraHappiness is counted once through capital':body('CvCity.cpp','int CvCity::GetHappinessFromPolicies(').index('if (isCapital())')<body('CvCity.cpp','int CvCity::GetHappinessFromPolicies(').index('GetNumericModifier(POLICYMOD_EXTRA_HAPPINESS)'),
  'native founding turn getter':'int CvLuaCity::lGetGameTurnFounded(' in data['CvLuaCity.cpp'],
  'native culture reward binding':'int CvLuaPlayer::lChangeJONSCulture(' in data['CvLuaPlayer.cpp'],
  'native yield and research precede PlayerDoTurn':turn.index('doResearch()')<turn.index('"PlayerDoTurn"') and turn.index('doTurn()')<turn.index('"PlayerDoTurn"'),
  'Gold Culture and Faith settle before PlayerDoTurn':all(turn.index(n)<turn.index('"PlayerDoTurn"') for n in ['GetTreasury()->DoGold()','changeJONSCultureTimes100(GetTotalJONSCulturePerTurnTimes100())','pGameReligions->DoPlayerTurn(*this)']),
  'real scripted buildings dirty the specific city after mutation':set_real.index('m_paiNumRealBuilding[eIndex] = iNewValue')<set_real.index('m_pCity->processBuilding(')<set_real.index('SetSpecificCityInfoDirty'),
  'free buildings also dirty the specific city after processing':set_free.index('m_pCity->processBuilding(')<set_free.index('SetSpecificCityInfoDirty'),
  'installed CP UI verifies SpecificCityInfoDirty player and city IDs':'function OnSpecificCityInfoDirty(iPlayerID, iCityID, eUpdateType)' in ui_source and 'Events.SpecificCityInfoDirty.Add(OnSpecificCityInfoDirty)' in ui_source,
  'native CountNumBuildings uses maintained count cache':'pPlayer->getNumBuildings(eBuilding)' in body('CvLuaPlayer.cpp','int CvLuaPlayer::lCountNumBuildings(') and 'UpdateNumBuildings(eBuilding)' in process,
  'city replacement effects use native military Production and yield modifiers':'changeMilitaryProductionModifier(pBuildingInfo->GetMilitaryProductionModifier() * iChange)' in city_process and 'changeYieldRateModifier(eYield, (pBuildingInfo->GetYieldModifier(eYield) * iChange))' in city_process,
  'CityRazed precedes native city deletion':disband.index('GAMEEVENT_CityRazed')<disband.index('pCity->kill()'),
  'building sale callback is post-mutation':sale.index('DoSellBuilding(eBuilding)')<sale.index('GAMEEVENT_CitySoldBuilding'),
  'conversion notifies after promotion transfer and deletes old unit without a killer':body('CvUnit.cpp','void CvUnit::convert(').index('GAMEEVENT_UnitConverted')<body('CvUnit.cpp','void CvUnit::convert(').index('pUnit->kill(true, NO_PLAYER)'),
  'city and unit lookup bindings exist':'int CvLuaPlayer::lGetCityByID(' in data['CvLuaPlayer.cpp'] and 'int CvLuaUnit::lIsDead(' in data['CvLuaUnit.cpp'],
  'CP unit lifecycle event ABI':'"UnitConverted",' in data['CustomMods.h'] and '"UnitCreated",' in data['CustomMods.h'],
 }
 for name,ok in contracts.items():assert ok,name
 print('PASS Classroom',len(contracts),'CP v151 source and installed UI/schema contracts (not native execution)')
 return {'commit':COMMIT,'contracts':contracts,'sha256':{n:hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest() for n in data},
  'installed_city_banner_ui_sha256':hashlib.sha256(ui.read_bytes()).hexdigest()}

def art(d):
 for atlas,size,filename,cols,rows in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'GARVEY_%'"):
  p=V/'Art'/filename
  with Image.open(p) as im:im.load();assert im.size==(size*int(cols),size*int(rows)),(p,im.size)
  h=p.read_bytes()[:128];assert h[:4]==b'DDS ' and h[84:88]!=b'DX10'
  assert struct.unpack_from('<I',h,28)[0]==max(size*int(cols),size*int(rows)).bit_length(),p
 for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',OFFICE)]:
  atlas,index=d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
  assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=32 AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
 for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(512,512)),('Board',(768,640))]:
  with Image.open(V/'Art'/f'GARVEY_{stem}.dds') as im:im.load();assert im.size==size
 assert len([p for p in (V/'Art').glob('*.dds') if not p.name.startswith('CWC2_')])==41
 assert ET.parse(V/'Art/GARVEY_LeaderScene.xml').getroot().get('FallbackImage')=='GARVEY_Leader.dds'
 root=ET.parse(V/'UI/GARVEY_RollCall.xml').getroot()
 controls={c.get('ID') for c in root.iter()}
 assert all('Student'+str(i) in controls for i in range(1,6))
 assert 'PatienceMeter' in controls
 refs=set(re.findall(r'Controls\.([A-Za-z_]+)',(V/'UI/GARVEY_RollCall.lua').read_text(encoding='utf-8')))
 assert refs<=controls,refs-controls
 for p in V.rglob('*.lua'):assert '0.1' not in p.read_text(encoding='utf-8')
 print('PASS Classroom 41 decoded DDS textures, mipmaps, atlas references, leader scene and five-choice UI XML')

def validate():
 d=sql();times=runtime(d);audit=sources();art(d)
 (V/'docs').mkdir(parents=True,exist_ok=True)
 report={'native_gameplay':'NOT TESTED IN GAME','lua':'5.1 mocked native boundary','scenarios':times,'source_audit':audit}
 (V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')

if __name__=='__main__':validate()
