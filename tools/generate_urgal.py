"""Compile Urgal against installed BNW/CP v151, preserving active replacement rows."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R/'TheUrgal'
CIV = 'CIVILIZATION_URGAL'
LEADER = 'LEADER_URGAL'
UNIT = 'UNIT_URGAL_RUSHER'
BUILDING = 'BUILDING_URGAL_BREWING_STAND'
# Keep the SQL training predicate and Lua eligibility predicate in agreement.
EXCLUDED = ('UNITCOMBAT_RECON', 'UNITCOMBAT_ARCHER', 'UNITCOMBAT_SIEGE', 'UNITCOMBAT_HELICOPTER')
CITIES = ['The Feast', 'Spawn Point', 'Ironwood', 'Potion Keep', 'Rush Valley',
          'Last Refill', 'Hotbar Heights', 'No Return', 'Oakfall', 'Stoneblade',
          'The Ravine', 'Purple Hollow', 'Chasewater', 'Brewer\'s Rest', 'Final Circle',
          'The Stronghold', 'North Watch', 'Swordhaven', 'Dawn Charge', 'Last Stand']
TEXT = {
 'CIV': 'The Urgal', 'SHORT': 'The Urgal', 'ADJECTIVE': 'Urgal', 'LEADER': 'Urgal',
 'TRAIT': 'Strength II',
 'TRAIT_HELP': 'Begin with 1 Strength Potion; gain 1 per new Era. Stockpile without a cap. Drink to give currently owned, eligible land melee units +50% attacking Combat Strength for 3/5/7/12 turns on Quick/Standard/Epic/Marathon. No defensive, city, ranged, naval or air bonus. New recruits are excluded. Potions cannot stack; 2 turns of Aftertaste block the next drink.',
 'STRATEGY': 'Prepare your army and roads before drinking. Use a scarce Strength Potion when the enemy cannot disengage, then attack during the short window. Brewing Stands help train eligible melee units. Rushers require no Iron and retain Pot Chaser on upgrade. Retreating enemies, mobile armies and cheap screens can waste your potion. The civilization receives no special economic or scientific boost.',
 'CIV_PEDIA': 'The Urgal takes its identity from the Strength potion kit of MCPVP Hardcore Games. Ordinary equipment could become terrifying for a brief encounter: drink, close the distance and press the advantage before it vanished. In this civilization that decision becomes an empire-wide military commitment. Potions arrive only with the passing of Eras. Every wasted charge is gone forever.[NEWLINE][NEWLINE]The Feast is the gathering point of an army that spends most of its time preparing. Brewing tables and barracks fill with equipment, roads are laid, and commanders search for the moment when retreat becomes impossible. The warning is simple: Urgal drank Strength. Run.',
 'LEADER_PEDIA': 'Urgal represents the aggressive Hardcore Games player who understands that preparation matters as much as the charge. He carries no permanent supernatural strength. His advantage is timing: a prepared force, a limited bottle and an opponent who has already committed. His veteran Rushers pursue the retreating enemy, recovering after successful kills while the potion lasts.',
 'DAWN': 'Urgal, the battlefield is quiet. Your people are gathering iron, sharpening blades and preparing the roads.[NEWLINE][NEWLINE]Your strength is not endless. Each Era brings a single bottle, and each bottle offers only a handful of turns in which the world must fear your army. Build your Brewing Stands. Train your Rushers. Wait until the enemy has nowhere left to run.[NEWLINE][NEWLINE]Then drink.',
 'UNIT': 'Urgal Rusher',
 'UNIT_HELP': 'Replaces Swordsman. 14 Combat Strength, 2 Movement, 80 Production and no Iron requirement. Pot Chaser: while affected by Strength II, killing an enemy unit heals 15 HP, up to maximum health. Pot Chaser survives upgrades.',
 'UNIT_STRATEGY': 'Train a reliable Classical army without Iron. Position these slightly more expensive Swordsmen before activating Strength II. Their permanent Pot Chaser promotion rewards kills during potion windows and remains useful after upgrading.',
 'UNIT_PEDIA': 'The Rusher embodies the classic sequence: drink, rush, kill, recover and keep rushing. The unit uses the ordinary Swordsman model and upgrade path. Its distinguishing advantage is the veteran who survives to carry Pot Chaser into later Eras.',
 'BUILDING': 'Brewing Stand',
 'BUILDING_HELP': 'Replaces Barracks. 75 Production, 1 maintenance and the active Barracks training XP (15 on the supported baseline). +10% Production toward eligible land melee units, including custom melee combat classes. Does not create Strength Potions.',
 'BUILDING_STRATEGY': 'Build Brewing Stands to prepare the army before committing a potion. They retain Barracks companion benefits and help train only eligible melee land units. They never generate potions.',
 'BUILDING_PEDIA': 'The Brewing Stand is a place of preparation. Bottles sit beside weapons, supplies are checked and the next charge is planned. Its military workshops train the army; the civilization\'s rare Strength Potions remain tied to Era progression.',
 'STRENGTH': 'Strength II',
 'STRENGTH_HELP': '+50% attacking Combat Strength against units during the current potion window. No defensive bonus. City attacks are unchanged. Applies only to the melee land units present when the potion was consumed.',
 'CHASER': 'Pot Chaser',
 'CHASER_HELP': 'While affected by Strength II, kills restore 15 HP up to maximum health. This veteran ability is retained on upgrade; it has no effect outside Strength II.',
 'RECOVERY': 'Pot Chaser - Strength II recovery',
 'RECOVERY_HELP': 'Killing an enemy unit heals 15 HP, up to maximum health. Temporary: requires Pot Chaser and active Strength II.',
 'INVENTORY': 'Strength Potions: {1_Num}', 'DRINK': 'DRINK STRENGTH II',
 'ACTIVE': 'STRENGTH II ACTIVE', 'ACTIVE_TURNS': 'Strength II - {1_Num} turns remaining',
 'AFTERTASTE': 'Aftertaste - {1_Num} turns remaining', 'EMPTY': 'NO POTIONS',
 'READY': 'Army ready', 'NO_ARMY': 'No eligible units', 'UNAVAILABLE': 'Potion state unavailable',
 'TOOLTIP': 'Potion of Strength II[NEWLINE]Consume 1 Strength Potion to empower eligible melee land units you currently own for {1_Num} turns. +50% attacking Combat Strength against units; no defensive or city bonus. Ranged, naval, air, reconnaissance, siege, helicopter and civilian units are excluded. Units created afterwards do not receive the effect. Cannot stack. After expiration, Aftertaste blocks drinking for 2 turns.[NEWLINE][NEWLINE]Current stockpile: {2_Num}.[NEWLINE]Eligible units now: {3_Num}.',
 'GAIN': 'A new Era grants {1_Num} Strength Potion(s). Stockpile: {2_Num}.',
 'DRANK': 'Strength II activated for {1_Num} turns on {2_Num} eligible units. Run.',
 'EXPIRED': 'Strength II has expired. Aftertaste prevents another potion for 2 turns.',
 'GREETING_1': 'Keep your distance. I have not decided whether this fight is worth a potion.',
 'WAR_1': 'You have nowhere left to run.', 'ATTACKED_1': 'You came all this way. Now stay.',
 'DEFEAT_1': 'Should have saved one more bottle.', 'PEACE_1': 'We will both need time to prepare.',
 'FRIENDLY_1': 'The stand is ready. For now, the bottles stay closed.',
 'NEUTRAL_1': 'What brings you to the Feast?', 'HOSTILE_1': 'You are standing too close.',
 'TRADE_1': 'A fair exchange. Keep moving.',
 'CIV5_HEADING_1': 'The Strength Kit', 'URGAL_NAME': 'Urgal',
 'URGAL_SUBTITLE': 'The Potion Rusher', 'URGAL_LIVED': 'The Hardcore Games',
 'URGAL_TITLES_1': 'Keeper of Strength II', 'URGAL_HEADING_1': 'The Moment to Drink',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], URGAL_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}': name for i,name in enumerate(['Refill','Hotbar','Tracker','Vial','Feast Runner','Iron Hand','Last Bottle','Rush Scout','Night Chase','The Brewer'],1)})

def clone(*a, **kw): return base_clone(*a, **kw).replace('BCClone','URGALClone')
def companions(*a, **kw): return base_companions(*a, **kw).replace('BCCompanion','URGALCompanion')

def main():
 d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True)
 core="""-- Only notifications are enabled globally; simulation handlers are scoped.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_PLAYER_TURN','EVENTS_NEW_ERA','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_URGAL_PURPLE',0.33,0.04,0.43,1),('COLOR_URGAL_PINK',0.98,0.50,0.91,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_URGAL','COLOR_URGAL_PINK','COLOR_URGAL_PURPLE','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_URGAL_STRENGTH_II','TXT_KEY_URGAL_TRAIT_HELP','TXT_KEY_URGAL_TRAIT');
