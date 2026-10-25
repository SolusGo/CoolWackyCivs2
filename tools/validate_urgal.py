"""Urgal: installed-schema SQL, shipped Lua 5.1 and pinned native source contracts.

These tests do not launch Civ V or establish native gameplay acceptance.
"""
from collections import Counter
import hashlib
import json
import re
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database, quote
from build_mod import files, R, ENTRIES, imported
from generate_urgal import V, CIV, LEADER, UNIT, BUILDING, EXCLUDED, TEXT

SUITES=['urgal_potions.lua','urgal_lifecycle.lua','urgal_ai.lua','urgal_ui.lua']

def apply(d):
 for path in sorted((V/'SQL').glob('*.sql')): d.executescript(path.read_text(encoding='utf-8'))

def inheritance(d):
 metadata={'ID','Type','Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'}
 count=0
 for table,old,new,prefix,col,overrides in [
  ('Units','UNIT_SWORDSMAN',UNIT,'Unit','UnitType',{'Combat':14,'Moves':2,'Cost':80}),
  ('Buildings','BUILDING_BARRACKS',BUILDING,'Building','BuildingType',{'Cost':75,'GoldMaintenance':1})]:
  a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
  b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
  for key in a.keys():
   if key not in metadata: assert b[key]==overrides.get(key,a[key]),(table,key,b[key],a[key])
  for (name,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
   cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(name)+')')]
   if not name.startswith(prefix) or col not in cols: continue
   fields=[c for c in cols if c not in [col,'ID']]
   query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(name)+' WHERE '+quote(col)+'=?'
   original=Counter(tuple(r) for r in d.execute(query,(old,)))
   actual=Counter(tuple(r) for r in d.execute(query,(new,)))
   if name=='Unit_ResourceQuantityRequirements': assert actual==Counter({r:n for r,n in original.items() if r[0]!='RESOURCE_IRON'})
   elif name=='Unit_FreePromotions': assert actual-original==Counter({('PROMOTION_URGAL_POT_CHASER',):1}) and not original-actual
   elif name=='Unit_ProductionModifierBuildings':
    # All eligible units, including the ordinary Swordsman, receive the local
    # Stand modifier after inheritance. Compare the remaining companion rows.
    assert actual[(BUILDING,10)]==1
    assert Counter({r:n for r,n in actual.items() if r[0]!=BUILDING})==Counter({r:n for r,n in original.items() if r[0]!=BUILDING})
   else: assert original==actual,(name,original-actual,actual-original)
   count+=1
 return count

