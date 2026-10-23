"""Generate the Substitute Classroom against the installed BNW/CP v151 schema."""
from pathlib import Path
from database import database
from generate_database import clone, companions

R=Path(__file__).resolve().parents[1]
V=R/'TheSubstituteClassroom'
CIV='CIVILIZATION_GARVEY_CLASSROOM'
LEADER='LEADER_GARVEY'
UNIT='UNIT_GARVEY_HALL_MONITOR'
OFFICE='BUILDING_GARVEY_PRINCIPALS_OFFICE'

# CONFIGURATION: the generated GARVEY_Config table supplies BOTH SQL and Lua.
# No game-speed multiplier: these are player turns on every supported speed.
CONFIG=dict(RollInterval=12,BonusDuration=8,DetentionDuration=5,CorrectionThreshold=3,
    AaronCorrection=50,DeniseCorrection=50,JacquelineCorrection=50,BlakeCorrection=50,TimothyCorrection=0,
    AaronMilitaryProduction=15,DeniseCulture=15,JacquelineScience=15,BlakeCombat=15,
    TimothyYield=10,DetentionCombat=20,DetentionMilitaryProduction=20,
    DetentionUnhappiness=2,OfficeRelief=1,OfficeScience=10,OfficeCulture=2,OfficeProduction=2,
    HallFriendlyCombat=15,HallDetentionCombat=10,KillCulturePercent=25,KillCultureMinimum=1)
STUDENTS=[('Aaron','A-A-Ron','Aaron','+15% Production toward military units'),
 ('Denise','Dee-Nice','Denise','+15% Culture'),
 ('Jacqueline','Jay-Quell-In','Jacqueline','+15% Science'),
 ('Blake','Buh-Lah-Kay','Blake','+15% Combat Strength for military units'),
 ('Timothy','Timothy','Timothy','+10% Production, Gold, Science, Culture and Faith')]
CITIES=['Room 101','Detention Hall','The Faculty Lounge','Classroom 204','The Schoolyard',
 "The Principal's Wing",'Southside Academy','The Attendance Office','The Chalkboard','The Staffroom',
 'The Examination Hall','The Disciplinary Wing','The Lecture Theatre']
