"""Actual-schema SQL, pinned CP v151 API contracts and Lua 5.1 simulations."""
from pathlib import Path
import re
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from build_mod import R,files
from validate_red import table,TABLES

V=R/'McPvP'

def sql():
 d=database()
 for p in files():
  if p.suffix=='.sql':d.executescript(p.read_text(encoding='utf-8'))
 for t,typ in [('Civilizations','CIVILIZATION_MCPVP'),('Leaders','LEADER_MCPVP_OLD_GUARD'),('Units','UNIT_MCPVP_VETERAN'),('Buildings','BUILDING_MCPVP_HUB')]:assert d.execute('SELECT 1 FROM '+t+' WHERE Type=?',(typ,)).fetchone(),typ
 for t,old,new,allowed in [('Units','UNIT_SCOUT','UNIT_MCPVP_VETERAN',{'ID','Type','Combat','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'}),('Buildings','BUILDING_BARRACKS','BUILDING_MCPVP_HUB',{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'})]:
  a=d.execute('SELECT * FROM '+t+' WHERE Type=?',(old,)).fetchone();b=d.execute('SELECT * FROM '+t+' WHERE Type=?',(new,)).fetchone()
  for k in a.keys():
   if k not in allowed:assert a[k]==b[k],(t,k)
 for t,col,old,new in [('Unit_FreePromotions','UnitType','UNIT_SCOUT','UNIT_MCPVP_VETERAN'),('Unit_ClassUpgrades','UnitType','UNIT_SCOUT','UNIT_MCPVP_VETERAN'),('Building_UnitCombatFreeExperiences','BuildingType','BUILDING_BARRACKS','BUILDING_MCPVP_HUB')]:
  fields=[r[1] for r in d.execute('PRAGMA table_info('+t+')') if r[1] not in ['ID',col]]
  q='SELECT '+','.join(map(quote,fields))+' FROM '+t+' WHERE '+col+'=?'
  assert set(map(tuple,d.execute(q,(old,))))<=set(map(tuple,d.execute(q,(new,)))),t
 assert d.execute("SELECT Combat FROM Units WHERE Type='UNIT_MCPVP_VETERAN'").fetchone()[0]==6
 assert tuple(d.execute("SELECT OnlyDefensive,DefenseMod,LostWithUpgrade FROM UnitPromotions WHERE Type='PROMOTION_MCPVP_FLAG'").fetchone())==(1,-15,0)
 assert dict(d.execute("SELECT YieldType,Yield FROM Building_YieldModifiers WHERE BuildingType='BUILDING_MCPVP_SABOTAGE'"))=={'YIELD_PRODUCTION':-20,'YIELD_GOLD':-15}
 known={r[0] for r in d.execute('SELECT Tag FROM Language_en_US')}
 for p in V.rglob('*'):
  if p.suffix in ['.sql','.xml']:
   for key in re.findall(r'TXT_KEY_MCPVP_[A-Z0-9_]+',p.read_text(encoding='utf-8')):assert key in known or key+'1' in known,key
 for t in ['Civilizations','Leaders','Units','Buildings','UnitPromotions']:
  for row in d.execute('SELECT * FROM '+t+" WHERE Type GLOB '*MCPVP*'"):
   atlas=d.execute('SELECT IconsPerRow*IconsPerColumn FROM IconTextureAtlases WHERE Atlas=? LIMIT 1',(row['IconAtlas'],)).fetchone()
   assert atlas and row['PortraitIndex']<atlas[0],row['Type']
 assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
 print('PASS McPvP actual BNW/CP SQL, active inheritance, promotion fields, city modifiers and localization')
 return d

def source_audit():
 ref=R/'tools/reference'
 sources={p.stem:p.read_text(encoding='utf-8-sig') for p in ref.glob('*.cpp')}
 bindings={k:set(re.findall(r'Method\(\s*(\w+)\s*\)',sources['CvLua'+k])) for k in ['Unit','Player','City','Plot','Team','Game']}
 native=set.union(*bindings.values())
 ui={'SetUpdate','ClearUpdate','SetHide','SetText','SetDisabled','SetToolTipString','RegisterCallback','CalculateSize','ReprocessAnchoring','CalculateInternalSize','SetInputHandler','LookUpControl','IsHidden'}
 used=set()
 for p in V.rglob('*.lua'):
  for name in re.findall(r':([A-Z]\w+)\(',p.read_text(encoding='utf-8')):
   if name not in ui:assert name in native,('Unknown native method',name,p);used.add(name)
 for kind,names in {'Unit':['CanMoveOrAttackInto','CanMoveThrough','GeneratePath','LastMissionPlot','PopMission','MaxMoves','SetXY','ChangeDamage','ChangeExperience','SetMadeAttack','IsOutOfAttacks','GetGameTurnCreated','IsInvisible'],
                    'City':['GetGameTurnFounded','GetOriginalOwner','SetNumRealBuilding','Plot'],
                    'Player':['GetScriptData','SetScriptData','ChangeGoldenAgeProgressMeter','GetPlotDanger'],
                    'Team':['IsAllowsOpenBordersToTeam'],
                    'Plot':['GetWorkingCity','IsVisible','IsRevealed','GetArea','MovementCost','IsFighting']}.items():
  for name in names:assert name in bindings[kind],(kind,name)
 h=(ref/'CustomMods.h').read_text(encoding='utf-8-sig')
 for name,sig in {'UnitPrekill':'iiiiibi','UnitConverted':'iiiib','CityTrained':'iiibb','UnitCreated':'iiiii','TeamSetEra':'iib','CanDoCommand':'iiiiiiib','UnitCanHaveAnyUpgrade':'ii'}.items():assert re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+sig+'"',h),(name,sig)
 for name,file in [('CombatResult','CvUnitCombat'),('CombatEnded','CvUnitCombat'),('MustAbortAttack','CvUnitCombat'),('CityCaptureComplete','CvPlayer'),('UnitSetXY','CvUnit')]:assert '"'+name+'"' in sources[file],name
 assert 'getNumAttacksMadeThisTurn() >= getNumAttacks()' in sources['CvUnit']
 assert 'return IsCanAttackRanged() || (IsCombatUnit() && !isOnlyDefensive())' in sources['CvUnit']
 assert 'luaL_optint(L, 4, 0)' in sources['CvLuaUnit'] and 'pkUnit->changeDamage(iChange, ePlayer)' in sources['CvLuaUnit']
 combat=sources['CvUnitCombat']
 expected=['iAttackingPlayer','iAttackingUnit','attackerDamage','attackerFinalDamage','attackerMaxHP','iDefendingPlayer','iDefendingUnit','defenderDamage','defenderFinalDamage','defenderMaxHP','iInterceptingPlayer','iInterceptingUnit','interceptorDamage','plotX','plotY']
 # Check BOTH emissions, including the misleading native local variable names.
 for label in ['CombatResult','CombatEnded']:
  start=combat.index('// '+('CombatResult' if label=='CombatResult' else 'RED : CombatEnded'))
  section=combat[start:combat.index('"'+label+'"',start)]
  assert re.search(r'int attackerDamage\s*=\s*kInfo.getDamageInflicted\(\s*BATTLE_UNIT_DEFENDER\s*\)',section)
  assert re.search(r'int defenderDamage\s*=\s*kInfo.getDamageInflicted\(\s*BATTLE_UNIT_ATTACKER\s*\)',section)
  assert re.findall(r'args->Push\((\w+)\)',section)==expected,(label,'15-argument order')
 assert 'setFinalDamage(BATTLE_UNIT_DEFENDER, iAttackerDamageInflicted + pkDefender->getDamage())' in combat
 assert 'pkDefender->changeDamage(iAttackerDamageInflicted, pkAttacker->getOwner())' in combat
 unit=sources['CvLuaUnit'];path=unit[unit.index('int CvLuaUnit::lGeneratePath('):unit.index('int CvLuaUnit::lGetActivePath(')]
 for token in ['lua_createtable','MOVEFLAG_IGNORE_STACKING_SELF','iMaxTurns','"X"','"Y"','"RemainingMovement"','"Turn"','return 1;']:assert token in path,token
 assert 'pkUnit->canMoveInto(*pkPlot)' in unit[unit.index('int CvLuaUnit::lCanMoveThrough('):unit.index('int CvLuaUnit::lJumpToNearestValidPlot(')]
 assert 'int CvPlot::movementCost(const CvUnit* pUnit, const CvPlot* pFromPlot, int iMovesRemaining)' in sources['CvPlot']
 assert 'pkPlayer->GetPlotDanger(*pkPlot,false)' in sources['CvLuaPlayer']
 assert 'GetPlotDanger(*pCheck,false) < GetCurrHitPoints()' in sources['CvUnit'],'native danger proxy is comparable with remaining HP'
 print('PASS McPvP pinned CP v151: '+str(len(used))+' Lua methods, critical object bindings, event ABIs and ranged-carrier guard')

def runtime(d):
 data={t:[dict(r) for r in d.execute('SELECT * FROM '+t)] for t in TABLES}
 for test in ['mcpvp_matches.lua','mcpvp_kits.lua','mcpvp_persistence.lua','mcpvp_ai_ui.lua','mcpvp_viper.lua','mcpvp_navigation.lua','mcpvp_objectives.lua','mcpvp_feasts.lua']:
  lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().RED_DATABASE=table(lua,data)
  loaded=set()
  def include(name):
   if name in loaded:return
   loaded.add(name);paths=list(V.rglob(name+'.lua'));assert len(paths)==1,name
   lua.execute(paths[0].read_text(encoding='utf-8'))
  lua.globals().include=include
  lua.execute((R/'tools/tests/red_mock.lua').read_text(encoding='utf-8'))
  lua.execute((R/'tools/tests/mcpvp_mock.lua').read_text(encoding='utf-8'))
  include('MCP_Core')
  lua.globals().TEST.LoadPanel=lambda:lua.execute((V/'UI/MCP_ServerBrowser.lua').read_text(encoding='utf-8'))
  lua.execute((R/'tools/tests'/test).read_text(encoding='utf-8'))
 print('PASS McPvP Lua 5.1 simulations (engine double, not native gameplay)')

def validate():
 d=sql();source_audit()
 lua=LuaRuntime()
 for p in list(V.rglob('*.lua'))+list((R/'tools/tests').glob('mcpvp_*.lua')):lua.execute('assert(loadstring(...))',p.read_text(encoding='utf-8'))
 for p in V.rglob('*.xml'):ET.parse(p)
 ids={e.get('ID') for e in ET.parse(V/'UI/MCP_ServerBrowser.xml').iter() if e.get('ID')}
 refs=set(re.findall(r'Controls\.([A-Za-z_]+)',(V/'UI/MCP_ServerBrowser.lua').read_text(encoding='utf-8')));assert refs<=ids,refs-ids
 for row in d.execute("SELECT Filename FROM IconTextureAtlases WHERE Atlas LIKE 'MCPVP_%'"):
  with Image.open(V/'Art'/row[0]) as im:im.load();assert im.getbbox()
 runtime(d)
 print('PASS McPvP Lua syntax, XML, UI control references and 48 DDS assets; native Civ V testing pending')

if __name__=='__main__':validate()
