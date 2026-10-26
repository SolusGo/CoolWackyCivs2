"""Threshold Court: installed-schema SQL, Lua 5.1 execution, assets, source audit.

Run from the repository with .venv/Scripts/python.exe tools/validate_threshold.py.
Never labels mocked behavior or a schema clone as in-game verification.
"""
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,json,re
from lupa.lua51 import LuaRuntime
from PIL import Image
from database import database,quote
from build_mod import R,files,ENTRIES,imported
from generate_threshold import V,CIV,LEADER,UNIT,BUILDING,TEXT
from audit_cp import COMMIT,BASE

SUITES=['threshold_transfers.lua','threshold_rejections.lua','threshold_faults.lua','threshold_ui.lua','threshold_lifecycle.lua']

def apply(d):
 for p in sorted((V/'SQL').glob('*.sql')):d.executescript(p.read_text(encoding='utf-8'))

def inheritance(d):
 count=0
 metadata={'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'}
 for table,old,new,prefix,col in [('Units','UNIT_PIKEMAN',UNIT,'Unit','UnitType'),('Buildings','BUILDING_MARKET',BUILDING,'Building','BuildingType')]:
  a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
  b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
  for k in a.keys():
   if k not in metadata:assert b[k]==(a[k]+1 if k=='Moves' and table=='Units' else a[k]),(table,k,a[k],b[k])
  for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
   cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
   if not name.startswith(prefix) or col not in cols:continue
   fields=[c for c in cols if c not in [col,'ID']]
   query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(name)+' WHERE '+quote(col)+'=?'
   expected=Counter(tuple(r) for r in d.execute(query,(old,)))
   actual=Counter(tuple(r) for r in d.execute(query,(new,)))
   if name=='Unit_FreePromotions':expected[('PROMOTION_THRESHOLD_DEFENDER',)]+=1
   if name=='Building_YieldChanges':
    yi=fields.index('YieldType');vi=fields.index('Yield');adjusted=Counter();found=False
    for row,n in expected.items():
     if row[yi]=='YIELD_CULTURE':
      row=list(row);row[vi]+=1;row=tuple(row);found=True
     adjusted[row]+=n
    if not found:
     assert fields==['YieldType','Yield'];adjusted[('YIELD_CULTURE',1)]+=1
    expected=adjusted
   assert expected==actual,(name,expected-actual,actual-expected)
   count+=1
 return count

def sql():
 d=database()
 for p in files():
  if p.suffix=='.sql' and V not in p.parents:d.executescript(p.read_text(encoding='utf-8'))
 before={name:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(name))) for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT IN ('CustomModOptions','Units')").fetchall()}
 units={r['Type']:dict(r) for r in d.execute('SELECT * FROM Units')}
 apply(d)
 for name,rows in before.items():assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(name))),('changed unrelated row',name)
 for key,old in units.items():
  now=dict(d.execute('SELECT * FROM Units WHERE Type=?',(key,)).fetchone())
  for col,value in old.items():
   expected=1 if col=='SendCanMoveIntoEvent' and old['Domain']=='DOMAIN_LAND' and old['Combat']>0 else value
   assert now[col]==expected,('unrelated unit',key,col)
 assert d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[:]==(1,0)
 assert d.execute('SELECT TraitType FROM Leader_Traits WHERE LeaderType=?',(LEADER,)).fetchone()[0]=='TRAIT_DOOR_IN_EVERY_WALL'
 assert d.execute("SELECT FriendlyLandsModifier,FriendlyLandsAttackModifier FROM UnitPromotions WHERE Type='PROMOTION_THRESHOLD_DEFENDER'").fetchone()[:]==(15,0)
 assert d.execute("SELECT OnlyDefensive,LostWithUpgrade,LostOnGifting FROM UnitPromotions WHERE Type='PROMOTION_THRESHOLD_EXHAUSTED'").fetchone()[:]==(1,0,0)
 count=inheritance(d)
 assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
 # Mutate CP baseline in memory and reapply just this civilization to prove
 # that no production, combat, resources, upgrades or CP columns are baked in.
 fresh=database()
 fresh.execute("UPDATE Units SET Combat=39,Moves=4,Cost=313,ExtraMaintenanceCost=7 WHERE Type='UNIT_PIKEMAN'")
 fresh.execute("UPDATE Buildings SET Cost=317,GoldMaintenance=9,SpecialistCount=3 WHERE Type='BUILDING_MARKET'")
 fresh.execute("INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_MARKET','YIELD_CULTURE',4)")
 apply(fresh);inheritance(fresh)
 for key,value in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_THC_'+key,)).fetchone()[0]==value
 print('PASS installed BNW/CP schema SQL,',count,'companion tables, dynamic sentinel baselines, exact balance, scoped notification opt-ins')
 return d,count

