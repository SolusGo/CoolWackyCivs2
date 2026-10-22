"""Actual database, native CP source contracts, Lua 5.1 simulations and art checks."""
from pathlib import Path
from collections import Counter
import re, struct
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
 for table,rows in previous.items():assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(table))),('prior collection rows changed',table)
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
  for row in rows:assert after[row[col]]==row,(t,row[col],'unrelated row changed')
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
 print('PASS pinned CP v151 source contracts: exact reversible local growth, WLTKD counter semantics and post-mutation recovery events (source audit, not runtime)')

def runtime():
 for test in ['cats_starts.lua','cats_lifecycle.lua','cats_bonds.lua','cats_edges.lua','cats_ui.lua','cats_resilience.lua']:
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
  data=p.read_bytes();assert data[:4]==b'DDS ' and struct.unpack_from('<I',data,28)[0]>1
  with Image.open(p) as im:im.load()
 ui=(V/'UI/THE11CATS_Household.lua').read_text(encoding='utf-8');xml=ET.parse(V/'UI/THE11CATS_Household.xml')
 ids={e.get('ID') for e in xml.iter() if e.get('ID')}
 assert set(re.findall(r'Controls\.([A-Za-z_]+)',ui))<=ids
 assert 'ResetInstances' not in ui and 'SetUpdate' not in ui
 with Image.open(R/'art-source/The11Cats/Emblem.png') as im:assert im.width==im.height and im.width>=1024
 print('PASS XML, Lua 5.1, UI controls, reusable instance architecture and decoded mipmapped DDS assets')

def validate():sql();source();runtime();assets()
if __name__=='__main__':validate()