"""
 core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_URGAL_CIV',ShortDescription='TXT_KEY_URGAL_SHORT',Adjective='TXT_KEY_URGAL_ADJECTIVE',Civilopedia='TXT_KEY_URGAL_CIV_PEDIA',CivilopediaTag='TXT_KEY_URGAL_CIV5',Strategy='TXT_KEY_URGAL_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_URGAL',Playable=1,AIPlayable=1,PackageID=None,DawnOfManQuote='TXT_KEY_URGAL_DAWN',DawnOfManAudio='',DawnOfManImage='URGAL_Dawn.dds',MapImage='URGAL_Map.dds',PortraitIndex=0,IconAtlas='URGAL_CIV_ATLAS',AlphaIconAtlas='URGAL_ALPHA_ATLAS')
 core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_URGAL_LEADER',Civilopedia='TXT_KEY_URGAL_LEADER_PEDIA',CivilopediaTag='TXT_KEY_URGAL_URGAL',PackageID=None,PortraitIndex=0,IconAtlas='URGAL_LEADER_ATLAS',ArtDefineTag='URGAL_LeaderScene.xml',VictoryCompetitiveness=9,WonderCompetitiveness=3,Boldness=9,DiploBalance=4,Loyalty=4,Meanness=8)
 core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_URGAL_STRENGTH_II');\n"
 core+=clone('Units','UNIT_SWORDSMAN',UNIT,Description='TXT_KEY_URGAL_UNIT',Civilopedia='TXT_KEY_URGAL_UNIT_PEDIA',Help='TXT_KEY_URGAL_UNIT_HELP',Strategy='TXT_KEY_URGAL_UNIT_STRATEGY',Combat=14,Moves=2,Cost=80,IconAtlas='URGAL_OBJECT_ATLAS',PortraitIndex=1)
 core+=clone('Buildings','BUILDING_BARRACKS',BUILDING,Description='TXT_KEY_URGAL_BUILDING',Civilopedia='TXT_KEY_URGAL_BUILDING_PEDIA',Help='TXT_KEY_URGAL_BUILDING_HELP',Strategy='TXT_KEY_URGAL_BUILDING_STRATEGY',Cost=75,GoldMaintenance=1,IconAtlas='URGAL_OBJECT_ATLAS',PortraitIndex=0)
 core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SWORDSMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_BARRACKS','{BUILDING}');\n"
 for table,count in [('City',len(CITIES)),('Spy',10)]:
  for i in range(1,count+1): core+=f"INSERT INTO Civilization_{table}Names VALUES ('{CIV}','TXT_KEY_URGAL_{table.upper()}_{i}');\n"
 inherit='-- Copy active scalar/companion rows at activation, including CP extension columns.\n'
 for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
  inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
 inherit+=companions(d,'Unit','UnitType','UNIT_SWORDSMAN',UNIT)
 inherit+=companions(d,'Building','BuildingType','BUILDING_BARRACKS',BUILDING)
 inherit+=companions(d,'Leader','LeaderType','LEADER_WASHINGTON',LEADER)
 excluded=','.join("'"+x+"'" for x in EXCLUDED)
 effects=f"""-- Native modifiers add. Cancel AttackMod against cities, leaving their strength unchanged.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,LostOnGifting,AttackMod,CityAttack,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_URGAL_STRENGTH_II','TXT_KEY_URGAL_STRENGTH','TXT_KEY_URGAL_STRENGTH_HELP','AS2D_IF_LEVELUP',1,1,1,50,-50,0,'URGAL_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_URGAL_STRENGTH');
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_URGAL_POT_CHASER','TXT_KEY_URGAL_CHASER','TXT_KEY_URGAL_CHASER_HELP','AS2D_IF_LEVELUP',1,0,1,'URGAL_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_URGAL_CHASER');
-- Native post-kill handling heals once, includes barbarians and clamps at max HP.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,LostOnGifting,HPHealedIfDestroyEnemy,HealIfDestroyExcludesBarbarians,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_URGAL_POT_RECOVERY','TXT_KEY_URGAL_RECOVERY','TXT_KEY_URGAL_RECOVERY_HELP','AS2D_IF_LEVELUP',1,1,1,15,0,1,'URGAL_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_URGAL_RECOVERY');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_URGAL_POT_CHASER');
DELETE FROM Unit_ResourceQuantityRequirements WHERE UnitType='{UNIT}' AND ResourceType='RESOURCE_IRON';
-- Per-unit native modifier: avoids speeding ranged units sharing a combat class.
INSERT INTO Unit_ProductionModifierBuildings(UnitType,BuildingType,ProductionModifier)
 SELECT Type,'{BUILDING}',10 FROM Units WHERE Domain='DOMAIN_LAND' AND Combat>0 AND COALESCE(RangedCombat,0)=0
 AND CombatClass IS NOT NULL AND CombatClass NOT IN ({excluded});
