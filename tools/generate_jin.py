"""Compile Jin's shared balance data and active CP v151 inheritance to shipped files."""
import json
from pathlib import Path
from database import database
from generate_database import clone, companions

R=Path(__file__).resolve().parents[1]; V=R/'JinDynasty'
C=json.loads((V/'Balance.json').read_text())
CIV='CIVILIZATION_JIN_DYNASTY'; LEADER='LEADER_JIN_AGUDA'
def sqlv(v): return 'NULL' if v is None else str(v) if isinstance(v,(int,float)) else "'"+v.replace("'","''")+"'"
def insert(table,**kw): return 'INSERT INTO '+table+'('+','.join(kw)+') VALUES ('+','.join(map(sqlv,kw.values()))+');\n'
def cl(*a,**k): return clone(*a,**k).replace('BCClone','JINClone')
def cp(*a,**k): return companions(*a,**k).replace('BCCompanion','JINCompanion')
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,str):return json.dumps(v,ensure_ascii=True)
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
 return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'

def main():
 d=database(); text={}
 for folder in ['SQL','Lua','UI','Art','docs']: (V/folder).mkdir(parents=True,exist_ok=True)
 def tx(key,name,help=None):
  text[key]=name
  if help: text[key+'_HELP']=help
  return 'TXT_KEY_JIN_'+key
 core="""-- Notification hooks only; no global gameplay rebalance.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_PLAYER_TURN','EVENTS_CITY','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_PREKILL','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_ENDED','EVENTS_TILE_IMPROVEMENTS','EVENTS_UNIT_MOVETO');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_JIN_CRIMSON',0.38,0.025,0.06,1),('COLOR_JIN_GOLD',0.85,0.68,0.31,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_JIN','COLOR_JIN_GOLD','COLOR_JIN_CRIMSON','COLOR_PLAYER_WHITE_TEXT');
"""
 tx('CIV','The Jin Dynasty');tx('SHORT','Jin');tx('ADJECTIVE','Jurchen');tx('LEADER','Wanyan Aguda')
 tx('TRAIT','Jurchen Legacy','Train Mounted Villagers. Build one of two Landmarks each in Classical, Medieval and Renaissance; each grants one chosen Grassland. Stockpile up to 5 Horses per Grassland: each gives cavalry +2 melee/+1 ranged maximum HP, or spend one plus 65% Gold to recruit cavalry near a War Stable. Emissaries establish independent City-State Tributaries and bribe hostile troops into Barbarian rebellion. Manage Jin systems in the crimson-and-gold Dynasty panel.')
 tx('CIV_PEDIA','The Jurchen Jin Dynasty (1115–1234) arose in northeastern Asia. Wanyan Aguda united Jurchen communities against Liao rule and founded a new imperial state in 1115. The Jin conquered northern Song territory in the 1120s, developing institutions that combined Jurchen military households with Chinese civil administration. Its capitals included Huining, Zhongdu and later Kaifeng. Warfare against the Southern Song and the Mongols reshaped the dynasty until its fall in 1234. This civilization adapts the interdependent Jin economy and cavalry systems of Age of Empires IV: Yue Fei\'s Legacy; it is not a Chinese civilization variant.')
 tx('LEADER_PEDIA','Wanyan Aguda (1068–1123), posthumously Emperor Taizu of Jin, led the Wanyan clan in rebellion against the Liao and proclaimed the Jin dynasty in 1115. His cavalry campaigns secured the foundations of a northern empire. He died before the conquest of the Northern Song court. The leader portrait is an original artistic interpretation, not a surviving likeness.')
 tx('STRATEGY','Choose Grassland sites within two plots of cities with War Stables. Retained Horses protect the entire mounted army; spending them buys tempo at the cost of health. Mounted Villagers are fast but expensive. Escort Emissaries, cultivate City-State Tributaries and use Bribe to disrupt formations. Each Landmark pair permanently locks one path. Fortification defenders expire and must remain near their home.')
 tx('DAWN','Wanyan Aguda, the riders of the northeast await your command. Your people will build an empire from swift labor, fertile pasture and disciplined cavalry.[NEWLINE][NEWLINE]Choose the foundations of your dynasty. Let Horses gather in your Grasslands, bring independent settlements into tribute, and call the Meng\'an Mouke to defend the frontier. Will you spend your strength today, or preserve it for the battles still to come?')
 core+=insert('Traits',Type='TRAIT_JIN_LEGACY',Description='TXT_KEY_JIN_TRAIT_HELP',ShortDescription='TXT_KEY_JIN_TRAIT')
 core+=cl('Civilizations','CIVILIZATION_CHINA',CIV,Description='TXT_KEY_JIN_CIV',ShortDescription='TXT_KEY_JIN_SHORT',Adjective='TXT_KEY_JIN_ADJECTIVE',Civilopedia='TXT_KEY_JIN_CIV_PEDIA',CivilopediaTag='TXT_KEY_JIN_CIV5',Strategy='TXT_KEY_JIN_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_JIN',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_JIN_DAWN',DawnOfManAudio='',DawnOfManImage='JIN_Dawn.dds',MapImage='JIN_Map.dds',IconAtlas='JIN_CIV_ATLAS',AlphaIconAtlas='JIN_ALPHA_ATLAS',PortraitIndex=0)
 core+=cl('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_JIN_LEADER',Civilopedia='TXT_KEY_JIN_LEADER_PEDIA',CivilopediaTag='TXT_KEY_JIN_AGUDA',PackageID=None,PortraitIndex=0,IconAtlas='JIN_LEADER_ATLAS',ArtDefineTag='JIN_LeaderScene.xml')
 core+=insert('Civilization_Leaders',CivilizationType=CIV,LeaderheadType=LEADER)+insert('Leader_Traits',LeaderType=LEADER,TraitType='TRAIT_JIN_LEGACY')
 inherit='-- Activation-time clones preserve CP and third-party extension columns.\n'
 for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']: inherit+=cp(d,table,'CivilizationType','CIVILIZATION_CHINA',CIV)
 inherit+=cp(d,'Leader','LeaderType','LEADER_WASHINGTON',LEADER)
 for i,name in enumerate(['Huining','Zhongdu','Shangjing','Liaoyang','Ningjiang','Huanglong','Kaifeng','Dading','Dongjing','Datong','Taiyuan','Hejian','Yanjing','Jinan','Zhenzhou','Guangning','Longzhou','Xianping','Tongzhou','Suibin','Hesuguan','Zhaozhou','Changchun','Huligai'],1):
  core+=insert('Civilization_CityNames',CivilizationType=CIV,CityName=tx('CITY_'+str(i),name))
 for i,name in enumerate(['Wanyan Zonghan','Wanyan Xiyin','Wanyan Zongwang','Wanyan Lou Shi','Wanyan Yinshu','Sheng','Pucha','Hesheri','Tangkuo','Wulinda'],1): core+=insert('Civilization_SpyNames',CivilizationType=CIV,SpyName=tx('SPY_'+str(i),name))
 effects=''
 unit_help={
 'MOUNTED_VILLAGER':'110 Production; 3 Movement; 150% of the active Worker base work rate. All Worker builds/routes/repair. Noncombat; cap 20 plus 3 per active Tributary. Ordinary Workers remain available. Uses a borrowed mounted model.',
 'IRON_PAGODA':'Horseback Riding; 145 Production; 19 Strength; 3 Movement. +15% defense against melee combat classes. After attacking a unit, deals 15% of actual primary damage to at most 3 adjacent hostile combat units. Requires Horses. Upgrades through the mounted line.',
 'MOHE':'Horseback Riding; 75 Production; 8 melee/9 ranged Strength; Range 2; 5 Movement. May move after one attack. +15% against melee infantry. Benefits from ranged cavalry Horse HP.',
 'BED_CROSSBOW':'Mathematics and Machine Workshop; 100 Production; 9 melee/15 ranged; Range 2. A second bolt deals 35% of actual primary damage to the target (nonlethal). +25% against melee infantry; no inherited city siege bonus or setup. Upgrades to Trebuchet.',
 'ZHANMA':'Rifling; 300 Production; 42 Strength; 2 Movement. +75% against mounted and armored classes; vulnerable to ranged fire.',
 'ERUPTOR':'Chemistry; 260 Production; 18 melee/42 ranged; Range 1; 2 Movement. Short-range blast deals 10% of actual primary damage to up to 3 adjacent hostile combat units.',
 'GRENADIER':'Chemistry automatic emplacement defender. 24 melee/32 ranged; Range 2; 4 Movement. 20% bounded collateral, home leash and finite lifetime; cannot be trained or upgraded.',
 'DEFENDER':'Early automatic emplacement defender. 16 Strength; 4 Movement. Home leash, no city capture and finite lifetime; cannot be trained or upgraded.',
 'EMISSARY':'120 Production; 3 Movement; noncombat. Available after the second completed Landmark; cap 2. May enter neutral territory. Establish Tributary adjacent to an independent peaceful City-State capital, or Bribe nearby hostile military units. Dragon Pavilion halves production cost.',
 'REINDEER_TRADER':'90 Production; 2 Movement; retains the active Caravan trade behavior and route limits. With any active Tributary, one +15% native modifier applies to outgoing international income, including Gold and native non-Gold trade yields; never stacks per Tributary.',
 'NEST_OF_BEES':'Machinery; 170 Production; 12 melee/26 ranged; Range 2. Anti-unit field artillery using the built-in Catapult model. No Korean DLC dependency; no inherited city siege bonus.',
 'TRACTION_TREBUCHET':'Physics; 125 Production; 12 melee/14 ranged; Range 2. Conventional Trebuchet city siege behavior and upgrade path, with Jin identity.'}
 for u in C['units']:
  key=u['key']; typ='UNIT_JIN_'+key; cls='UNITCLASS_JIN_'+key
  cls0=d.execute('SELECT Class FROM Units WHERE Type=?',(u['base'],)).fetchone()[0]
  cls=cls0 if key=='REINDEER_TRADER' else cls
  if key!='REINDEER_TRADER': core+=insert('UnitClasses',Type=cls,Description=tx(key,u['name'],unit_help[key]),DefaultUnit=None)
  else:tx(key,u['name'],unit_help[key])
  core+=insert('Civilization_UnitClassOverrides',CivilizationType=CIV,UnitClassType=cls,UnitType=typ)
  kw=dict(Class=cls,Description='TXT_KEY_JIN_'+key,Help='TXT_KEY_JIN_'+key+'_HELP',Strategy='TXT_KEY_JIN_'+key+'_HELP',Civilopedia='TXT_KEY_JIN_'+key+'_HELP',Cost=u['cost'],Moves=u['moves'],PrereqTech=u['tech'],IconAtlas='JIN_UNIT_ATLAS',PortraitIndex=u['icon'],UnitFlagAtlas='JIN_FLAG_ATLAS',UnitFlagIconOffset=u['icon'],GoodyHutUpgradeUnitClass=None)
  for k,k0 in [('combat','Combat'),('ranged','RangedCombat'),('range','Range')]:
   if k in u:kw[k0]=u[k]
  if 'workPercent' in u and not u['workPercent']:kw['WorkRate']=0
  if key=='MOUNTED_VILLAGER':kw.update(UnitArtInfo='ART_DEF_UNIT_U_MONGOLIAN_KESHIK')
  if key=='EMISSARY':kw.update(RivalTerritory=1,Capture='UNITCLASS_WORKER',DefaultUnitAI='UNITAI_EXPLORE')
  if key in ['MOHE','GRENADIER','DEFENDER','IRON_PAGODA']:kw.update(IsMounted=1)
  if key in ['GRENADIER','DEFENDER']:kw.update(SendCanMoveIntoEvent=1,NoMinorCivGift=1)
  core+=cl('Units',u['base'],typ,**kw)
  inherit+=cp(d,'Unit','UnitType',u['base'],typ)
  if key=='MOUNTED_VILLAGER':effects+=f"UPDATE Units SET WorkRate=CAST((SELECT WorkRate FROM Units WHERE Type='UNIT_WORKER')*{u['workPercent']}/100 AS INTEGER) WHERE Type='{typ}';\n"
  if key=='EMISSARY':effects+="DELETE FROM Unit_Builds WHERE UnitType='UNIT_JIN_EMISSARY';\nDELETE FROM Unit_AITypes WHERE UnitType='UNIT_JIN_EMISSARY';\n"
  if key in ['BED_CROSSBOW','MOHE','ERUPTOR','GRENADIER','NEST_OF_BEES']:
   effects+=f"DELETE FROM Unit_FreePromotions WHERE UnitType='{typ}';\n"
  if key in ['GRENADIER','DEFENDER']:effects+=f"DELETE FROM Unit_ClassUpgrades WHERE UnitType='{typ}';\nDELETE FROM Unit_ResourceQuantityRequirements WHERE UnitType='{typ}';\n"
  if key=='BED_CROSSBOW':effects+=f"DELETE FROM Unit_ResourceQuantityRequirements WHERE UnitType='{typ}';\n"
 for building in C['buildings']:
  key,name,cost,tech,base,idx=[building[k] for k in ['key','name','cost','tech','base','icon']]
  typ='BUILDING_JIN_'+key; cls='BUILDINGCLASS_JIN_'+key
  help={'WAR_STABLE':'Recruit eligible cavalry instantly with 1 nearby Grassland Horse and 65% of normal Gold cost. Influence radius 2. Retains Stable companion effects.', 'MACHINE_WORKSHOP':'Enables Bed Crossbows in this city. Retains Barracks training experience.', 'MONASTERY':'Generates Faith and supports nearby Karma gathering after Mountain Hall. Mountain Hall halves its production cost.'}[key]
  core+=insert('BuildingClasses',Type=cls,DefaultBuilding=typ,Description=tx(key,name,help))
  core+=cl('Buildings',base,typ,BuildingClass=cls,Description='TXT_KEY_JIN_'+key,Help='TXT_KEY_JIN_'+key+'_HELP',Civilopedia='TXT_KEY_JIN_'+key+'_HELP',Strategy='TXT_KEY_JIN_'+key+'_HELP',Cost=cost,PrereqTech=tech,CivilizationRequired=CIV,IconAtlas='JIN_BUILDING_ATLAS',PortraitIndex=idx)
  inherit+=cp(d,'Building','BuildingType',base,typ)
  if key=='WAR_STABLE':
   for table in ['Building_LocalResourceOrs','Building_LocalResourceAnds']:effects+=f"DELETE FROM {table} WHERE BuildingType='{typ}';\n"
 landmark_help={
 'FLOWER_PAGODA':'Place one movable Flower Garden from the Dynasty panel: radius 2, +25% worker speed and +15% non-siege military strength. Relocation cooldown 5 Standard turns.',
 'GREAT_PASTURE':'Separate 5-Horse stockpile in this city, also acts as a War Stable. In addition, completion grants the normal chosen Grassland.',
 'DRAGON_PAVILION':'One free Emissary (deferred if capped/blocked); +100% Emissary Production in all Jin cities, equivalent to half cost. All current/future Jin cities gain Meng\'an Mouke defenses.',
 'MOUNTAIN_HALL':'Acts as a Monastery; +100% Monastery Production. Worked tiles and nearby workers generate Karma; deaths remove 25. At 1,000, reset and bless for 4 turns: +1 Farm Food, +4 Faith, +10 city healing and +25% city ranged attacks.',
 'GREAT_WALL_BASTION':'Capital gains 1,000 defense (10 displayed strength), +25% ranged strike, two defender slots and one automatic 20-HP Bed Crossbow shot per owner-turn.',
 'PAGODA_FOREST':'Generates one Pagoda Grove each 5 Standard turns, up to 15 empire-wide and 5 around each city. +1 Production on worked Groves; nearby hostile units lose 1 Movement once per turn.'}
 for l in C['landmarks']:
  key=l['key'];typ='BUILDING_JIN_'+key;cls='BUILDINGCLASS_JIN_'+key
  core+=insert('BuildingClasses',Type=cls,DefaultBuilding=typ,Description=tx(key,l['name'],landmark_help[key]),MaxPlayerInstances=1)
  fields=dict(Type=typ,BuildingClass=cls,Description='TXT_KEY_JIN_'+key,Help='TXT_KEY_JIN_'+key+'_HELP',Civilopedia='TXT_KEY_JIN_'+key+'_HELP',Strategy='TXT_KEY_JIN_'+key+'_HELP',Cost=l['cost'],PrereqTech=None,CivilizationRequired=CIV,CapitalOnly=1,NeverCapture=1,ConquestProb=0,NukeImmune=1,GoldMaintenance=0,HurryCostModifier=-1,IconAtlas='JIN_BUILDING_ATLAS',PortraitIndex=l['icon'])
  if key=='GREAT_WALL_BASTION':fields.update(Defense=C['bastionDefense'],RangedStrikeModifier=C['bastionStrike'])
  core+=insert('Buildings',**fields)
  if key=='MOUNTAIN_HALL':effects+=insert('Building_YieldChanges',BuildingType=typ,YieldType='YIELD_FAITH',Yield=C['hallFaith'])
 for key,name in [('GRASSLAND','Grassland'),('GARDEN','Flower Garden'),('GROVE','Pagoda Grove')]:
  core+=insert('Improvements',Type='IMPROVEMENT_JIN_'+key,Description=tx(key,name),Civilopedia='TXT_KEY_JIN_'+key,Help='TXT_KEY_JIN_'+key,ArtDefineTag={'GRASSLAND':'ART_DEF_IMPROVEMENT_PASTURE','GARDEN':'ART_DEF_IMPROVEMENT_LANDMARK','GROVE':'ART_DEF_IMPROVEMENT_TRADING_POST'}[key],SpecificCivRequired=1,CivilizationType=CIV,PillageGold=10,PortraitIndex={'GRASSLAND':9,'GARDEN':0,'GROVE':5}[key],IconAtlas='JIN_BUILDING_ATLAS')
 effects+=insert('Improvement_Yields',ImprovementType='IMPROVEMENT_JIN_GROVE',YieldType='YIELD_PRODUCTION',Yield=C['groveProduction'])
 def dummy(key,**kw):
  typ='BUILDING_JIN_'+key;cls='BUILDINGCLASS_JIN_'+key
  core0=insert('BuildingClasses',Type=cls,DefaultBuilding=typ,Description=tx(key,key.replace('_',' ').title()))
  core0+=insert('Buildings',Type=typ,BuildingClass=cls,Description='TXT_KEY_JIN_'+key,Cost=-1,FaithCost=-1,GreatWorkCount=-1,IsDummy=1,NeverCapture=1,ConquestProb=0,CivilizationRequired=CIV,IconAtlas='JIN_BUILDING_ATLAS',PortraitIndex=9,**kw)
  return core0
 core+=dummy('TRIBUTE');effects+=insert('Building_YieldChanges',BuildingType='BUILDING_JIN_TRIBUTE',YieldType='YIELD_FOOD',Yield=C['tributaryFood'])
 core+=dummy('BLESSING',HealRateChange=C['blessingHeal'],RangedStrikeModifier=C['blessingStrike'])
 effects+=insert('Building_ImprovementYieldChanges',BuildingType='BUILDING_JIN_BLESSING',ImprovementType='IMPROVEMENT_FARM',YieldType='YIELD_FOOD',Yield=C['blessingFarmFood'])
 effects+=insert('Building_YieldChanges',BuildingType='BUILDING_JIN_BLESSING',YieldType='YIELD_FAITH',Yield=C['blessingFaith'])
 # The old yield-specific table is compiled out behind undefined HH_MOD_API_TRADEROUTE_MODIFIERS.
 # The supported native scalar modifies outgoing international income without post-turn payouts.
 core+=insert('Policies',Type='POLICY_JIN_TRIBUTARY_TRADE',Description=tx('TRADE_POLICY','Tributary trade'),Help='TXT_KEY_JIN_TRADE_POLICY',IsDummy=1,TradeRouteYieldModifier=C['tradePercent'])
 for up in C['upgrades']:
  key=up['key'];core+=dummy('UP_'+key);tx('UP_'+key,up['name'],up['help'])
 effects+=insert('Building_ImprovementYieldChanges',BuildingType='BUILDING_JIN_UP_COLLECTIVE_HUNTING',ImprovementType='IMPROVEMENT_CAMP',YieldType='YIELD_FOOD',Yield=C['huntingFood'])
 # The discount is staged locally in every city, since this table uses local buildings.
 core+=dummy('PAVILION_DISCOUNT');effects+=insert('Unit_ProductionModifierBuildings',UnitType='UNIT_JIN_EMISSARY',BuildingType='BUILDING_JIN_PAVILION_DISCOUNT',ProductionModifier=C['emissaryDiscount'])
 # Native class production policy handles the empire-wide Monastery half-cost.
 core+=insert('Policies',Type='POLICY_JIN_MONASTERY',Description=tx('MONASTERY_POLICY','Mountain Hall monasteries'),IsDummy=1)
 effects+=insert('Policy_BuildingClassProductionModifiers',PolicyType='POLICY_JIN_MONASTERY',BuildingClassType='BUILDINGCLASS_JIN_MONASTERY',ProductionModifier=C['monasteryDiscount'])
 def promo(key,**kw):
  name=key.replace('_',' ').title();tx('PROMO_'+key,name)
  return insert('UnitPromotions',Type='PROMOTION_JIN_'+key,Description='TXT_KEY_JIN_PROMO_'+key,Help='TXT_KEY_JIN_PROMO_'+key,Sound='AS2D_IF_LEVELUP',CannotBeChosen=1,LostWithUpgrade=1,LostOnGifting=1,PortraitIndex=0,IconAtlas='JIN_CIV_ATLAS',PediaType='PEDIA_ATTRIBUTES',PediaEntry='TXT_KEY_JIN_PROMO_'+key,**kw)
 for n in range(1,C['horseCapacity']*4*max(C['meleeHP'],C['rangedHP'])+1):
  effects+=promo('HORSE_'+str(n),MaxHitPointsChange=n)
 for key,kw in [('GARDEN_WORK',dict(WorkRateMod=C['gardenWork'])),('GARDEN_COMBAT',dict(CombatPercent=C['gardenCombat'])),('MOHE',dict(CanMoveAfterAttacking=1)),('IRON_ARMOR',{}),('BED',{}),('ZHANMA',{}),('TEMPORARY',dict(NoCapture=1)),('QUILTED_ARMOR',dict(MaxHitPointsChange=C['quiltedHP'])),('PADDED_LAMELLAR',dict(MaxHitPointsChange=C['lamellarHP'])),('DRAFT_HORSES',dict(MovesChange=C['draftMovement'])),('DRAFT_WORK',dict(WorkRateMod=C['draftWork'])),('MOHE_ANCESTRY',dict(RangedAttackModifier=C['moheUpgradeAttack'])),('STORM_LANCES',dict(AttackMod=C['stormAttack'])),('TOWER_SHIELDS',dict(RangedDefenseMod=C['towerDefense'])),('PORCUPINE_DEFENSE',{}),('FLYING_FIRE',dict(RangedAttackModifier=C['flyingFireAttack'])),('PILI_PAO',dict(RangedAttackModifier=C['piliAttack']))]:effects+=promo(key,**kw)
 for key,classes,value,col in [('IRON_ARMOR',['UNITCOMBAT_MELEE','UNITCOMBAT_MOUNTED','UNITCOMBAT_GUN'],C['ironMeleeDefense'],'Defense'),('MOHE',['UNITCOMBAT_MELEE'],C['moheInfantryBonus'],'Modifier'),('BED',['UNITCOMBAT_MELEE','UNITCOMBAT_GUN'],C['bedInfantryBonus'],'Modifier'),('ZHANMA',['UNITCOMBAT_MOUNTED','UNITCOMBAT_ARMOR'],C['zhanmaMountedBonus'],'Modifier'),('PORCUPINE_DEFENSE',['UNITCOMBAT_MOUNTED','UNITCOMBAT_ARMOR'],C['porcupineBonus'],'Modifier')]:
  for cls in classes:
   effects+=insert('UnitPromotions_UnitCombatMods',PromotionType='PROMOTION_JIN_'+key,UnitCombatType=cls,**{col:value})
 for unit,pr in [('IRON_PAGODA','IRON_ARMOR'),('MOHE','MOHE'),('BED_CROSSBOW','BED'),('ZHANMA','ZHANMA'),('DEFENDER','TEMPORARY'),('GRENADIER','TEMPORARY')]:effects+=insert('Unit_FreePromotions',UnitType='UNIT_JIN_'+unit,PromotionType='PROMOTION_JIN_'+pr)
 for response,msg in [('FIRST_GREETING','The Jin welcome an envoy who speaks with purpose.'),('DECLAREWAR','The riders are ready. Your borders will not stop them.'),('ATTACKED','You have summoned the strength of the north.'),('DEFEATED','An empire falls. Its people endure.'),('PEACE_MADE_BY_HUMAN_GRACIOUS','Let the horses rest and the fields recover.'),('GREETING_POLITE_HELLO','May trade prosper between our peoples.'),('GREETING_NEUTRAL_HELLO','Speak. The court is listening.'),('GREETING_HOSTILE_HELLO','You have tested our patience.'),('TRADE_ACCEPT_GENEROUS','Our envoys accept this exchange.')]:
  tag=tx('DIPLO_'+response+'_1',msg);effects+=insert('Diplomacy_Responses',LeaderType=LEADER,ResponseType='RESPONSE_'+response,Response=tag[:-1]+'%',Bias=1)
 text.update(CIV5_HEADING_1='The Jurchen Empire',CIV5_TEXT_1=text['CIV_PEDIA'],AGUDA_NAME=text['LEADER'],AGUDA_SUBTITLE='Emperor Taizu of Jin',AGUDA_LIVED='1068–1123',AGUDA_TITLES_1='Founder of the Jin Dynasty',AGUDA_HEADING_1='Uniting the Jurchen',AGUDA_TEXT_1=text['LEADER_PEDIA'])
 art=''
 for family,stem,cols,rows in [('CIV','Icon',1,1),('ALPHA','Alpha',1,1),('LEADER','Portrait',1,1),('UNIT','Units',4,3),('BUILDING','Buildings',5,2),('FLAG','Flags',4,3)]:
  for size in [16,24,32,45,48,64,80,128,256]:art+=insert('IconTextureAtlases',Atlas='JIN_'+family+'_ATLAS',IconSize=size,Filename='JIN_'+stem+str(size)+'.dds',IconsPerRow=cols,IconsPerColumn=rows)
 for name,content in [('00_JIN_Core',core),('01_JIN_Inheritance',inherit),('02_JIN_Effects',effects),('03_JIN_Art',art),('10_JIN_Text',''.join(insert('Language_en_US',Tag='TXT_KEY_JIN_'+k,Text=v) for k,v in sorted(text.items())))]: (V/'SQL'/(name+'.sql')).write_text(content,encoding='utf-8',newline='\n')
 (V/'Lua/JIN_Config.lua').write_text('-- Generated by tools/generate_jin.py from JinDynasty/Balance.json.\nJINConfig='+lua(C)+'\n',encoding='utf-8',newline='\n')
 print('Generated Jin SQL, localization and shared Lua balance configuration')

if __name__=='__main__':main()
