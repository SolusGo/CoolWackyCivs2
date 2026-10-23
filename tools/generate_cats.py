"""Generate The 11 Cats from the installed BNW + CP v151 schema."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions
from cats_data import CATS, CHAPTERS, FAMILY
from cats_presentation import TEXT as PRESENTATION_TEXT
R=Path(__file__).resolve().parents[1]; V=R/'The11Cats'; P='THE11CATS_'
CIV='CIVILIZATION_THE11CATS'; LEADER='LEADER_THE11CATS_AUSTIN'
UNIT='UNIT_THE11CATS_HOUSE_CAT'; TREE='BUILDING_THE11CATS_CAT_TREE'
DUMMIES=[c[0] for c in CATS[1:]]+['FIRST_PAIR','BONNIE_FAMILY','SISTERS_BED','MOTHER_DAUGHTER','TREE_FOOD']
TEXT={
 'CIV':'The 11 Cats','CIV5':'The 11 Cats','AUSTIN':'Austin — King of the House','SHORT':'The 11 Cats','ADJECTIVE':'Household','LEADER':'Austin','TRAIT':'King of the House',
 'TRAIT_HELP':'We Love the King Day lasts 25% longer. Throughout history, ten beloved Cats join Austin\'s household. Cats may Settle In to owned cities, providing +1 Culture and unique bonuses based on their personalities. Cities may accommodate up to three Resident Cats. Cats can always find their way home.',
 'CIV_PEDIA':'The 11 Cats are eleven real family cats, each with a distinct personality and a place in the same growing household. Austin, adopted in 2013, was first. Luna followed around 2014–2015. Bonnie was rescued as a stray and became mother to Appa, Loki, Kuro, Oscar and Boomie across two litters. Charlotte and her daughter Sisi found safety after unsuitable conditions. Max was once lost and was safely found again.[NEWLINE][NEWLINE]Some were born here. Some were found alone. Some needed a rescue. All eventually had somewhere they belonged. The Household panel tells their stories without turning suffering into a source of rewards.',
 'STRATEGY':'Develop four to six peaceful cities, build Cat Trees and plan each city\'s three resident slots. Culture and Diplomacy are natural victories, with Science a secondary path. Great People, happy homes and genuine WLTKD celebrations reward patient development. Rehoming takes time; the household offers almost no offensive military power.',
 'DAWN':'Austin, King of the House, your family began in 2013 with a place to belong. Across the ages, ten companions will join you: each with a voice, a history and a favorite place to rest.[NEWLINE][NEWLINE]Build warm homes, welcome those who need them and keep your family safe. May the day come when every place is filled: 11 / 11 — Everyone Is Home.',
 'UNIT':'House Cat','UNIT_HELP':'An untrainable, maintenance-free civilian companion. Move to an owned city and open The Household to Settle In (maximum three residents). Every resident provides +1 Culture and its personal bonus. Cannot attack, work, found cities, upgrade, be purchased, gifted or disbanded. Lost Cats recover and return.',
 'UNIT_PEDIA':'Ten named companions travel as House Cats; Austin is the leader, never an extra unit. The Household registry preserves each identity through travel, residence and recovery. A standard civilian map model represents the companion, with custom portrait and paw-and-crown flag.',
 'TREE':'Cat Tree','TREE_HELP':'Replaces Garden. +25% Great Person generation, +1 Culture. Requires no Fresh Water. With at least one Resident Cat: +1 Food, once per city.',
 'TREE_PEDIA':'A Cat Tree gives a household places to climb, watch, play and rest. It retains the Garden\'s technology, cost and other replacement rules, provides +25% Great Person generation and +1 Culture, and needs no Fresh Water. A resident makes it a lived-in home: +1 Food, whether one, two or three cats share the city.',
 'HOUSEHOLD':'The Household','HOUSEHOLD_PEDIA':'Austin is always the first member. Ancient: Luna; Classical: Bonnie; Medieval: Appa, Loki, Kuro; Renaissance: Oscar, Boomie; Industrial: Charlotte, Sisi; Modern: Max. Later-era starts immediately welcome every eligible earlier companion. The count includes all joined cats, including those travelling or recovering. At eleven, the milestone is 11 / 11 — Everyone Is Home. It grants no extra empire-wide yields.',
 'BONDS':'Family Bonds','BONDS_PEDIA':'The First Pair: Luna in the current capital gives +1 Culture. Bonnie\'s Family: Bonnie with any biological kitten (Appa, Loki, Kuro, Oscar or Boomie) gives +1 Food and +1 Gold, once. Sister\'s Bed: Appa, Loki and Oscar together give +1 Happiness and +10% Great Person generation. Mother and Daughter: Charlotte and Sisi together give +1 Happiness and +5% Growth. Bonds are local and independent; their effects end immediately when the combination ends.',
 'REHOME':'Rehome Cat','REHOME_PEDIA':'Choose a resident in The Household and click Rehome Cat. Its city effects end and its travelling unit appears safely in or adjacent to that home. The cat cannot Settle In again for ten Standard-speed turns (Quick 7, Epic 15, Marathon 30). Cooldowns belong to identities and survive loading and recovery. A blocked spawn leaves the resident in place until there is room.',
 'RECOVERY':'No Cat Left Behind','RECOVERY_PEDIA':'A cat displaced by city loss, destruction, capture or unit removal hides safely and returns after three Standard-speed turns (Quick 2, Epic 5, Marathon 9). If no safe city or plot exists, it remains pending. No yields are earned during recovery. Losing the capital, multiple simultaneous losses and elimination preserve identities without duplicating them. Return requires the human player to own a safe city.',
 'DUMMY':'Household resident effect','DUMMY_HELP':'Managed by The Household; cannot be built or purchased.',
 'LOYAL':'Always Finds Home','LOYAL_HELP':'Cannot be captured as an enemy reward. Embarks safely; lost companions recover through The Household.',
 'TITLE':'THE HOUSEHOLD','OPEN':'[ICON_CULTURE] The Household','CLOSE':'Close','HOMES':'Homes','CATS':'Cats','SETTLE':'Settle In','LOCATE':'Locate Cat','STORY':'Read Latest Chapter',
 'COUNT':'The Household — {1_Count} / 11','COMPLETE':'11 / 11 — Everyone Is Home.',
 'NOT_JOINED':'Not Yet Joined','TRAVELLING':'Travelling','RESIDENT':'Settled','RECOVERING':'Recovering','KING':'King of the House',
 'COOLDOWN':'Rehoming cooldown: {1_Turns} turns','RETURN':'Returns in {1_Turns} turns; waits safely if no home is available.',
 'JOINED':'{1_Name} has joined the household.','RETURNED':'{1_Name} has found the way home.',
 'FLED':'{1_Name} has fled the fighting and is hiding. They will return home soon.',
 'WAIT_HOME':'Waiting safely for a home with space to arrive.','CAPACITY':'{1_Count}/3 Cats','NO_BONDS':'No active Family Bonds.',
 'READY':'Ready to Settle In.','NEED_CITY':'Move this Cat into an owned, non-razing city with a free resident slot.',
 'FULL':'This home already has three Resident Cats.','WAIT_COOLDOWN':'Wait for the rehoming cooldown to end.',
 'INVALID':'This Cat or home is no longer eligible.','NO_SPAWN':'No safe arrival plot is available; the Cat stays at home.',
 'NO_TURN':'Return to normal gameplay during your active turn.','LOCKED':'This companion has not yet joined.','KING_HELP':'Austin is the leader; he never becomes a civilian unit.',
 'NARRATIVE':'Household story','BIO':'Biography','FAMILY':'Family and relationships','EFFECT':'Resident effects','STATUS':'Status',
 'BOND_FIRST_PAIR':'The First Pair: +1 Culture',
 'BOND_BONNIE_FAMILY':"Bonnie's Family: +1 Food, +1 Gold",
 'BOND_SISTERS_BED':"Sister's Bed: +1 Happiness, +10% Great Person generation",
 'BOND_MOTHER_DAUGHTER':'Mother and Daughter: +1 Happiness, +5% Growth',
 'AUSTIN_NAME':'Austin','AUSTIN_SUBTITLE':'King of the House','AUSTIN_LIVED':'Adopted in 2013','AUSTIN_TITLES_1':'King of the House','AUSTIN_HEADING_1':'The First Cat',
 'CIV5_HEADING_1':'Everyone Is Home',
 'GREETING_1':'Ah, a visitor! You may approach. His Majesty Austin welcomes those who come in peace. Have you brought suitable offerings?',
 'FRIENDLY_1':'The household is peaceful today. Come, sit with us. There is always room for another friend.',
 'NEUTRAL_1':'His Majesty is listening. A gentle voice, if you please.',
 'HOSTILE_1':'The household needs quiet. Please choose your next words with care.',
 'WAR_1':'You threaten my household? Then you leave me no choice. No harm shall come to my family.',
 'ATTACKED_1':'You bring fighting to our door? My family will be protected.',
 'DEFEAT_1':'The house grows quiet... but I hope the ones I love will always find somewhere warm to rest.',
 'DOF_1':'A fine friendship, don\'t you think? Even a king knows the value of good company.',
 'DOF_ACCEPT_1':'Yes. There is a warm place here for a trusted friend.',
 'DENOUNCE_1':'The household cannot trust such conduct. His Majesty must make this known.',
 'PEACE_1':'Let us have peace, warm places to rest and no more frightened families.',
 'PEACE_OFFER_1':'Enough. Let every household rest safely again.',
 'TRADE_1':'A generous offering. The King accepts, with a most appreciative purr.',
 'REFUSE_1':'His Majesty must decline. Perhaps another offering?',
}

def clone(*args,**kw): return base_clone(*args,**kw).replace('BCClone','THE11CATS_Clone')
def companions(*args,**kw): return base_companions(*args,**kw).replace('BCCompanion','THE11CATS_Companion')
def main():
 TEXT.update(PRESENTATION_TEXT)
 d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True); (V/'Lua').mkdir(exist_ok=True)
 core="""-- Audited against CP v151. Options expose hooks; all handlers are scoped.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CITY','EVENTS_CITY_CAPITAL','EVENTS_UNIT_CREATED','EVENTS_UNIT_PREKILL','EVENTS_UNIT_CAPTURE','EVENTS_COMMAND','EVENTS_UNIT_ACTIONS','EVENTS_UNIT_UPGRADES');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_THE11CATS_PURPLE',0.24,0.10,0.36,1),('COLOR_THE11CATS_GOLD',0.94,0.73,0.31,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_THE11CATS','COLOR_THE11CATS_PURPLE','COLOR_THE11CATS_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_THE11CATS_KING','TXT_KEY_THE11CATS_TRAIT_HELP','TXT_KEY_THE11CATS_TRAIT');
"""
 core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_THE11CATS_CIV',ShortDescription='TXT_KEY_THE11CATS_SHORT',Adjective='TXT_KEY_THE11CATS_ADJECTIVE',Civilopedia='TXT_KEY_THE11CATS_CIV_PEDIA',CivilopediaTag='TXT_KEY_THE11CATS_CIV5',Strategy='TXT_KEY_THE11CATS_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_THE11CATS',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_THE11CATS_DAWN',DawnOfManAudio='',DawnOfManImage='THE11CATS_Dawn.dds',MapImage='THE11CATS_Map.dds',PortraitIndex=0,IconAtlas='THE11CATS_CIV_ATLAS',AlphaIconAtlas='THE11CATS_ALPHA_ATLAS')
 core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_THE11CATS_LEADER',Civilopedia='TXT_KEY_THE11CATS_AUSTIN_BIO',CivilopediaTag='TXT_KEY_THE11CATS_AUSTIN',PackageID=None,PortraitIndex=0,IconAtlas='THE11CATS_LEADER_ATLAS',ArtDefineTag='THE11CATS_LeaderScene.xml',DoFWillingness=8,Loyalty=8,Meanness=2,Chattiness=8,Boldness=3,MinorCivCompetitiveness=7,WonderCompetitiveness=6)
 core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_THE11CATS_KING');\n"
 core+="INSERT INTO UnitClasses(Type,DefaultUnit,Description) VALUES ('UNITCLASS_THE11CATS_HOUSE_CAT',NULL,'TXT_KEY_THE11CATS_UNIT');\n"
 core+=clone('Units','UNIT_WORKER',UNIT,Class='UNITCLASS_THE11CATS_HOUSE_CAT',Capture=None,Combat=0,Cost=-1,FaithCost=-1,RequiresFaithPurchaseEnabled=0,HurryCostModifier=-1,AdvancedStartCost=-1,Moves=2,WorkRate=0,DefaultUnitAI=None,NoMaintenance=1,MilitarySupport=0,GoodyHutUpgradeUnitClass=None,Description='TXT_KEY_THE11CATS_UNIT',Civilopedia='TXT_KEY_THE11CATS_UNIT_PEDIA',Help='TXT_KEY_THE11CATS_UNIT_HELP',Strategy='TXT_KEY_THE11CATS_UNIT_HELP',IconAtlas='THE11CATS_OBJECT_ATLAS',PortraitIndex=1,UnitFlagAtlas='THE11CATS_FLAG_ATLAS',UnitFlagIconOffset=0)
 core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_THE11CATS_HOUSE_CAT','{UNIT}');\n"
 core+=clone('Buildings','BUILDING_GARDEN',TREE,FreshWater=0,GreatPeopleRateModifier=25,Description='TXT_KEY_THE11CATS_TREE',Civilopedia='TXT_KEY_THE11CATS_TREE_PEDIA',Help='TXT_KEY_THE11CATS_TREE_HELP',Strategy='TXT_KEY_THE11CATS_TREE_HELP',IconAtlas='THE11CATS_OBJECT_ATLAS',PortraitIndex=0)
 core+=f"INSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_GARDEN','{TREE}');\n"
 cities=['The Family Home',"Sister's Bed",'Sunny Windowsill','Warm Blanket','Purring Hearth','Quiet Corner','Golden Cushion','Garden Window','Treat Cupboard','Safe Haven','Royal Perch','Evening Sun']
 for i,name in enumerate(cities,1):
  TEXT[f'CITY_{i}']=name;core+=f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_THE11CATS_CITY_{i}');\n"
 for i,name in enumerate(['Soft Paw','Quiet Purr','Golden Whisker','Night Watch','Velvet Step','Warm Welcome','Window Watcher','Royal Messenger','Gentle Voice','Homeward'],1):
  TEXT[f'SPY_{i}']=name;core+=f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_THE11CATS_SPY_{i}');\n"
 inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON',LEADER,('Leader_Traits',))
 for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']: inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
 inherit+=companions(d,'Building_','BuildingType','BUILDING_GARDEN',TREE)
 effects=f"UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{TREE}' AND YieldType='YIELD_CULTURE';\nINSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{TREE}','YIELD_CULTURE',1 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{TREE}' AND YieldType='YIELD_CULTURE');\n"
 for suffix in DUMMIES:
  effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_THE11CATS_{suffix}','BUILDING_THE11CATS_{suffix}','TXT_KEY_THE11CATS_DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex) VALUES ('BUILDING_THE11CATS_{suffix}','BUILDINGCLASS_THE11CATS_{suffix}','TXT_KEY_THE11CATS_DUMMY','TXT_KEY_THE11CATS_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'THE11CATS_CIV_ATLAS',0);\n"
 yields={c[0]:{'CULTURE':1} for c in CATS[1:]}
 for cat,y in {'BONNIE':{'GOLD':1},'APPA':{'FOOD':1,'PRODUCTION':1},'LOKI':{'FOOD':1},'KURO':{'FOOD':1,'GOLD':1},'OSCAR':{'FOOD':2},'BOOMIE':{'CULTURE':2},'CHARLOTTE':{'PRODUCTION':1},'MAX':{'GOLD':1},'FIRST_PAIR':{'CULTURE':1},'BONNIE_FAMILY':{'FOOD':1,'GOLD':1},'TREE_FOOD':{'FOOD':1}}.items(): yields.setdefault(cat,{}).update(y)
 for cat,ys in yields.items():
  for y,n in ys.items(): effects+=f"INSERT INTO Building_YieldChanges VALUES ('BUILDING_THE11CATS_{cat}','YIELD_{y}',{n});\n"
 effects+="UPDATE Buildings SET GreatPeopleRateModifier=10 WHERE Type IN ('BUILDING_THE11CATS_LUNA','BUILDING_THE11CATS_SISTERS_BED');\n"
 effects+="UPDATE Buildings SET UnmoddedHappiness=1 WHERE Type IN ('BUILDING_THE11CATS_LOKI','BUILDING_THE11CATS_BOOMIE','BUILDING_THE11CATS_SISI','BUILDING_THE11CATS_MAX','BUILDING_THE11CATS_SISTERS_BED','BUILDING_THE11CATS_MOTHER_DAUGHTER');\n"
 effects+="UPDATE Buildings SET Defense=500 WHERE Type='BUILDING_THE11CATS_CHARLOTTE';\nINSERT INTO Building_YieldModifiers VALUES ('BUILDING_THE11CATS_BONNIE','YIELD_PRODUCTION',5);\n"
 # Native reversible local growth modifier, zero duration prevents automatic expiry.
 for name in ['SISI','MOTHER_DAUGHTER']:
  effects+=f"INSERT INTO CityEventChoices(Type,Description,Help,EventDuration,EventDurationScaling,Expires,GrowthMod,EventChoiceAudio) VALUES ('CITY_EVENT_CHOICE_THE11CATS_{name}','TXT_KEY_THE11CATS_DUMMY','TXT_KEY_THE11CATS_DUMMY_HELP',0,0,1,5,'');\n"
 effects+="INSERT INTO UnitPromotions(Type,Description,Help,AllowsEmbarkation,EmbarkedAllWater,CannotBeCaptured,NoCapture,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas) VALUES ('PROMOTION_THE11CATS_HOME','TXT_KEY_THE11CATS_LOYAL','TXT_KEY_THE11CATS_LOYAL_HELP',1,1,1,1,1,1,0,'THE11CATS_CIV_ATLAS');\n"
 effects+=f"INSERT INTO Unit_FreePromotions VALUES ('{UNIT}','PROMOTION_THE11CATS_HOME');\n"
 for cat in CATS[1:]:
  id=cat[0];effects+=f"INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas) VALUES ('PROMOTION_THE11CATS_{id}','TXT_KEY_THE11CATS_{id}_NAME','TXT_KEY_THE11CATS_{id}_BIO',1,1,{CATS.index(cat)},'THE11CATS_CATS_ATLAS');\n"
 for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('ATTACKED','ATTACKED'),('DEFEATED','DEFEAT'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('WORK_WITH_US','DOF'),('WORK_WITH_US_YES','DOF_ACCEPT'),('DENOUNCE','DENOUNCE'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),('TRADE_ACCEPT_GENEROUS','TRADE'),('TRADE_REJECT_UNACCEPTABLE','REFUSE')]:
  effects+=f"INSERT INTO Diplomacy_Responses VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_THE11CATS_{key}_%',1);\n"
 for flavor,n in [('CULTURE',8),('GROWTH',8),('GOLD',6),('SCIENCE',5),('WONDER',6),('DIPLOMACY',7),('EXPANSION',4),('DEFENSE',6),('OFFENSE',3)]:
  effects+=f"UPDATE Leader_Flavors SET Flavor={n} WHERE LeaderType='{LEADER}' AND FlavorType='FLAVOR_{flavor}';\n"
 effects+=f"UPDATE Leader_MajorCivApproachBiases SET Bias=8 WHERE LeaderType='{LEADER}' AND MajorCivApproachType='MAJOR_CIV_APPROACH_FRIENDLY';\nUPDATE Leader_MajorCivApproachBiases SET Bias=2 WHERE LeaderType='{LEADER}' AND MajorCivApproachType='MAJOR_CIV_APPROACH_WAR';\n"
 config=['-- Generated from tools/cats_data.py. No Austin unit is defined.','local H=MapModData.THE11CATS','H.Cats={}','H.Order={}']
 def lua(s): return '"'+s.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')+'"'
 for index,(id,name,gender,era,trait,effect,bio,family) in enumerate(CATS):
  for key,val in [('NAME',name),('GENDER',gender),('TRAIT',trait),('EFFECT',effect),('BIO',bio),('FAMILY',family)]:TEXT[id+'_'+key]=val
  mother,litter=FAMILY.get(id,('',0))
  config+=['H.Order[#H.Order+1]='+lua(id),'H.Cats.'+id+'={id='+lua(id)+',era='+str(era)+',portrait='+str(index)+',gender='+lua(gender)+',mother='+lua(mother)+',litter='+str(litter)+'}']
 for i,(title,story) in enumerate(CHAPTERS,1):TEXT[f'CHAPTER_{i}']=title;TEXT[f'STORY_{i}']=story
 TEXT['AUSTIN_TEXT_1']=TEXT['AUSTIN_BIO'];TEXT['CIV5_TEXT_1']=TEXT['CIV_PEDIA']
 for id in ['TRAIT','HOUSEHOLD','BONDS','REHOME','RECOVERY']+[c[0] for c in CATS]+[f'CHAPTER_{i}' for i in range(1,7)]:
  desc=id+'_NAME' if id in [c[0] for c in CATS] else id
  summary=id+'_BIO' if id in [c[0] for c in CATS] else 'STORY_'+id.split('_')[-1] if id.startswith('CHAPTER_') else 'TRAIT_HELP' if id=='TRAIT' else id+'_PEDIA'
  effects+=f"INSERT INTO Concepts(Type,Topic,Description,Summary,Advisor,CivilopediaHeaderType) VALUES ('CONCEPT_THE11CATS_{id}','TXT_KEY_THE11CATS_HOUSEHOLD','TXT_KEY_THE11CATS_{desc}','TXT_KEY_THE11CATS_{summary}','ECONOMIC','HEADER_CITIES');\n"
 art=''
 for atlas,stem,cols,rows in [('CIV','Icon',1,1),('ALPHA','Alpha',1,1),('LEADER','Portrait',1,1),('OBJECT','Objects',2,1),('CATS','Cats',4,3)]:
  for size in [16,24,32,45,48,64,80,128,256]:art+=f"INSERT INTO IconTextureAtlases VALUES ('THE11CATS_{atlas}_ATLAS',{size},'THE11CATS_{stem}{size}.dds',{cols},{rows});\n"
 art+="INSERT INTO IconTextureAtlases VALUES ('THE11CATS_FLAG_ATLAS',32,'THE11CATS_Flag32.dds',1,1);\n"
 text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_THE11CATS_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
 for name,content in [('00_Core',core),('01_Inheritance',inherit),('02_Effects',effects),('03_Art',art),('10_Text',text)]: (V/'SQL'/('THE11CATS_'+name+'.sql')).write_text(content,encoding='utf-8',newline='\n')
 (V/'Lua/THE11CATS_Config.lua').write_text('\n'.join(config)+'\n',encoding='utf-8',newline='\n')
 print('Generated The 11 Cats: identity, Garden inheritance, 15 dummies, exact growth choices, lore and atlases')
if __name__=='__main__':main()