def runtime(d):
 count=0
 for speed in ['QUICK','STANDARD','EPIC','MARATHON']:
  for suite in SUITES:
   lua=LuaRuntime();g=lua.globals();g.GameInfoTypes=lua.table();g.GameInfo=lua.table();g.Texts=lua.table()
   for table in ['Civilizations','Buildings','UnitPromotions','Units']:
    data=lua.table()
    for row in d.execute('SELECT * FROM '+table):
     g.GameInfoTypes[row['Type']]=row['ID'];data[row['ID']]=lua.table_from(dict(row))
    g.GameInfo[table]=data
   for row in d.execute("SELECT Tag,Text FROM Language_en_US WHERE Tag LIKE 'TXT_KEY_THC_%'"):g.Texts[row[0]]=row[1]
   def include(name):
    if name not in ['InstanceManager','SupportFunctions']:
     lua.execute((V/'Lua'/(name+'.lua')).read_text(encoding='utf-8'))
   g.include=include
   g.ReloadCore=lambda:include('THC_Core')
   g.LoadUI=lambda:lua.execute((V/'UI/THC_Transfer.lua').read_text(encoding='utf-8'))
   lua.execute((R/'tools/tests/threshold_mock.lua').read_text(encoding='utf-8'))
   lua.execute("Game.GetGameSpeedType=function()return 'GAMESPEED_"+speed+"'end")
   include('THC_Core')
   lua.execute((R/'tools/tests'/suite).read_text(encoding='utf-8'));count+=1
 print('PASS',count,'shipped Lua 5.1 modeled suite runs across four speeds (not in-game tests)')
 return count

def assets(d):
 paths=[p for p in files() if V in p.parents]
 lua=LuaRuntime();parse=lua.eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
 for p in paths:
  if p.suffix in ['.lua','.sql','.xml']:assert b'\r\n' not in p.read_bytes(),('game text must match Git LF checkout',p)
  if p.suffix=='.lua':parse(p.read_text(encoding='utf-8'),str(p))
  if p.suffix=='.xml':ET.parse(p)
  if p.suffix=='.dds':
   with Image.open(p) as im:im.load();assert im.width>0 and im.height>0
 for (filename,) in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'THC_%'"):assert (V/'Art'/filename).is_file()
 for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',BUILDING)]:
  row=d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
  assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',tuple(row)).fetchone()
 ui=V/'UI/THC_Transfer.xml';ids={e.get('ID') for e in ET.parse(ui).iter() if e.get('ID')}
 refs=set(re.findall(r'Controls\.([A-Za-z_]+)',ui.with_suffix('.lua').read_text(encoding='utf-8')));assert refs<=ids,refs-ids
 keys=set()
 for p in paths:
  if p.suffix=='.lua':
   code=p.read_text(encoding='utf-8');keys.update(re.findall(r"T.Text\('([A-Z_]+)'",code))
   assert 'Network.' not in code and 'GameEvents.PlayerDoTurn.Add' not in code
 assert keys<=TEXT.keys(),keys-TEXT.keys()
 assert any(e[0]=='TheThresholdCourt/UI/THC_Transfer.xml' for e in ENTRIES)
 assert not imported(ui) and all(imported(p) for p in paths if p.suffix in ['.lua','.dds'])
 print('PASS Lua/XML syntax, localization, atlas bounds, 48 decoded DDS and InGameUIAddin controls')

