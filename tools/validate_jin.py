"""Installed-schema Jin validation and executable shipped Lua 5.1 behavior tests."""
from collections import Counter
import json,hashlib,re,time
from pathlib import Path
from xml.etree import ElementTree as ET
from lupa.lua51 import LuaRuntime
from PIL import Image
from database import database,quote
from build_mod import R,files,imported,ENTRIES,VERSION
from generate_jin import V,C,CIV

TABLES=['Units','UnitClasses','Buildings','BuildingClasses','UnitPromotions','Features','Terrains','Technologies','GameSpeeds','Civilizations','Domains','Yields','Civilization_UnitClassOverrides','Unit_FreePromotions','Unit_ResourceQuantityRequirements']
SUITES=['jin_economy.lua','jin_diplomacy.lua','jin_military.lua','jin_landmarks.lua','jin_ui.lua','jin_lifecycle.lua','jin_reliability.lua','jin_autonomy.lua','jin_transactions.lua','jin_hardening.lua']

def apply(d):
 for path in sorted((V/'SQL').glob('*.sql')):d.executescript(path.read_text(encoding='utf-8'))

def sql():
 d=database()
 for path in files():
  if path.suffix=='.sql' and V not in path.parents:d.executescript(path.read_text(encoding='utf-8'))
 before={name:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(name))) for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name!='CustomModOptions'").fetchall()}
 apply(d)
 for name,rows in before.items():assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(name))),('unrelated rows changed',name)
 assert d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[:]==(1,0)
 # Inheritance is evaluated at mod activation, including unknown future CP columns.
 injected=database();injected.executescript("ALTER TABLE Units ADD JIN_Test INTEGER DEFAULT 0;UPDATE Units SET JIN_Test=77,WorkRate=140 WHERE Type IN ('UNIT_WORKER','UNIT_CARAVAN');INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_WORKER','PROMOTION_AMPHIBIOUS');INSERT INTO Unit_ProductionModifierBuildings(UnitType,BuildingType,ProductionModifier) VALUES ('UNIT_WORKER','BUILDING_MONUMENT',7),('UNIT_CARAVAN','BUILDING_MONUMENT',9);")
 apply(injected)
 assert injected.execute("SELECT WorkRate,JIN_Test,Moves FROM Units WHERE Type='UNIT_JIN_MOUNTED_VILLAGER'").fetchone()[:]==(210,77,3)
 assert injected.execute("SELECT JIN_Test FROM Units WHERE Type='UNIT_JIN_REINDEER_TRADER'").fetchone()[0]==77
 trader=d.execute("SELECT Food,HurryCostModifier,Moves,Trade,Class FROM Units WHERE Type='UNIT_JIN_REINDEER_TRADER'").fetchone()
 assert tuple(trader)==(1,0,2,1,'UNITCLASS_CARAVAN')
 assert tuple(d.execute("SELECT Food,HurryCostModifier,Moves FROM Units WHERE Type='UNIT_CARAVAN'").fetchone())==(0,20,1)
 for unit,value in [('MOUNTED_VILLAGER',7),('REINDEER_TRADER',9)]:assert injected.execute("SELECT ProductionModifier FROM Unit_ProductionModifierBuildings WHERE UnitType=? AND BuildingType='BUILDING_MONUMENT'",('UNIT_JIN_'+unit,)).fetchone()[0]==value
 assert injected.execute("SELECT 1 FROM Unit_FreePromotions WHERE UnitType='UNIT_JIN_MOUNTED_VILLAGER' AND PromotionType='PROMOTION_AMPHIBIOUS'").fetchone()
 for table in ['Unit_Builds','Unit_AITypes','Unit_ResourceQuantityRequirements']:
  fields=[r[1] for r in d.execute('PRAGMA table_info('+table+')') if r[1] not in ['UnitType','ID']]
  q='SELECT '+','.join(map(quote,fields))+' FROM '+table+' WHERE UnitType=?'
  assert Counter(map(tuple,d.execute(q,('UNIT_WORKER',))))==Counter(map(tuple,d.execute(q,('UNIT_JIN_MOUNTED_VILLAGER',))))
 for table in ['Unit_AITypes','Unit_FreePromotions','Unit_ClassUpgrades']:
  fields=[r[1] for r in d.execute('PRAGMA table_info('+table+')') if r[1] not in ['UnitType','ID']]
  q='SELECT '+','.join(map(quote,fields))+' FROM '+table+' WHERE UnitType=?'
  assert Counter(map(tuple,d.execute(q,('UNIT_CARAVAN',))))==Counter(map(tuple,d.execute(q,('UNIT_JIN_REINDEER_TRADER',))))
 for u in C['units']:
  row=d.execute('SELECT * FROM Units WHERE Type=?',('UNIT_JIN_'+u['key'],)).fetchone();assert row and row['Cost']==u['cost']
  for field in ['Description','Help','Strategy','Civilopedia']:assert d.execute('SELECT 1 FROM Language_en_US WHERE Tag=?',(row[field],)).fetchone(),row[field]
  for field,table in [('PrereqTech','Technologies'),('Class','UnitClasses'),('CombatClass','UnitCombatInfos')]:
   if row[field]:assert d.execute('SELECT 1 FROM '+table+' WHERE Type=?',(row[field],)).fetchone(),(field,row[field])
  assert row['UnitFlagAtlas']=='JIN_FLAG_ATLAS'
 assert d.execute("SELECT WorkRate FROM Units WHERE Type='UNIT_JIN_EMISSARY'").fetchone()[0]==0
 assert not d.execute("SELECT * FROM Unit_Builds WHERE UnitType='UNIT_JIN_EMISSARY'").fetchone()
 assert d.execute("SELECT TradeRouteYieldModifier FROM Policies WHERE Type='POLICY_JIN_TRIBUTARY_TRADE'").fetchone()[0]==15
 for l in C['landmarks']:
  row=d.execute('SELECT * FROM Buildings WHERE Type=?',('BUILDING_JIN_'+l['key'],)).fetchone()
  assert row['Cost']==l['cost'] and row['CivilizationRequired']==CIV and row['NeverCapture']==1 and row['CapitalOnly']==1
  assert d.execute('SELECT MaxPlayerInstances FROM BuildingClasses WHERE Type=?',(row['BuildingClass'],)).fetchone()[0]==1
 for n in [20,40]:
  assert d.execute('SELECT MaxHitPointsChange FROM UnitPromotions WHERE Type=?',('PROMOTION_JIN_HORSE_'+str(n),)).fetchone()[0]==n
 # Atlas references, DDS decoding and localization/foreign-key targets.
 for row in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'JIN_%'"):
  path=V/'Art'/row['Filename'];im=Image.open(path);im.load();assert im.size==(int(row['IconSize'])*int(row['IconsPerRow']),int(row['IconSize'])*int(row['IconsPerColumn']))
 for table in ['Units','Buildings','UnitPromotions','Improvements','Civilizations','Leaders']:
  for row in d.execute('SELECT * FROM '+table+" WHERE Type LIKE '%JIN_%'"):
   if 'IconAtlas' in row.keys() and row['IconAtlas']:assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconsPerRow*IconsPerColumn>?',(row['IconAtlas'],row['PortraitIndex'])).fetchone()
 assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
 for path in (V/'Art').glob('*.dds'):
  with Image.open(path) as im:im.load()
 print('PASS Jin SQL: human-only, unchanged existing rows, CP Worker/Caravan inheritance, native effects, localization and',len(list((V/'Art').glob('*.dds'))),'decoded DDS textures')
 return d

