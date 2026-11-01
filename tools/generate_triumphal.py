"""Generate the isolated Imperium database module from the installed BNW/CP schema.

Runtime SELECT cloning preserves the active replacement's balance and companions.
No other civilization generator or artwork is invoked.
"""
from pathlib import Path
from database import database
from generate_database import clone, companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheTriumphalImperium'
CIV = 'CIVILIZATION_TRIUMPHAL_IMPERIUM'
LEADER = 'LEADER_TRI_AURELION'
UNIT = 'UNIT_TRI_UNBROKEN'
HALL = 'BUILDING_TRI_HALL_OF_TRIUMPHS'
CITIES = ['Corona Invicta', 'Porta Aeterna', 'Aureum Forum', 'Castrum Victoris',
          'Rubra Concordia', 'Laurea Ferrata', 'Vallis Triumphalis', 'Arx Solis',
          'Nova Victoria', 'Ferrum Magna', 'Aquae Imperiales', 'Columna Regia',
          'Portus Aurelionis', 'Mons Invictus', 'Vigilantia', 'Gloria Prima',
          'Corona Australis', 'Via Fortis', 'Solarium', 'Custodia', 'Aquila Rubra',
          'Castrum Ultimum', 'Aurora Victrix', 'Finis Renovatus']
TEXT = {
 'CIV': 'The Triumphal Imperium', 'SHORT': 'Triumphal Imperium', 'ADJECTIVE': 'Imperial',
 'LEADER': 'Imperator Aurelion', 'TRAIT': 'Victory Begets Victory',
 'TRAIT_HELP': 'Earn Victory Momentum (0-6): +1 for defeating a major civilization military unit in combat; +2 for conquering a major civilization city. Each point grants +2% military Combat Strength and +4% military unit Production in every city. Lose 1 after a complete owner-turn cycle without a qualifying victory, including defensive victories between turns. Each city site grants conquest Momentum once per Imperium player. Conquests earn a free Hall of Triumphs after Bronze Working.',
 'STRATEGY': 'Prepare a normal economy, Iron supply and army before fighting. Chain victories against major civilizations to build Momentum; defensive kills also sustain it. At 4 Momentum, original Unbroken gain 1 Movement and Halls gain +10% local military Production. Choose Domination, but preserve units and Happiness: Momentum fades during unsuccessful campaigns or peace.',
 'UNIT': 'The Unbroken',
 'UNIT_HELP': 'Replaces Swordsman, retaining its active cost, Strength, Iron requirement, Movement and technology. Unbroken Advance: +10% attacking Combat Strength, retained on upgrade. At 4 or more Victory Momentum, original Unbroken gain +1 Movement; this temporary effect is removed below 4 and on upgrade. Activating it never refills movement.',
 'UNIT_STRATEGY': 'Use these elite infantry offensively alongside ranged support. Their permanent attack bonus survives upgrading; Victorious March belongs only to the original Unbroken type. They still need Iron, healing, good terrain and protection against concentrated fire.',
 'UNIT_PEDIA': 'The Unbroken carry the marks of every campaign on shields passed from veteran to recruit. Their name is an obligation rather than a promise of invulnerability. They advance because the soldier beside them advances, and every laurel on a standard records a victory that must be surpassed.',
 'HALL': 'Hall of Triumphs',
 'HALL_HELP': 'Replaces Barracks and preserves its normal cost, maintenance, requirements and military experience. Adds +1 Culture. At 4 or more Victory Momentum: +10% local military unit Production, additive with empire Momentum. A city conquered from a major civilization receives this actual building once Bronze Working is known; diplomatic transfers and founded cities do not qualify.',
 'HALL_STRATEGY': 'Train troops in Halls and keep Momentum at 4 or higher to activate their local military industry. At 6 Momentum a Hall city receives +24% empire and +10% local military Production, totaling +34 percentage points before other normal modifiers. Civilian units, buildings and projects receive neither bonus.',
 'HALL_PEDIA': 'Captured weapons line the marble galleries of the Hall of Triumphs. Here recruits hear the names of the fallen, artisans inspect foreign arms, and officers plan the next campaign beneath crimson standards. The institution preserves military training even in peace; its great furnaces answer only the demand of renewed victories.',
 'CIV_PEDIA': 'The Triumphal Imperium rose along the roads and river crossings of Corona Invicta. Its rulers regarded triumph as a public duty: victory proved that discipline, supply and command were aligned, and obliged them to attempt something greater. Laurel wreaths were cast in gold and set above workshops as often as palaces.[NEWLINE][NEWLINE]Success brought recruits and confidence. Conquered cities became training centers, and their captured weapons filled new Halls of Triumphs. Yet the same institutions faltered when victories ceased. No emperor could live forever on the memory of an old procession.[NEWLINE][NEWLINE]One Victory Demands Another.',
 'LEADER_PEDIA': 'Aurelion earned his first command defending a river bridge and his imperial title reopening the road beyond it. He treats ceremony as a contract with the next campaign. His confidence is formidable, but he respects capable enemies and knows that an army without farms, smiths and roads cannot march on pride alone.',
 'DAWN': 'Imperator Aurelion, the golden laurel awaits you.[NEWLINE][NEWLINE]From Corona Invicta your people have raised roads, drilled their legions and built halls for victories still to come. They ask for neither an effortless conquest nor an empty boast. They ask that success become the strength to succeed again.[NEWLINE][NEWLINE]Break the enemy line, seize the gates, and let each triumph awaken another army. But remember: when victory falls silent, confidence fades.[NEWLINE][NEWLINE]Will your Imperium carry the laurel to the ends of the earth? One Victory Demands Another.',
 'CIV5_HEADING_1': 'One Victory Demands Another',
 'AURELION_NAME': 'Imperator Aurelion', 'AURELION_SUBTITLE': 'Bearer of the Unfinished Laurel',
 'AURELION_LIVED': 'The Age of the Imperium', 'AURELION_TITLES_1': 'Imperator',
 'AURELION_HEADING_1': 'The Next Triumph',
 'ADVANCE': 'Unbroken Advance', 'ADVANCE_HELP': '+10% Combat Strength when attacking. Retained on upgrade.',
 'MARCH': 'Victorious March', 'MARCH_HELP': '+1 Movement for original Unbroken while their Imperium has at least 4 Victory Momentum. Lost on upgrade; never refills movement.',
 'MOMENTUM': 'Victory Momentum', 'MOMENTUM_HELP': 'Empire-wide military strength from current Victory Momentum.',
 'DUMMY': 'Imperial Mobilisation', 'DUMMY_HELP': 'Hidden military Production modifier managed by Victory Momentum.',
 'UI_TITLE': 'VICTORY MOMENTUM: {1_Num} / 6',
 'UI_EFFECTS': 'Strength +{1_Num}%   Military Production +{2_Num}%',
 'UI_ACTIVE': '[COLOR_POSITIVE_TEXT]ACTIVE[ENDCOLOR]', 'UI_INACTIVE': 'INACTIVE (requires 4)',
 'UI_TIP': 'Victory Momentum: {1_Num}/6[NEWLINE]Combat Strength: +{2_Num}%[NEWLINE]Military unit Production in all cities: +{3_Num}%[NEWLINE]Unbroken - Victorious March (+1 Movement): {4_Status}[NEWLINE]Hall of Triumphs (+10% local military Production): {4_Status}[NEWLINE][NEWLINE]+1 per major military combat kill; +2 per first conquest of a major city site. No rewards from barbarians, City-States or civilians. Each complete owner-turn cycle without a qualifying victory loses 1. Victories between turns count. Hover here for current effects.',
 'NOTICE_TITLE': 'Victory Begets Victory',
 'NOTICE_GAIN': 'Victories have raised Victory Momentum to {1_Num}/6. Your armies and military workshops grow stronger.',
 'NOTICE_MAX': 'The Imperium stands at maximum Victory Momentum: 6/6. +12% military Combat Strength and +24% military Production. One Victory Demands Another.',
 'NOTICE_DECAY': 'A complete turn cycle passed without a qualifying victory. Victory Momentum falls to {1_Num}/6.',
 'GREETING_1': 'I am Aurelion, Imperator of the Triumphal Imperium. You arrive beneath the laurel of our last victory. Speak before we march toward the next.',
 'WAR_1': 'The road to our next triumph passes through your gates. Prepare your armies.',
 'ATTACKED_1': 'You have brought our next victory to us. The legions will remember your generosity.',
 'DEFEAT_1': 'The procession ends. Let history record that we marched, and that you proved the stronger.',
 'PEACE_1': 'Let our soldiers rest and our smiths work. The laurel does not wither in a single day.',
 'PEACE_OFFER_1': 'We have measured one another. Accept peace, and let each empire prepare its own future.',
 'FRIENDLY_1': 'A worthy ally sharpens ambition. What shall our peoples accomplish together?',
 'NEUTRAL_1': 'The Imperium hears you. Make your purpose clear.',
 'HOSTILE_1': 'Your words have enjoyed a longer peace than your deeds deserve.',
 'TRADE_1': 'Agreed. Our roads shall carry the terms of this bargain.',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], AURELION_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': x for i, x in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': x for i, x in enumerate(['Cassian', 'Valeria', 'Drusus', 'Livia', 'Corvin', 'Severa', 'Marcellus', 'Aelia', 'Vigil', 'Octavia'], 1)})