"""
 for flavor,value in {'OFFENSE':10,'DEFENSE':3,'CITY_DEFENSE':3,'MILITARY_TRAINING':10,'EXPANSION':6,'WONDER':3,'DIPLOMACY':4,'RECON':6,'MOBILE':9}.items():
  key='FLAVOR_'+flavor
  effects+=f"UPDATE Leader_Flavors SET Flavor={value} WHERE LeaderType='{LEADER}' AND FlavorType='{key}';\nINSERT INTO Leader_Flavors(LeaderType,FlavorType,Flavor) SELECT '{LEADER}','{key}',{value} WHERE EXISTS(SELECT 1 FROM Flavors WHERE Type='{key}') AND NOT EXISTS(SELECT 1 FROM Leader_Flavors WHERE LeaderType='{LEADER}' AND FlavorType='{key}');\n"
 for approach,bias in [('WAR',9),('HOSTILE',8),('DECEPTIVE',6),('GUARDED',4),('AFRAID',2),('FRIENDLY',4),('NEUTRAL',4)]:
  effects+=f"UPDATE Leader_MajorCivApproachBiases SET Bias={bias} WHERE LeaderType='{LEADER}' AND MajorCivApproachType='MAJOR_CIV_APPROACH_{approach}';\n"
 for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('ATTACKED','ATTACKED'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('TRADE_ACCEPT_GENEROUS','TRADE')]:
  effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_URGAL_{key}_%',1);\n"
 art=''
 for atlas,stem,columns in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2),('LEADER','Portrait',1),('PROMOTION','Promotions',2)]:
  for size in [16,24,32,45,48,64,80,128,256]: art+=f"INSERT INTO IconTextureAtlases VALUES ('URGAL_{atlas}_ATLAS',{size},'URGAL_{stem}{size}.dds',{columns},1);\n"
 text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_URGAL_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
 for name,content in [('00_URGAL_Core',core),('01_URGAL_Inheritance',inherit),('02_URGAL_Effects',effects),('03_URGAL_Art',art),('10_URGAL_Text',text)]:
  (V/'SQL'/(name+'.sql')).write_text(content,encoding='utf-8',newline='\n')
 print('Generated Urgal SQL: AI-playable, Swordsman/Barracks inheritance, native attack/healing and per-unit production')

if __name__=='__main__': main()