def make_runtime(d,speed='GAMESPEED_STANDARD'):
 lua=LuaRuntime();g=lua.globals()
 g.GameInfo=lua.table();g.GameInfoTypes=lua.table()
 callable_table=lua.eval('''function(rows)
 local t={__rows=rows};for _,r in ipairs(rows)do if r.ID~=nil then t[r.ID]=r end;if r.Type then t[r.Type]=r end end
 return setmetatable(t,{__call=function(self,filter)
  local i=0;return function()while i<#rows do i=i+1;local row=rows[i];local ok=true
   if filter then for k,v in pairs(filter)do if row[k]~=v then ok=false end end end
   if ok then return row end end end end}) end''')
 for table in TABLES:
  rows=[lua.table_from({k:r[k] for k in r.keys() if r[k] is not None}) for r in d.execute('SELECT * FROM '+table)]
  g.GameInfo[table]=callable_table(lua.table_from(rows))
 for (table,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
  cols={r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')}
  if {'ID','Type'}<=cols:
   for r in d.execute('SELECT ID,Type FROM '+quote(table)):g.GameInfoTypes[r[1]]=r[0]
 g.Text=lua.table_from(dict(d.execute("SELECT Tag,Text FROM Language_en_US WHERE Tag LIKE 'TXT_KEY_JIN_%'")))
 g.speedID=d.execute('SELECT ID FROM GameSpeeds WHERE Type=?',(speed,)).fetchone()[0]
 def include(name):
  if name not in ['InstanceManager','IconSupport']:lua.execute((V/'Lua'/(name+'.lua')).read_text(encoding='utf-8'))
 def load():
  lua.execute('ContextPtr=NewContext()')
  include('JIN_Core')
 g.include=include;g.LoadJin=load
 g.LoadJinUI=lambda:lua.execute((V/'UI/JIN_Dynasty.lua').read_text(encoding='utf-8'))
 printed=[]
 g.print=lambda *args:printed.append(' '.join(map(str,args)))
 lua.execute((R/'tools/tests/jin_mock.lua').read_text(encoding='utf-8'));load()
 return lua,printed

def source_audit():
 ref=R/'tools/reference'
 unit=(ref/'CvUnit.cpp').read_text(encoding='utf-8-sig');combat=(ref/'CvUnitCombat.cpp').read_text(encoding='utf-8-sig')
 city=(ref/'CvCity.cpp').read_text(encoding='utf-8-sig');player=(ref/'CvPlayer.cpp').read_text(encoding='utf-8-sig')
 custom=(ref/'CustomMods.h').read_text(encoding='utf-8-sig')
 assert re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',custom)
 for kind,methods in {'Player':['GetScriptData','SetScriptData','SetHasPolicy','InitUnit'],'Unit':['GetScriptData','SetScriptData','GetMaxHitPoints','SetDamage','ChangeDamage','IsCanDefend','SetMoves','PushMission','RangeStrike','CanRangeStrikeAt','CanMoveOrAttackInto','IsBusy','IsOutOfAttacks','IsTrade'],'City':['GetNumRealBuilding','SetNumRealBuilding','IsCanPurchase','CanPlaceUnitHere','PushOrder','IsWorkingPlot'],'Plot':['SetResourceType','GetResourceType','SetImprovementType','GetPlotIndex']}.items():
  content=(ref/('CvLua'+kind+'.cpp')).read_text(encoding='utf-8-sig')
  for method in methods:assert re.search(r'Method\(\s*'+method+r'\s*\)',content),method
 assert 'visitor(unit.m_iMaxHitPointsChange)' in unit and 'visitor(unit.m_iWorkRateMod)' in unit
 assert 'changeMaxHitPointsChange(thisPromotion.GetMaxHitPointsChange() * iChange)' in unit
 assert 'int Modifiers = GetWorkRateMod();' in unit
 assert 'args->Push(attackerDamage);' in combat and 'int attackerDamage = kInfo.getDamageInflicted( BATTLE_UNIT_DEFENDER );' in combat
 post=player[player.index('void CvPlayer::doTurnPostDiplomacy('):];assert post.index('pLoopCity->doTurn();')<post.index('"PlayerDoTurn"')
 assert 'CanPlaceUnitHere(eUnitType)' in city and 'bTestTrainable, false /*bIgnoreCost*/, true /*bWillPurchase*/' in city
 binding=(ref/'CvLuaCity.cpp').read_text(encoding='utf-8-sig')
 assert 'const bool bForce\t\t= luaL_optint(L, 8, 0)' in binding
 assert 'getOwner(), eOldImprovement, eNewValue, IsImprovementPillaged()' in (ref/'CvPlot.cpp').read_text(encoding='utf-8-sig')
 trade=(ref/'CvTradeClasses.cpp').read_text(encoding='utf-8-sig')
 assert 'GetNumericModifier(POLICYMOD_TRADE_MODIFIER)' in trade
 speed=trade[trade.index('int CvPlayerTrade::GetTradeRouteSpeed('):];speed=speed[:speed.index('//\t---')]
 assert 'GetTradeUnit(eDomain, m_pPlayer)' in speed and 'pkUnitInfo->GetMoves()' in speed
 assert 'GetSpecificUnitType("UNITCLASS_CARAVAN")' in trade
 assert 'pTrade->ClearTradeRoute(iTradeConnectionIndex)' in trade and 'pkUnit->kill(false)' in trade
 assert 'GAMEEVENT_PlayerPlunderedTradeRoute, pUnit->getOwner(), pUnit->GetID(), iPlunderGoldValue, pOriginCity->getOwner()' in trade
 assert 'isUnitTypeFoodProduction' in city and 'GetFoodProductionTimes100' in city and 'GetHurryCostModifier()' in city
 missions=(ref/'CvUnitMission.cpp').read_text(encoding='utf-8-sig')
 assert '"CanStartMission"' in missions and 'hUnit->IsBusy()' in missions
 assert post.index('"PlayerDoTurn"')<post.index('doTurnUnits()')
 lua_unit=(ref/'CvLuaUnit.cpp').read_text(encoding='utf-8-sig')
 push=lua_unit[lua_unit.index('int CvLuaUnit::lPushMission('):lua_unit.index('int CvLuaUnit::lCanStartMission(')]
 assert all('luaL_optint(L, '+str(n) in push for n in [5,6,7,8])
 assert '#define HH_MOD_API_TRADEROUTE_MODIFIERS' not in (ref/'CustomModsGlobal.h').read_text(encoding='utf-8-sig')
 assert 'HH_MOD_API_TRADEROUTE_MODIFIERS' not in (ref/'CvGameCoreDLL_Expansion2.vcxproj').read_text(encoding='utf-8-sig')
 buildings=(ref/'CvBuildingClasses.cpp').read_text(encoding='utf-8-sig')
 sell=buildings[buildings.index('bool CvCityBuildings::IsBuildingSellable('):]
 assert 'CityBuildingsIsBuildingSellable' in sell and 'kBuilding.GetGoldMaintenance() <= 0' in sell
 report={'cp_commit':'44c1e14ff75d80c1dba5c8a71e8289439a53aafb','dll':151,'scope':'source/API contracts, not native execution','hardening_contracts':['PlayerDoTurn before doTurnUnits: deferred one-shot orders','CanStartMission test-all veto; numeric PushMission options','native ranged LOS/war validation','specific Caravan Moves feeds land route speed and duration','native trade plunder clears route without HP contest','Food surplus production and unit HurryCostModifier','trade launch/return kill representation; explicit plunder ABI'],'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in ref.glob('*.cpp')}}
 (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('PASS Jin pinned CP v151 API, serialized HP/work modifiers, actual combat damage ABI and post-economic PlayerDoTurn contracts')

def main():
 d=sql();source_audit();runs=[]
 parser=LuaRuntime().eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
 for p in V.rglob('*.lua'):parser(p.read_text(encoding='utf-8'),str(p))
 for p in V.rglob('*.xml'):ET.parse(p)
 for suite in SUITES:
  speeds=['GAMESPEED_QUICK','GAMESPEED_STANDARD','GAMESPEED_EPIC','GAMESPEED_MARATHON'] if suite in ['jin_economy.lua','jin_landmarks.lua'] else ['GAMESPEED_STANDARD']
  for speed in speeds:
   lua,printed=make_runtime(d,speed);start=time.perf_counter();lua.execute((R/'tools/tests'/suite).read_text(encoding='utf-8'))
   assert not [line for line in printed if line.startswith('JIN ') and not line.startswith('JIN invalid saved state')],printed
   for line in printed:print(line)
   runs.append({'suite':suite,'speed':speed,'milliseconds':round((time.perf_counter()-start)*1000,2)})
 for entry in ['JinDynasty/UI/JIN_Dynasty.xml']:assert sum(p==entry for p,_,_ in ENTRIES)==1
 ui=ET.parse(V/'UI/JIN_Dynasty.xml').getroot();panel=ui.find("Grid[@ID='Panel']")
 width,height=map(int,panel.get('Size').split(','))
 for viewport in [(1280,720),(1920,1080)]:assert width<=viewport[0] and height<=viewport[1]
 assert ui.find("Grid/ScrollPanel[@ID='Scroll']").get('Size')=='932,276'
 assert not imported(V/'UI/JIN_Dynasty.xml') and imported(V/'Lua/JIN_Core.lua')
 result={'date':'2026-10-30','mod_version':VERSION,'runtime':'Lupa Lua 5.1, actual installed-schema SQL, synthetic native calls','native_gameplay':'NOT RUN','native_rendering':'NOT RUN','native_save_files':'NOT RUN','runs':runs}
 (V/'docs/Validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('PASS Jin:',len(runs),'executable Lua scenarios; native Civ V acceptance remains pending')

if __name__=='__main__':main()
