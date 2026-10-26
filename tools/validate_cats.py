"""Actual database, native CP source contracts, Lua 5.1 simulations and art checks."""
from pathlib import Path
from collections import Counter
import re, struct, json, math
import hashlib
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote
from build_mod import R, files
from generate_cats import CIV, LEADER, UNIT, TREE, DUMMIES, TEXT
V=R/'The11Cats'

def sql():
 d=database()
 native={t:[tuple(r) for r in d.execute('SELECT * FROM '+quote(t))] for t in ['Civilizations','Leaders','Traits','Units','Buildings']}
 previous={}
 for p in files():
  if p.suffix=='.sql':
   if p.parent.parent==V and not previous:
    for (table,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
     if table!='CustomModOptions':previous[table]=Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(table)))
   d.executescript(p.read_text(encoding='utf-8'))
 def expected_row(table,row):
  # CP's movement event opt-in is required for Threshold exhaustion. No other
  # existing unit column may change when the full collection activates.
  if table!='Units':return tuple(row)
  cols=[r[1] for r in d.execute('PRAGMA table_info(Units)')];row=list(row)
  if row[cols.index('Domain')]=='DOMAIN_LAND' and row[cols.index('Combat')]>0:
   row[cols.index('SendCanMoveIntoEvent')]=1
  return tuple(row)
 for table,rows in previous.items():
  expected=Counter()
  for row,count in rows.items():expected[expected_row(table,row)]+=count
  assert not expected-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(table))),('prior collection rows changed',table)
 assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
 assert d.execute('SELECT LeaderheadType FROM Civilization_Leaders WHERE CivilizationType=?',(CIV,)).fetchone()[0]==LEADER
 u=d.execute('SELECT * FROM Units WHERE Type=?',(UNIT,)).fetchone()
 assert (u['Cost'],u['FaithCost'],u['WorkRate'],u['Moves'],u['Combat'],u['NoMaintenance'],u['Capture'],u['DefaultUnitAI'])==(-1,-1,0,2,0,1,None,None)
 for t in ['Unit_Builds','Unit_ClassUpgrades','Unit_AITypes']:
  assert not d.execute('SELECT 1 FROM '+t+' WHERE UnitType=?',(UNIT,)).fetchone(),t
 tree=d.execute('SELECT * FROM Buildings WHERE Type=?',(TREE,)).fetchone();garden=d.execute("SELECT * FROM Buildings WHERE Type='BUILDING_GARDEN'").fetchone()
 for k in garden.keys():
  if k not in {'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','FreshWater','GreatPeopleRateModifier'}: assert tree[k]==garden[k],k
 assert tree['GreatPeopleRateModifier']==25 and tree['FreshWater']==0
 for (table,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
  columns=[r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')]
  if table.startswith('Building_') and 'BuildingType' in columns:
   keys=[c for c in columns if c not in ['ID','BuildingType']]
   query='SELECT '+','.join(map(quote,keys))+' FROM '+quote(table)+' WHERE BuildingType=?'
   original={tuple(r) for r in d.execute(query,('BUILDING_GARDEN',))}
   if table=='Building_YieldChanges':original={r for r in original if r[0]!='YIELD_CULTURE'}
   assert original<={tuple(r) for r in d.execute(query,(TREE,))},table
 expected={'LUNA':{'YIELD_CULTURE':1},'BONNIE':{'YIELD_CULTURE':1,'YIELD_GOLD':1},'APPA':{'YIELD_CULTURE':1,'YIELD_FOOD':1,'YIELD_PRODUCTION':1},'LOKI':{'YIELD_CULTURE':1,'YIELD_FOOD':1},'KURO':{'YIELD_CULTURE':1,'YIELD_FOOD':1,'YIELD_GOLD':1},'OSCAR':{'YIELD_CULTURE':1,'YIELD_FOOD':2},'BOOMIE':{'YIELD_CULTURE':2},'CHARLOTTE':{'YIELD_CULTURE':1,'YIELD_PRODUCTION':1},'SISI':{'YIELD_CULTURE':1},'MAX':{'YIELD_CULTURE':1,'YIELD_GOLD':1},'FIRST_PAIR':{'YIELD_CULTURE':1},'BONNIE_FAMILY':{'YIELD_FOOD':1,'YIELD_GOLD':1},'SISTERS_BED':{},'MOTHER_DAUGHTER':{},'TREE_FOOD':{'YIELD_FOOD':1}}
 for id,yields in expected.items():
  building='BUILDING_THE11CATS_'+id
  assert dict(d.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(building,)))==yields,id
  b=d.execute('SELECT * FROM Buildings WHERE Type=?',(building,)).fetchone()
  assert b['Cost']==-1 and b['IsDummy']==1 and b['ConquestProb']==0 and b['NeverCapture']==1
  assert b['GreatPeopleRateModifier']==(10 if id in ['LUNA','SISTERS_BED'] else 0)
  assert b['UnmoddedHappiness']==(1 if id in ['LOKI','BOOMIE','SISI','MAX','SISTERS_BED','MOTHER_DAUGHTER'] else 0)
  assert b['Defense']==(500 if id=='CHARLOTTE' else 0)
 assert d.execute("SELECT Yield FROM Building_YieldModifiers WHERE BuildingType='BUILDING_THE11CATS_BONNIE' AND YieldType='YIELD_PRODUCTION'").fetchone()[0]==5
 assert [tuple(r) for r in d.execute("SELECT GrowthMod,Expires,EventDuration,EventDurationScaling FROM CityEventChoices WHERE Type LIKE 'CITY_EVENT_CHOICE_THE11CATS_%'")]==[(5,1,0,0)]*2
 assert d.execute("SELECT COUNT(DISTINCT ID) FROM CityEventChoices WHERE Type LIKE 'CITY_EVENT_CHOICE_THE11CATS_%'").fetchone()[0]==2
 for t,rows in native.items():
  after={r['Type']:tuple(r) for r in d.execute('SELECT * FROM '+quote(t))}
  col=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')].index('Type')
  for row in rows:assert after[row[col]]==expected_row(t,row),(t,row[col],'unrelated row changed')
 keys={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
 for path in V.rglob('*'):
  if path.suffix in ['.lua','.xml','.sql']:
   for key in re.findall(r'TXT_KEY_THE11CATS_[A-Z_0-9]+',path.read_text(encoding='utf-8')):
    assert key.endswith('_') or key in keys,('missing localization',key,path)
 for row in d.execute("SELECT Atlas,IconSize,Filename,IconsPerRow,IconsPerColumn FROM IconTextureAtlases WHERE Atlas LIKE 'THE11CATS_%'"):
  assert (V/'Art'/row['Filename']).is_file()
  with Image.open(V/'Art'/row['Filename']) as im:assert im.size==(int(row['IconSize'])*int(row['IconsPerRow']),int(row['IconSize'])*int(row['IconsPerColumn'])),(row['Filename'],im.size)
 for table in ['Units','Buildings','Leaders','Civilizations','UnitPromotions']:
  for atlas,index in d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+" WHERE Type LIKE '%THE11CATS%'"):
   assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone(),(table,atlas,index)
 assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
 print('PASS The 11 Cats real BNW/CP database: exact bonuses, Garden inheritance, human-only registration, native rows unchanged and art/localization keys')

def source():
 ref=R/'tools/reference';city=(ref/'CvCity.cpp').read_text(encoding='utf-8-sig');binding=(ref/'CvLuaCity.cpp').read_text(encoding='utf-8-sig')
 unit=(ref/'CvUnit.cpp').read_text(encoding='utf-8-sig');mods=(ref/'CustomMods.h').read_text(encoding='utf-8-sig')
 for method in ['IsCityEventChoiceActive','DoCityEventChoice','DoCancelCityEventChoice','GetWeLoveTheKingDayCounter','SetWeLoveTheKingDayCounter','GetGameTurnFounded','GetOriginalOwner']:
  assert 'Method('+method+');' in binding,method
 assert 'Method(GetScriptData);' not in binding,'do not invent a city ScriptData API'
 assert 'ChangeGrowthFromEvent(pkEventChoiceInfo->getGrowthMod())' in city
 assert 'ChangeGrowthFromEvent(pkEventChoiceInfo->getGrowthMod() * -1)' in city
 assert 'if (pkEventChoiceInfo->getEventDuration() > 0)' in city
 assert 'IsEventChoiceActive(eChosenEventChoice) && pkEventChoiceInfo->Expires()' in city
 assert 'iTotalYield *= 100 + getGrowthMods(' in city
 assert 'getCaptureUnitType(getOwner()) != NO_UNIT' in unit
 assert '"CityBeginsWLTKD", "iiii"' in mods and '"CityExtendsWLTKD", "iiii"' in mods
 assert 'GameEvents.UnitPrekill.Add(function(iPlayer, iUnit, iUnitType, iX, iY, bDelay, iByPlayer)' in mods
 assert '"CityCaptureComplete"' in (ref/'CvPlayer.cpp').read_text(encoding='utf-8-sig')
 player_binding=(ref/'CvLuaPlayer.cpp').read_text(encoding='utf-8-sig')
 init=player_binding.split('int CvLuaPlayer::lInitUnit(lua_State* L)',1)[1].split('int CvLuaPlayer::lInitUnitWithNameOffset',1)[0]
 assert 'luaL_optint(L, 5, NO_UNITAI)' in init,'native optional Unit AI default'
 for evidence in ['changeGreatPeopleRateModifier(pBuildingInfo->GetGreatPeopleRateModifier() * iChange)',
                  'int iCityMod = getTotalGreatPeopleRateModifier() + GetSpecialistRateModifierFromBuildings(eSpecialist)',
                  'changeYieldRateModifier(eYield, (pBuildingInfo->GetYieldModifier(eYield) * iChange))',
                  'iStrengthValue += iBuildingDefense;',
                  'ChangeUnmoddedHappinessFromBuildings(pBuildingInfo->GetUnmoddedHappiness() * iChange)',
                  'visitor(city.m_iGrowthEvent);','visitor(city.m_abEventChoiceActive);']:
  assert evidence in city,evidence
 print('PASS pinned CP v151 source contracts: exact reversible local growth, WLTKD counter semantics and post-mutation recovery events (source audit, not runtime)')

def bonuses():
 # Independent numerical expectations against the actual SQL rows. These small
 # city arithmetic models are NOT a replacement for native yield acceptance.
 d=database()
 for p in files():
  if p.suffix=='.sql':d.executescript(p.read_text(encoding='utf-8'))
 expected={
  'LUNA':(0,0,0,1,0,10,0,0), 'BONNIE':(0,0,1,1,0,0,5,0),
  'APPA':(1,1,0,1,0,0,0,0), 'LOKI':(1,0,0,1,1,0,0,0),
  'KURO':(1,0,1,1,0,0,0,0), 'OSCAR':(2,0,0,1,0,0,0,0),
  'BOOMIE':(0,0,0,2,1,0,0,0), 'CHARLOTTE':(0,1,0,1,0,0,0,5),
  'SISI':(0,0,0,1,1,0,0,0), 'MAX':(0,0,1,1,1,0,0,0),
 }
 actual={}
 for id,want in expected.items():
  name='BUILDING_THE11CATS_'+id
  row=d.execute('SELECT * FROM Buildings WHERE Type=?',(name,)).fetchone()
  yields=dict(d.execute('SELECT YieldType,Yield FROM Building_YieldChanges WHERE BuildingType=?',(name,)))
  prod=d.execute("SELECT Yield FROM Building_YieldModifiers WHERE BuildingType=? AND YieldType='YIELD_PRODUCTION'",(name,)).fetchone()
  got=tuple(yields.get('YIELD_'+y,0) for y in ['FOOD','PRODUCTION','GOLD','CULTURE'])+(row['UnmoddedHappiness'],row['GreatPeopleRateModifier'],prod[0] if prod else 0,row['Defense']/100)
  assert got==want,(id,got,want)
  actual[id]=got
  assert row['BuildingProductionModifier']==0,(id,'wrong production scope')
 assert 3000*(100+actual['BONNIE'][6])//100==3150
 assert 500*(100+25+actual['LUNA'][5])//100==675
 assert 3000+actual['CHARLOTTE'][7]*100==3500
 growth=[]
 for choice in ['SISI','MOTHER_DAUGHTER']:
  row=d.execute('SELECT GrowthMod,Expires,EventDuration FROM CityEventChoices WHERE Type=?',('CITY_EVENT_CHOICE_THE11CATS_'+choice,)).fetchone()
  assert tuple(row)==(5,1,0)
  growth.append(row[0])
 # Native growth applies AFTER consumption; positive surplus only.
 def food_rate(food,consumption,modifier):
  surplus=food-consumption
  return surplus*(100+modifier)//100 if surplus>0 else surplus
 assert food_rate(2000,1400,growth[0])==630
 assert food_rate(2000,1400,sum(growth))==660
 assert food_rate(500,1400,sum(growth))==-900
 genders={'AUSTIN':'Male','LUNA':'Female','BONNIE':'Female','APPA':'Male','LOKI':'Female','KURO':'Female','OSCAR':'Male','BOOMIE':'Female','CHARLOTTE':'Female','SISI':'Female','MAX':'Male'}
 for id,gender in genders.items():
  assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_THE11CATS_'+id+'_GENDER',)).fetchone()[0]==gender
 print('PASS all ten personal effects: SQL-backed local GP/general Production/Strength/Happiness/growth arithmetic and eleven canonical genders (models, not native execution)')

def preserved():
 # Fingerprints from the shipped a1d2fb3 implementation. Gameplay definitions,
 # inheritance order and atlases must remain byte-for-byte identical in this pass.
 baseline={
  '00_Core':'914f6936cc8b8a980f62905c2444568f302a0cf6f7f97a94b0f57bc37bf67fa7',
  '01_Inheritance':'e2b7ec48451de74c5a870b543942c1d744217c1ab0fc795fc11b1c09a35a906e',
  '02_Effects':'8d9093f8b59abf13d425b7aff4c8abd6d553d35b357dfe58bd7be482b83efc45',
  '03_Art':'4c2a26c9f1ab04d126f6aa8a69b8d1e1d3cd809f99a68888a3f357bc09159ca3',
 }
 for name,digest in baseline.items():
  data=(V/'SQL'/('THE11CATS_'+name+'.sql')).read_text(encoding='utf-8').encode('utf-8')
  assert hashlib.sha256(data).hexdigest()==digest,('changed gameplay baseline',name)
 print('PASS shipped gameplay/identity/inheritance/atlas SQL fingerprints; no numeric changes or new gameplay IDs')

def runtime():
 for test in ['cats_starts.lua','cats_lifecycle.lua','cats_bonds.lua','cats_edges.lua','cats_ui.lua','cats_resilience.lua','cats_faults.lua','cats_notices.lua','cats_wltkd.lua','cats_performance.lua','cats_metadata.lua','cats_transactions.lua','cats_growth_faults.lua','cats_native_context.lua']:
  lua=LuaRuntime();g=lua.globals()
  def include(name):
   if name not in ['IconSupport','InstanceManager']:lua.execute((V/'Lua'/f'{name}.lua').read_text(encoding='utf-8'))
  def reload():lua.execute('ResetContextEvents()');include('THE11CATS_Manager')
  g.include=include;g.Reload=reload;g.LoadUI=lambda:lua.execute((V/'UI/THE11CATS_Household.lua').read_text(encoding='utf-8'))
  lua.execute((R/'tools/tests/cats_mock.lua').read_text(encoding='utf-8'));include('THE11CATS_Manager')
  lua.execute((R/'tools/tests'/test).read_text(encoding='utf-8'))
 print('PASS Lua 5.1 behavioral simulations; no Civ V process was launched')

def assets():
 for path in V.rglob('*.xml'):ET.parse(path)
 check=LuaRuntime().eval('function(s,n) local f,e=loadstring(s,n);assert(f,e) end')
 for p in V.rglob('*.lua'):check(p.read_text(encoding='utf-8'),str(p))
 for p in (V/'Art').glob('*.dds'):
  data=p.read_bytes();assert data[:4]==b'DDS ' and data[84:88]!=b'DX10'
  with Image.open(p) as im:
   im.load();assert struct.unpack_from('<I',data,28)[0]==int(math.log2(max(im.size)))+1,('incomplete mip chain',p)
   if p.stem in ['THE11CATS_Leader','THE11CATS_Dawn','THE11CATS_Household','THE11CATS_Map']:assert data[84:88]==b'DXT5'
 ui=(V/'UI/THE11CATS_Household.lua').read_text(encoding='utf-8');xml=ET.parse(V/'UI/THE11CATS_Household.xml')
 ids={e.get('ID') for e in xml.iter() if e.get('ID')}
 assert set(re.findall(r'Controls\.([A-Za-z_]+)',ui))<=ids
 assert 'ResetInstances' not in ui and 'SetUpdate' not in ui
 with Image.open(R/'art-source/The11Cats/Emblem.png') as im:assert im.width==im.height and im.width>=1024
 source=R/'art-source/The11Cats';identity=json.loads((source/'Identity.json').read_text(encoding='utf-8'))
 from cats_data import CATS
 names=[row[0] for row in CATS];assert [p['id'] for p in identity['portraits']]==names
 assert len({p['sha256'] for p in identity['portraits']})==11
 with Image.open(source/'Cats.png') as atlas:
  cells=[]
  for i,p in enumerate(identity['portraits']):
   assert p['index']==i and p['sha256']==hashlib.sha256((source/p['source']).read_bytes()).hexdigest()
   with Image.open(source/p['source']) as im:assert im.width==im.height and im.width>=1024
   cell=atlas.crop(((i%4)*256,(i//4)*256,(i%4+1)*256,(i//4+1)*256))
   cells.append(hashlib.sha256(cell.tobytes()).hexdigest())
  assert len(set(cells))==11 and atlas.crop((768,512,1024,768)).getbbox() is None
 assert [p['id'] for p in identity['emblem']]==names and len(identity['emblem'])==11
 for i,a in enumerate(identity['emblem']):
  for b in identity['emblem'][i+1:]:assert math.dist(a['center'],b['center'])>(a['diameter']+b['diameter'])/2,'overlapping cat medallions'
 assert identity['emblem'][0]['diameter']>max(p['diameter'] for p in identity['emblem'][1:])
 assert identity['scene_cats']=={'Leader':['AUSTIN'],'Dawn':['AUSTIN','LUNA']}
 assert len(list((V/'Art').glob('*.dds')))==50
 print('PASS 11 unique source portraits/atlas cells, canonical indices, nonoverlapping 11-cat emblem, legacy full mip chains and BC3 scenes')
 print('PASS XML, Lua 5.1, UI controls, reusable instance architecture and decoded mipmapped DDS assets')

def validate():preserved();sql();source();bonuses();runtime();assets()
if __name__=='__main__':validate()