TEXT={
 'CIV':'The Substitute Classroom','SHORT':'Substitute Classroom','ADJECTIVE':'Substitute',
 'LEADER':'Mr. Garvey','TRAIT':'Insubordinate and Churlish',
 'TRAIT_HELP':'Conduct Roll Call every 12 player turns, first available 12 turns after founding your capital. Choose one of five students for an 8-turn bonus. Corrections build Insubordination: the third triggers 5 turns of DETENTION (+20% military strength and military Production, Culture from kills, -2 Global Happiness). Timothy never corrects you. Open ROLL CALL for choices and status.',
 'CIV_PEDIA':'A classroom is a small civilization: citizens, borders, taxes paid in homework, and the occasional rebellion over a seating plan. Under Mr. Garvey, the attendance sheet becomes a constitution and the corridor becomes a contested frontier. Room 101 tolerates many things. Correct pronunciation is not one of them.',
 'LEADER_PEDIA':'Mr. Garvey arrives with twenty years of teaching experience and absolutely no patience for what he considers elaborate student pranks. Aaron, Denise, Jacqueline and Blake discover that their names are now matters of state. Timothy alone understands the diplomatic value of a simple Present. Inspired by the Key & Peele Substitute Teacher sketches, this fictional civilization turns classroom discipline into empire management.',
 'STRATEGY':'Time Roll Call for your next eight turns. A-A-Ron supports army production; Dee-Nice accelerates policies; Jay-Quell-In drives research; Buh-Lah-Kay strengthens campaigns. Timothy offers a reliable broad economy. Three corrections trigger a short military surge, so preserve forces and build a Principal\'s Office before your patience runs out.',
 'DAWN':'Mr. Garvey, your class awaits. Beyond Room 101 stretch unruly kingdoms, suspicious seating arrangements, and a world that insists you are saying its name incorrectly. Take attendance, appoint your Hall Monitors, and send every rebellion to the Principal\'s Office. Can you build a civilization that will stand the test of time... without correcting you?',
 'UNIT':'Hall Monitor','UNIT_HELP':'Replaces Pikeman, retaining all normal CP properties. +15% Combat Strength in friendly territory. Military kills on friendly battle tiles grant Culture equal to 25% of defeated base strength (minimum 1). +10% additional strength during DETENTION. Unique training is lost on upgrade; civilization-wide temporary bonuses continue on eligible upgraded units.',
 'UNIT_STRATEGY':'Defend friendly territory with Hall Monitors. Their territorial strength and Culture rewards make intruders productive lessons. During Detention they gain an extra +10% strength in addition to the empire\'s +20%. Upgrade along the normal Pikeman path when their equipment becomes obsolete.',
 'UNIT_PEDIA':'A clipboard, an armband, and a terrifying willingness to report running in the corridor: the Hall Monitor is the mailed fist of classroom order. Uses the standard Pikeman model.',
 'OFFICE':"Principal's Office",'OFFICE_HELP':'Replaces Public School with all ordinary CP benefits. +2 Culture and +2 Production. During DETENTION: +10% Science in this city. Having at least one Office reduces the empire-wide Detention Happiness penalty from -2 to -1; additional Offices do not stack this relief.',
 'OFFICE_STRATEGY':'Build Offices for ordinary Public School research plus Culture and Production. The first Office softens Detention\'s global penalty. Every Office boosts its own Science during Detention. Captured Offices keep their ordinary benefits; special Detention effects require a human Substitute Classroom owner.',
 'OFFICE_PEDIA':'O-Shag-Hennessy\'s office is the final destination of every insubordinate student. The paperwork produces Culture, the filing cabinets produce Production, and nobody asks how the principal spells his name.',
 'DUMMY':'Classroom administration','DUMMY_HELP':'Automatically maintained Roll Call effect.',
 'HALL_PROMO':'Corridor Authority','HALL_PROMO_HELP':'+15% Combat Strength in friendly territory; friendly military kills grant Culture. Lost on upgrade.',
 'BLAKE_PROMO':'Buh-Lah-Kay','BLAKE_PROMO_HELP':'+15% Combat Strength during this Roll Call bonus.',
 'DETENTION_PROMO':'DETENTION!','DETENTION_PROMO_HELP':'+20% Combat Strength during Detention.',
 'HALL_DETENTION_PROMO':'No Hall Pass','HALL_DETENTION_PROMO_HELP':'+10% additional strength for Hall Monitors during Detention.',
 'PENALTY':'Detention discipline','PENALTY_HELP':'Temporary Global Happiness penalty during Detention.',
 'OPEN':'ROLL CALL','CLOSE':'Close','TITLE':'ROOM 101 - ATTENDANCE SHEET',
 'AVAILABLE':'Roll Call available - choose a student.','WAIT':'Next Roll Call in {1_Num} turns.',
 'CURRENT':'Student: {1_Name} - {2_Num} turns remaining','NONE':'No student bonus active.',
 'PATIENCE':'Patience: {1_Num}/3 - {2_Status}',
 'CALM':'Calm','IRRITATED':'Irritated','FURIOUS':'Furious',
 'DETENTION_STATUS':'[COLOR_NEGATIVE_TEXT]3/3 - DETENTION TRIGGERED! {1_Num} turns left[ENDCOLOR]',
 'DETENTION_DETAIL':'Insubordination reset to 0. +20% strength, +20% military Production, Culture from kills. Happiness: -{1_Num}.',
 'NO_DETENTION':'Detention inactive.',
 'SELECT':'Call on student','RULES':'Bonuses last 8 player turns; Roll Call cooldown starts on selection. Corrections resolve once. Kill Culture: 25% of base strength, rounded, minimum 1 per effect.',
 'READY_NOTICE':'The class is assembled. Open ROLL CALL when you are ready.',
 'ACCEPTED':'{1_Name}: Present. Mr. Garvey accepts the answer. Bonus active for {2_Num} turns.',
 'DETENTION_START':"THAT'S IT! EVERYBODY GETS DETENTION! I WILL SEND YOU TO O-SHAG-HENNESSY'S OFFICE!",
 'DETENTION_END':"Maybe tomorrow you'll learn how to behave.",
 'BONUS_END':'Class dismissed. The Roll Call bonus has ended.',
 'KILL':'CLASS DISMISSED. +{1_Num} [ICON_CULTURE] Culture.',
 'DISABLED':'Classroom state could not be read. Check Lua.log before continuing.',
 'WAR':'OH, SO YOU WANNA GO TO WAR?!',
 'PEACE':'I EXPECT BETTER BEHAVIOUR FROM NOW ON.',
 'GREETING_1':'I am Mr. Garvey. I taught for twenty years in the inner city. You will address me correctly.',
 'DECLARE_1':'YOU HAVE BEEN INSUBORDINATE AND CHURLISH FOR THE LAST TIME!',
 'DEFEAT_1':'Class dismissed. But I am writing every one of you up.',
 'PEACE_1':'I EXPECT BETTER BEHAVIOUR FROM NOW ON.',
 'HOSTILE_1':'YOU DONE MESSED UP!',
 'FRIENDLY_1':'Present and on time. We might get along.',
 'NEUTRAL_1':'Is everybody here? No games today.',
 'ATTACKED_1':'OH, SO YOU WANNA GO TO WAR?!',
 'TRADE_1':'That is an acceptable hall pass.',
}
QUOTES=[('A-A-RON!',"It's pronounced Aaron, sir.",'YOU DONE MESSED UP, A-A-RON!'),
 ('DEE-NICE!','Denise.','DO YOU WANNA GO TO WAR, DEE-NICE?!'),
 ('JAY-QUELL-IN!','Jacqueline.','INSUBORDINATE AND CHURLISH!'),
 ('BUH-LAH-KAY!','Blake.','YOU WANNA GO TO WAR, BUH-LAH-KAY?!')]