def sql():
 d=database()
 for p in files():
  if p.suffix=='.sql' and V not in p.parents: d.executescript(p.read_text(encoding='utf-8'))
 before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall() if t!='CustomModOptions'}
 apply(d)
 for t,rows in before.items(): assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('modified unrelated row',t)
 assert d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[:]==(1,1)
 assert d.execute('SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? AND UnitClassType=?',(CIV,'UNITCLASS_SWORDSMAN')).fetchone()[0]==UNIT
 assert d.execute('SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=? AND BuildingClassType=?',(CIV,'BUILDINGCLASS_BARRACKS')).fetchone()[0]==BUILDING
 count=inheritance(d)
 assert list(d.execute('SELECT * FROM Building_DomainFreeExperiences WHERE BuildingType=?',(BUILDING,)))
 p=d.execute("SELECT * FROM UnitPromotions WHERE Type='PROMOTION_URGAL_STRENGTH_II'").fetchone()
 assert (p['AttackMod'],p['CityAttack'],p['DefenseMod'],p['CombatPercent'],p['RangedAttackModifier'],p['CannotBeChosen'],p['LostWithUpgrade'])==(50,-50,0,0,0,1,1)
 p=d.execute("SELECT * FROM UnitPromotions WHERE Type='PROMOTION_URGAL_POT_CHASER'").fetchone()
 assert p['LostWithUpgrade']==0 and p['HPHealedIfDestroyEnemy']==0
 p=d.execute("SELECT * FROM UnitPromotions WHERE Type='PROMOTION_URGAL_POT_RECOVERY'").fetchone()
 assert (p['HPHealedIfDestroyEnemy'],p['HealIfDestroyExcludesBarbarians'],p['CannotBeChosen'],p['LostWithUpgrade'])==(15,0,1,1)
 eligible={r['Type'] for r in d.execute('SELECT * FROM Units') if r['Domain']=='DOMAIN_LAND' and r['Combat']>0 and (r['RangedCombat'] or 0)==0 and r['CombatClass'] and r['CombatClass'] not in EXCLUDED}
 actual={r[0]:r[1] for r in d.execute('SELECT UnitType,ProductionModifier FROM Unit_ProductionModifierBuildings WHERE BuildingType=?',(BUILDING,))}
 assert set(actual)==eligible and set(actual.values())=={10}
 assert not list(d.execute("SELECT * FROM Building_UnitCombatProductionModifiers WHERE BuildingType=? AND UnitCombatType='UNITCOMBAT_ARCHER'",(BUILDING,)))
 for key,text in TEXT.items(): assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_URGAL_'+key,)).fetchone()[0]==text
 assert d.execute('SELECT Boldness,Meanness,Loyalty,WonderCompetitiveness FROM Leaders WHERE Type=?',(LEADER,)).fetchone()[:]==(9,8,4,3)
 assert dict(d.execute('SELECT FlavorType,Flavor FROM Leader_Flavors WHERE LeaderType=?',(LEADER,)))['FLAVOR_MILITARY_TRAINING']==10
 # Replacements inherit future scalar columns and companion content at activation.
 changed=database()
 changed.executescript("""ALTER TABLE Units ADD URGAL_Test INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD URGAL_Test INTEGER DEFAULT 0;
UPDATE Units SET URGAL_Test=41,Combat=99,Moves=7,Cost=123 WHERE Type='UNIT_SWORDSMAN';
UPDATE Buildings SET URGAL_Test=71,Cost=99,GoldMaintenance=4 WHERE Type='BUILDING_BARRACKS';
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_SWORDSMAN','PROMOTION_AMPHIBIOUS');
UPDATE Building_DomainFreeExperiences SET Experience=23 WHERE BuildingType='BUILDING_BARRACKS';
INSERT INTO Units(Type,Class,Domain,Combat,CombatClass,Cost,RangedCombat) VALUES ('UNIT_URGAL_TEST_MODDED','UNITCLASS_WARRIOR','DOMAIN_LAND',17,'UNITCOMBAT_CUSTOM_URGAL',90,0),('UNIT_URGAL_TEST_HYBRID','UNITCLASS_ARCHER','DOMAIN_LAND',17,'UNITCOMBAT_GUN',90,25);
""")
 apply(changed);inheritance(changed)
 assert changed.execute('SELECT URGAL_Test,Combat,Moves,Cost FROM Units WHERE Type=?',(UNIT,)).fetchone()[:]==(41,14,2,80)
 assert changed.execute('SELECT URGAL_Test FROM Buildings WHERE Type=?',(BUILDING,)).fetchone()[0]==71
 assert changed.execute("SELECT ProductionModifier FROM Unit_ProductionModifierBuildings WHERE UnitType='UNIT_URGAL_TEST_MODDED' AND BuildingType=?",(BUILDING,)).fetchone()[0]==10
 assert not changed.execute("SELECT 1 FROM Unit_ProductionModifierBuildings WHERE UnitType='UNIT_URGAL_TEST_HYBRID' AND BuildingType=?",(BUILDING,)).fetchone()
 assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
 print('PASS Urgal installed-schema SQL:',count,'companion tables, unrelated rows preserved, replacements, modifiers, production eligibility and localization')
 return {'companion_tables':count,'eligible_training_types':len(eligible)}

def runtime():
 for suite in SUITES:
  lua=LuaRuntime()
  def include(name): lua.execute((V/'Lua'/(name+'.lua')).read_text(encoding='utf-8'))
  lua.globals().include=include
  lua.globals().LoadUrgal=lambda:include('URGAL_Core')
  lua.globals().LoadUrgalUI=lambda:lua.execute((V/'UI/URGAL_Potions.lua').read_text(encoding='utf-8'))
  lua.execute((R/'tools/tests/urgal_mock.lua').read_text(encoding='utf-8'))
  lua.execute((R/'tools/tests'/suite).read_text(encoding='utf-8'))