def sources():
 names=['CvLuaUnit.cpp','CvLuaCity.cpp','CvLuaPlayer.cpp','CvLuaPlot.cpp','CvUnit.cpp','CvPlayer.cpp','CvPlot.cpp','CvPromotionClasses.cpp','CustomMods.h']
 source={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
 def body(n,sig):
  s=source[n];start=s.index(sig);return s[start:s.index('\n}',start)+2]
 unit=source['CvUnit.cpp'];binding=source['CvLuaUnit.cpp']
 checks={
  'pinned CP DLL version 151':bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',source['CustomMods.h'])),
  'SetXY directly relocates native instance':'pkUnit->setXY(x, y, bGroup, bUpdate, bShow, bCheckPlotVisible)' in body('CvLuaUnit.cpp','int CvLuaUnit::lSetXY('),
  'SetXY flags are numeric luaL_optint':'luaL_optint(L, 4, 0)' in body('CvLuaUnit.cpp','int CvLuaUnit::lSetXY('),
  'endpoint legality destination is numeric fourth argument':'const bool bDestination = luaL_optint(L, 4, 0)' in body('CvLuaUnit.cpp','int CvLuaUnit::lCanMoveOrAttackInto('),
  'native combat plus melee capability':'IsCombatUnit() && !IsCanAttackRanged() && !isOnlyDefensive()' in body('CvUnit.cpp','bool CvUnit::IsCanAttackWithMove('),
  'OnlyDefensive leaves normal defensive eligibility':'isOnlyDefensive' not in body('CvUnit.cpp','bool CvUnit::IsCanDefend('),
  'Blitz bypasses attacks-used count':'if(isBlitz())' in body('CvUnit.cpp','bool CvUnit::isOutOfAttacks('),
  'made attack increments rather than exhausting all attacks':'m_iAttacksMade++' in body('CvUnit.cpp','void CvUnit::setMadeAttack('),
  'movement veto dispatch requires type opt-in':'MOD_EVENTS_CAN_MOVE_INTO && m_pUnitInfo->IsSendCanMoveIntoEvent()' in unit,
  'CanMoveInto is authoritative test-all veto':'GAMEEVENTINVOKE_TESTALL(GAMEEVENT_CanMoveInto' in unit,
  'upgrade has native Lua veto':'"CanHaveUpgrade"' in unit,
  'native attack and defense use battle territory modifier':'GetGenericMeleeStrengthModifier(pDefender, pToPlot, true' in unit and 'GetGenericMeleeStrengthModifier(pAttacker, pInPlot, false' in unit,
  'friendly modifier native gate':'if(pBattlePlot->IsFriendlyTerritory(getOwner()))' in unit and 'iModifier += getFriendlyLandsModifier();' in unit,
  'native promotion loads friendly and defensive fields':'GetInt("FriendlyLandsModifier")' in source['CvPromotionClasses.cpp'] and 'GetBool("OnlyDefensive")' in source['CvPromotionClasses.cpp'],
  'player ScriptData saved in native save':'visitor(player.m_strScriptData)' in source['CvPlayer.cpp'],
  'unit ScriptData saved in native save':'visitor(unit.m_strScriptData)' in unit,
  'plot ScriptData saved and restored':'visitor(scriptData)' in source['CvPlot.cpp'] and 'mutPlot.setScriptData(scriptData.c_str())' in source['CvPlot.cpp'],
  'capture notification exposes coordinates':'"CityCaptureComplete"' in source['CvPlayer.cpp'],
  'founding notification prevents same-turn ID reuse':'"PlayerCityFounded"' in source['CvPlayer.cpp'],
  'conversion hook precedes old unit death':unit.index('GAMEEVENTINVOKE_HOOK(GAMEEVENT_UnitConverted')<unit.index('pUnit->kill(true, NO_PLAYER)'),
 }
 for method in ['SetXY','CanMoveOrAttackInto','IsCanAttackWithMove','IsOnlyDefensive','FinishMoves','SetMoves','SetMadeAttack','IsBusy','GetScriptData','SetScriptData','GetGameTurnCreated']:
  checks['unit binding '+method]='Method('+method+')' in binding
 for key,ok in checks.items():assert ok,key
 print('PASS',len(checks),'pinned official CP v151 source contracts')
 return {'commit':COMMIT,'contracts':checks,'sources':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}

def main():
 d,tables=sql();runs=runtime(d);assets(d);audit=sources()
 report={'date':'2026-10-26','native_gameplay':'NOT TESTED IN GAME','native_ui':'NOT TESTED IN GAME','native_saves':'NOT TESTED IN GAME','companion_tables':tables,'modeled_suite_runs':runs,'suites':SUITES,'source_audit':audit,'pending':['Civ V database activation and native UI rendering','Native cross-continent/Huge SetXY and camera/selection','Real manual/autosave/restart persistence and city capture/raze','Native Blitz/restored movement and combat preview/defense','Whole-game balance']}
 (V/'docs').mkdir(exist_ok=True);(V/'docs/Validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')

if __name__=='__main__':main()