def main():
    d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True)
    core="""-- Expose verified CP hooks; every gameplay mutation is namespaced and owner-scoped.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_BATTLES','EVENTS_UNIT_PREKILL','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS',
  'EVENTS_UNIT_UPGRADES','EVENTS_CITY','EVENTS_CITY_FOUNDING');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_TRI_CRIMSON',0.32,0.018,0.045,1),('COLOR_TRI_GOLD',0.83,0.65,0.28,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_TRI_IMPERIUM','COLOR_TRI_CRIMSON','COLOR_TRI_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_TRI_VICTORY_BEGETS_VICTORY','TXT_KEY_TRI_TRAIT_HELP','TXT_KEY_TRI_TRAIT');
"""
    def c(*a,**kw): return clone(*a,**kw).replace('BCClone','TRIClone')
    core+=c('Civilizations','CIVILIZATION_ROME',CIV,Description='TXT_KEY_TRI_CIV',ShortDescription='TXT_KEY_TRI_SHORT',Adjective='TXT_KEY_TRI_ADJECTIVE',Civilopedia='TXT_KEY_TRI_CIV_PEDIA',CivilopediaTag='TXT_KEY_TRI_CIV5',Strategy='TXT_KEY_TRI_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_TRI_IMPERIUM',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_TRI_DAWN',DawnOfManAudio='',DawnOfManImage='TRI_Dawn.dds',MapImage='TRI_Map.dds',PortraitIndex=0,IconAtlas='TRI_CIV_ATLAS',AlphaIconAtlas='TRI_ALPHA_ATLAS')
    core+=c('Leaders','LEADER_AUGUSTUS',LEADER,Description='TXT_KEY_TRI_LEADER',Civilopedia='TXT_KEY_TRI_LEADER_PEDIA',CivilopediaTag='TXT_KEY_TRI_AURELION',PackageID=None,PortraitIndex=0,IconAtlas='TRI_LEADER_ATLAS',ArtDefineTag='TRI_LeaderScene.xml')
    core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_TRI_VICTORY_BEGETS_VICTORY');\n"
    core+=c('Units','UNIT_SWORDSMAN',UNIT,Description='TXT_KEY_TRI_UNIT',Civilopedia='TXT_KEY_TRI_UNIT_PEDIA',Help='TXT_KEY_TRI_UNIT_HELP',Strategy='TXT_KEY_TRI_UNIT_STRATEGY',IconAtlas='TRI_OBJECT_ATLAS',PortraitIndex=0,UnitFlagAtlas='TRI_FLAG_ATLAS',UnitFlagIconOffset=0)
    core+=c('Buildings','BUILDING_BARRACKS',HALL,Description='TXT_KEY_TRI_HALL',Civilopedia='TXT_KEY_TRI_HALL_PEDIA',Help='TXT_KEY_TRI_HALL_HELP',Strategy='TXT_KEY_TRI_HALL_STRATEGY',IconAtlas='TRI_OBJECT_ATLAS',PortraitIndex=1)
    core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SWORDSMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_BARRACKS','{HALL}');\n"
    for table,key,count in [('Civilization_CityNames','CITY',len(CITIES)),('Civilization_SpyNames','SPY',10)]:
        for i in range(1,count+1): core+=f"INSERT INTO {table} VALUES ('{CIV}','TXT_KEY_TRI_{key}_{i}');\n"
    inherit='-- Copy active base companions at activation; no hardcoded Swordsman/Barracks balance.\n'
    for prefix,col,old,new,skip in [
        ('Leader_','LeaderType','LEADER_AUGUSTUS',LEADER,tuple(t for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'") if t not in ('Leader_Flavors','Leader_MajorCivApproachBiases','Leader_MinorCivApproachBiases'))),
        ('Civilization_','CivilizationType','CIVILIZATION_ROME',CIV,tuple(t for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'") if t not in ('Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits'))),
        ('Unit_','UnitType','UNIT_SWORDSMAN',UNIT,()),
        ('Building_','BuildingType','BUILDING_BARRACKS',HALL,())]:
        inherit+=companions(d,prefix,col,old,new,skip).replace('BCCompanion','TRICompanion')
    effects=f"""-- The Hall adds exactly one Culture to the inherited Barracks yields.
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{HALL}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield)
 SELECT '{HALL}','YIELD_CULTURE',1 WHERE NOT EXISTS
 (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{HALL}' AND YieldType='YIELD_CULTURE');
INSERT INTO UnitPromotions(Type,Description,Help,AttackMod,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_TRI_UNBROKEN_ADVANCE','TXT_KEY_TRI_ADVANCE','TXT_KEY_TRI_ADVANCE_HELP',10,0,0,1,1,0,'TRI_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_TRI_ADVANCE');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_TRI_UNBROKEN_ADVANCE');
INSERT INTO UnitPromotions(Type,Description,Help,MovesChange,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_TRI_VICTORIOUS_MARCH','TXT_KEY_TRI_MARCH','TXT_KEY_TRI_MARCH_HELP',1,1,1,1,1,0,'TRI_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_TRI_MARCH');
"""
    for level in range(1,7):
        effects+=f"INSERT INTO UnitPromotions(Type,Description,Help,CombatPercent,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('PROMOTION_TRI_MOMENTUM_{level}','TXT_KEY_TRI_MOMENTUM','TXT_KEY_TRI_MOMENTUM_HELP',{2*level},1,1,1,0,0,'TRI_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_TRI_MOMENTUM');\n"
    for suffix,mod in [(str(i),i*4) for i in range(1,7)]+[('HALL_ACTIVE',10)]:
        effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_TRI_MOBILISATION_{suffix}','BUILDING_TRI_MOBILISATION_{suffix}','TXT_KEY_TRI_DUMMY');\n"
        effects+=f"INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,IsDummy,ShowInPedia,NeverCapture,ConquestProb,NukeImmune,MilitaryProductionModifier,PortraitIndex,IconAtlas) VALUES ('BUILDING_TRI_MOBILISATION_{suffix}','BUILDINGCLASS_TRI_MOBILISATION_{suffix}','TXT_KEY_TRI_DUMMY','TXT_KEY_TRI_DUMMY_HELP',-1,-1,-1,1,0,1,0,1,{mod},0,'TRI_CIV_ATLAS');\n"
    for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('ATTACKED','ATTACKED'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('TRADE_ACCEPT_GENEROUS','TRADE'),('TRADE_ACCEPT_ACCEPTABLE','TRADE')]:
        effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_TRI_{key}_%',1);\n"
    art=''
    for atlas,stem,cols,sizes in [('CIV','Icon',1,[16,24,32,45,48,64,80,128,256]),('ALPHA','Alpha',1,[16,24,32,45,48,64,80,128,256]),('LEADER','Portrait',1,[16,24,32,45,48,64,80,128,256]),('OBJECT','Objects',2,[16,24,32,45,48,64,80,128,256]),('FLAG','Flag',1,[32])]:
        for size in sizes: art+=f"INSERT INTO IconTextureAtlases VALUES ('TRI_{atlas}_ATLAS',{size},'TRI_{stem}{size}.dds',{cols},1);\n"
    text=''.join("INSERT INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_TRI_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name,content in [('00_TRI_Core',core),('01_TRI_Inheritance',inherit),('02_TRI_Effects',effects),('03_TRI_Art',art),('10_TRI_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content,encoding='utf-8',newline='\n')
    print('Generated Imperium database files; existing civilizations untouched')

if __name__=='__main__': main()