for i,(key,name,actual,effect) in enumerate(STUDENTS,1):
 TEXT[f'STUDENT_{i}']=name
 TEXT[f'ROW_{i}']=f'{name} ({actual})[NEWLINE]{effect}. '+('No corrections.' if i==5 else '50% chance of a correction.')
 if i<5:
  a,b,c=QUOTES[i-1];TEXT[f'CORRECTION_{i}']=f'Mr. Garvey: "{a}"[NEWLINE]Student: "{b}"[NEWLINE]Mr. Garvey: "{c}"'
TEXT['CORRECTION_5']='Mr. Garvey: "Timothy?"[NEWLINE]Student: "Present."[NEWLINE]Mr. Garvey: "Thank you."'
for i,name in enumerate(CITIES,1):TEXT[f'CITY_{i}']=name
for i in range(1,11):TEXT[f'SPY_{i}']=f'Attendance Inspector {i}'
TEXT.update(CIV5='The Substitute Classroom',CIV5_HEADING_1='The Substitute Classroom',
 CIV5_TEXT_1=TEXT['CIV_PEDIA'],LEADER_HEADING_1='Mr. Garvey',LEADER_TEXT_1=TEXT['LEADER_PEDIA'])

def main():
 d=database();(V/'SQL').mkdir(parents=True,exist_ok=True)
 core='''-- CONFIGURATION (fixed player-turn cadence on Quick/Standard/Epic/Marathon).
CREATE TABLE GARVEY_Config(Name TEXT PRIMARY KEY,Value INTEGER NOT NULL);
'''
 for key,value in CONFIG.items():core+=f"INSERT INTO GARVEY_Config VALUES ('{key}',{value});\n"
 core+='''-- Enable only CP hooks used by this module; no vanilla gameplay rows change.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_CITY_FOUNDING','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_PREKILL',
 'EVENTS_UNIT_UPGRADES','EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_GARVEY_GREEN',0.04,0.20,0.15,1),('COLOR_GARVEY_CHALK',0.96,0.92,0.77,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_GARVEY','COLOR_GARVEY_GREEN','COLOR_GARVEY_CHALK','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_GARVEY_ROLL_CALL','TXT_KEY_GARVEY_TRAIT_HELP','TXT_KEY_GARVEY_TRAIT');
'''
 core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_GARVEY_CIV',ShortDescription='TXT_KEY_GARVEY_SHORT',Adjective='TXT_KEY_GARVEY_ADJECTIVE',Civilopedia='TXT_KEY_GARVEY_CIV_PEDIA',CivilopediaTag='TXT_KEY_GARVEY_CIV5',Strategy='TXT_KEY_GARVEY_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_GARVEY',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_GARVEY_DAWN',DawnOfManAudio='',DawnOfManImage='GARVEY_Dawn.dds',MapImage='GARVEY_Map.dds',PortraitIndex=0,IconAtlas='GARVEY_CIV_ATLAS',AlphaIconAtlas='GARVEY_ALPHA_ATLAS')
 core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_GARVEY_LEADER',Civilopedia='TXT_KEY_GARVEY_LEADER_PEDIA',CivilopediaTag='TXT_KEY_GARVEY_LEADER',PackageID=None,PortraitIndex=0,IconAtlas='GARVEY_LEADER_ATLAS',ArtDefineTag='GARVEY_LeaderScene.xml',Boldness=10,Meanness=8,Chattiness=9,DoFWillingness=3)
 core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_GARVEY_ROLL_CALL');\n"
 core+=clone('Units','UNIT_PIKEMAN',UNIT,Description='TXT_KEY_GARVEY_UNIT',Civilopedia='TXT_KEY_GARVEY_UNIT_PEDIA',Help='TXT_KEY_GARVEY_UNIT_HELP',Strategy='TXT_KEY_GARVEY_UNIT_STRATEGY',IconAtlas='GARVEY_OBJECT_ATLAS',PortraitIndex=1,UnitFlagAtlas='GARVEY_FLAG_ATLAS',UnitFlagIconOffset=0)
 core+=clone('Buildings','BUILDING_PUBLIC_SCHOOL',OFFICE,Description='TXT_KEY_GARVEY_OFFICE',Civilopedia='TXT_KEY_GARVEY_OFFICE_PEDIA',Help='TXT_KEY_GARVEY_OFFICE_HELP',Strategy='TXT_KEY_GARVEY_OFFICE_STRATEGY',IconAtlas='GARVEY_OBJECT_ATLAS',PortraitIndex=0)
 core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_PIKEMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_PUBLIC_SCHOOL','{OFFICE}');\n"
 for i in range(1,len(CITIES)+1):core+=f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_GARVEY_CITY_{i}');\n"
 for i in range(1,11):core+=f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_GARVEY_SPY_{i}');\n"
 inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON',LEADER,('Leader_Traits',))
 for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
 inherit+=companions(d,'Unit_','UnitType','UNIT_PIKEMAN',UNIT)
 inherit+=companions(d,'Building_','BuildingType','BUILDING_PUBLIC_SCHOOL',OFFICE)
 effects=''
 def val(key):return f"(SELECT Value FROM GARVEY_Config WHERE Name='{key}')"
 for suffix,column,key in [('HALL','FriendlyLandsModifier','HallFriendlyCombat'),('BLAKE','CombatPercent','BlakeCombat'),('DETENTION','CombatPercent','DetentionCombat'),('HALL_DETENTION','CombatPercent','HallDetentionCombat')]:
  effects+=f"INSERT INTO UnitPromotions(Type,Description,Help,{column},CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('PROMOTION_GARVEY_{suffix}','TXT_KEY_GARVEY_{suffix}_PROMO','TXT_KEY_GARVEY_{suffix}_PROMO_HELP',{val(key)},1,1,1,'GARVEY_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_GARVEY_{suffix}_PROMO');\n"
 effects+=f"INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_GARVEY_HALL');\n"
 for y,key in [('CULTURE','OfficeCulture'),('PRODUCTION','OfficeProduction')]:
  effects+=f"UPDATE Building_YieldChanges SET Yield=Yield+{val(key)} WHERE BuildingType='{OFFICE}' AND YieldType='YIELD_{y}';\nINSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{OFFICE}','YIELD_{y}',{val(key)} WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{OFFICE}' AND YieldType='YIELD_{y}');\n"
 for suffix in ['AARON','DENISE','JACQUELINE','TIMOTHY','DETENTION','OFFICE_SCIENCE']:
  effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_GARVEY_{suffix}','BUILDING_GARVEY_{suffix}','TXT_KEY_GARVEY_DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex) VALUES ('BUILDING_GARVEY_{suffix}','BUILDINGCLASS_GARVEY_{suffix}','TXT_KEY_GARVEY_DUMMY','TXT_KEY_GARVEY_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'GARVEY_CIV_ATLAS',0);\n"
 for suffix,key in [('AARON','AaronMilitaryProduction'),('DETENTION','DetentionMilitaryProduction')]:effects+=f"UPDATE Buildings SET MilitaryProductionModifier={val(key)} WHERE Type='BUILDING_GARVEY_{suffix}';\n"
 # CultureRateModifier applies to the city's native culture pipeline.
 effects+=f"UPDATE Buildings SET CultureRateModifier={val('DeniseCulture')} WHERE Type='BUILDING_GARVEY_DENISE';\nUPDATE Buildings SET CultureRateModifier={val('TimothyYield')} WHERE Type='BUILDING_GARVEY_TIMOTHY';\n"
 for suffix,y,key in [('JACQUELINE','SCIENCE','JacquelineScience'),('OFFICE_SCIENCE','SCIENCE','OfficeScience')]+[('TIMOTHY',y,'TimothyYield') for y in ['PRODUCTION','GOLD','SCIENCE','FAITH']]:effects+=f"INSERT INTO Building_YieldModifiers(BuildingType,YieldType,Yield) VALUES ('BUILDING_GARVEY_{suffix}','YIELD_{y}',{val(key)});\n"
 # Branchless free policies express an uncapped global penalty, once per empire.
 for suffix,amount in [('FULL',f"-{val('DetentionUnhappiness')}"),('RELIEF',f"-{val('DetentionUnhappiness')}+{val('OfficeRelief')}")]:effects+=f"INSERT INTO Policies(Type,Description,Help,ExtraHappiness,IsDummy,PortraitIndex,IconAtlas) VALUES ('POLICY_GARVEY_PENALTY_{suffix}','TXT_KEY_GARVEY_PENALTY','TXT_KEY_GARVEY_PENALTY_HELP',{amount},1,0,'GARVEY_CIV_ATLAS');\n"
 for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','DECLARE'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('ATTACKED','ATTACKED'),('TRADE_ACCEPT_GENEROUS','TRADE')]:effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_GARVEY_{key}_%',1);\n"
 art=''
 for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2),('LEADER','Portrait',1)]:
  for size in [16,24,32,45,48,64,80,128,256]:art+=f"INSERT INTO IconTextureAtlases VALUES ('GARVEY_{atlas}_ATLAS',{size},'GARVEY_{stem}{size}.dds',{cols},1);\n"
 art+="INSERT INTO IconTextureAtlases VALUES ('GARVEY_FLAG_ATLAS',32,'GARVEY_Flag32.dds',1,1);\n"
 text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_GARVEY_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
 for name,content in [('00_GARVEY_Core',core),('01_GARVEY_Inheritance',inherit),('02_GARVEY_Effects',effects),('03_GARVEY_Art',art),('10_GARVEY_Text',text)]:
  (V/'SQL'/f'{name}.sql').write_text(content.replace('BCClone','GARVEYClone').replace('BCCompanion','GARVEYCompanion'),encoding='utf-8',newline='\n')
 print('Generated human-only Classroom, complete Pikeman/Public School inheritance and configured effects')

if __name__=='__main__':main()