def art_ui():
 root=ET.parse(V/'UI/URGAL_Potions.xml').getroot()
 controls={n.get('ID') for n in root.iter() if n.get('ID')}
 assert set(re.findall(r'Controls\.(\w+)',(V/'UI/URGAL_Potions.lua').read_text()))<=controls
 assert ('TheUrgal/UI/URGAL_Potions.xml') in {e[0] for e in ENTRIES}
 for p in V.rglob('*.xml'): ET.parse(p)
 images=list((V/'Art').glob('*.dds'));assert len(images)==48
 for p in images:
  with Image.open(p) as im: im.load();assert im.width>0 and im.height>0
 assert not imported(V/'UI/URGAL_Potions.xml') and imported(V/'Lua/URGAL_Core.lua')
 print('PASS 48 decoded DDS textures, XML, UI control bindings and entry/VFS flags')

def sources():
 from audit_cp import BASE,COMMIT
 names=['CustomMods.h','CvUnit.cpp','CvUnitCombat.cpp','CvUnitClasses.cpp','CvCity.cpp','CvTeam.cpp','CvPromotionClasses.cpp','CvLuaUnit.cpp']
 data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
 def body(file,signature):
  text=data[file];start=text.index(signature);return text[start:text.index('\n}',start)+2]
 attack=body('CvUnit.cpp','int CvUnit::GetMaxAttackStrength(')
 defense=body('CvUnit.cpp','int CvUnit::GetMaxDefenseStrength(')
 convert=body('CvUnit.cpp','void CvUnit::convert(')
 healing=body('CvUnitCombat.cpp','void CvUnitCombat::ApplyPostKillTraitEffects(')
 contracts={
  'native additive attack modifier':'iModifier += getAttackModifier();' in attack,
  'city modifier can cancel bonus':'if(pToPlot->isCity())' in attack and 'iModifier += cityAttackModifier();' in attack,
  'defense has no generic attack modifier':'getAttackModifier()' not in defense,
  'promotion SQL attack field read':'GetInt("AttackMod")' in data['CvPromotionClasses.cpp'],
  'promotion SQL healing field read':'GetInt("HPHealedIfDestroyEnemy")' in data['CvPromotionClasses.cpp'],
  'native healing clamps to missing health':'getHPHealedIfDefeatEnemy() > pkWinner->getDamage()' in healing and 'pkWinner->changeDamage(-pkWinner->getDamage())' in healing,
  'native healing accepts barbarians unless excluded':'IsHealIfDefeatExcludeBarbarians()' in healing,
  'conversion follows promotion copy and precedes source destruction':convert.index('setHasPromotion(ePromotion, bGivePromotion)')<convert.index('GAMEEVENT_UnitConverted')<convert.index('pUnit->kill(true, NO_PLAYER)'),
  'conversion hook ABI':bool(re.search(r'GAMEEVENT_UnitConverted\s+"UnitConverted",\s+"iiiib"',data['CustomMods.h'])),
  'creation hook ABI':bool(re.search(r'GAMEEVENT_UnitCreated\s+"UnitCreated",\s+"iiiii"',data['CustomMods.h'])),
  'era hook ABI':bool(re.search(r'GAMEEVENT_TeamSetEra\s+"TeamSetEra",\s+"iib"',data['CustomMods.h'])),
  'per-unit production table is read':'"Unit_ProductionModifierBuildings"' in data['CvUnitClasses.cpp'],
  'production checks building in training city':'GetCityBuildings()->GetNumBuilding(eBuilding) > 0' in data['CvCity.cpp'] and 'pkUnitInfo->GetBuildingProductionModifier(eBuilding)' in data['CvCity.cpp'],
  'script data binds to unit save':'visitor(unit.m_strScriptData)' in data['CvUnit.cpp'] and 'Method(GetScriptData)' in data['CvLuaUnit.cpp'],
 }
 for key,ok in contracts.items(): assert ok,key
 print('PASS',len(contracts),'pinned CP v151 source contracts (not in-game testing)')
 return {'official_commit':COMMIT,'contracts':contracts,'sources':{n:{'url':BASE+('Lua/' if n.startswith('CvLua') else '')+n,'sha256':hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest()} for n in names}}

def main():
 result={'date':'2026-10-26','native_gameplay':'NOT TESTED IN GAME','sql':sql()}
 runtime();art_ui();result['suites']=SUITES;result['source_audit']=sources()
 result['pending']=['Native leader/setup rendering and UI at 1024x768 and 1920x1080','Native melee/city/ranged previews and resolved combat','Native Pot Chaser kills and HP cap','Native mid-window saves, reload, upgrades and gifts','Native AI activation and whole-game balance']
 (V/'docs').mkdir(exist_ok=True)
 (V/'docs/Validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__': main()
