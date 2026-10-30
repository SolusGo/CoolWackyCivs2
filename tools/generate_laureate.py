"""Laureate definitions: schema-derived cloning of the active CP replacement rows."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheLaureateCommonwealth'
CIV = 'CIVILIZATION_LAUREATE_COMMONWEALTH'
LEADER = 'LEADER_LAUREA'
UNIT = 'UNIT_LAUREATE_CHAMPION'
HALL = 'BUILDING_HALL_OF_LAURELS'
TRAIT = 'TRAIT_EVERGREEN_CROWN'
CROWN = 'PROMOTION_CROWNING_BLOW'
VETERAN = 'PROMOTION_LAUREL_LEVEL_REWARDED'
GP = 'PROMOTION_LC_PERSON_RECOGNIZED'
POLICY = 'POLICY_LC_GOLDEN_EXCELLENCE'
CITIES = ['Daphne','Stephanopolis','Chryse','Calliste','Arete','Eukleia','Nikephoros',
          'Helikon','Eleuthera','Kleos','Asterion','Laureion','Harmonia','Thaleia',
          'Sophene','Marathos','Praxia','Dikaiopolis','Aurelia','Concordia',
          'Mnemosyne','Euporia','Kallipolis','Evergreen Forum']
TEXT = {
 'CIV':'The Laureate Commonwealth','SHORT':'Laureate Commonwealth','ADJECTIVE':'Laureate',
 'LEADER':'Laurea','TRAIT':'The Evergreen Crown',
 'TRAIT_HELP':'World Wonders earn 40 + 10 per Era [ICON_GOLDEN_AGE] Golden Age Points; Great People earn 20 + 5 per Era; military units first reaching Level 3 earn 10 + 2 per Era. Era starts at 0; instant awards scale with game speed. During Golden Ages: +15% Great Person generation in cities and +15% military combat experience.',
 'STRATEGY':'Pursue Culture through Wonders, Great People and a disciplined army. The Evergreen Crown accelerates normal Golden Age progress without extending Golden Ages. Build Halls of Laurels for steady progress, and use Champions to finish wounded enemies. Technology, expansion and careful positioning remain essential.',
 'UNIT':'Laureate Champion',
 'UNIT_HELP':'Replaces Swordsman. Retains the active Swordsman\'s cost, Strength, Movement, Iron requirement, promotions and upgrades. Crowning Blow: +15% Strength when attacking wounded enemy units; heals 15 HP after killing an enemy military unit. Crowning Blow survives upgrades.',
 'UNIT_STRATEGY':'Let other units wound the enemy, then commit the Champion to a decisive attack. Crowning Blow grants no advantage against healthy units, cities or while defending. Its kill healing supports successive engagements; Iron and normal Swordsman technology are still required.',
 'UNIT_PEDIA':'The Commonwealth crowns its veterans only after their deeds have been witnessed. A Champion wears practical armor, carries the ordinary infantry sword and bears a small wreath as a public obligation: excellence must be renewed in service, never presumed from rank.',
 'HALL':'Hall of Laurels',
 'HALL_HELP':'Replaces Amphitheater and retains all active Amphitheater effects, requirements and its Great Work of Writing slot. Adds +1 Local Happiness and +1 [ICON_GOLDEN_AGE] Golden Age Point each owner turn while functioning. Multiple Halls stack. No points during resistance, razing or empire anarchy.',
 'HALL_STRATEGY':'Build Halls to honor writers, builders and veterans. Their local Happiness follows ordinary population limits. Each functioning Hall adds one point directly to the normal Golden Age meter, even during a Golden Age; its point is separate from Culture.',
 'HALL_PEDIA':'Marble colonnades shelter inscribed accounts of service, statues of citizens and golden wreaths dedicated to great works. The Hall is part theater, part archive and part civic forum. No family owns a hereditary place within it; every name must be supported by an achievement.',
 'CROWN':'Crowning Blow','CROWN_HELP':'+15% Strength when attacking wounded enemy units. No wounded-target bonus against cities or on defense. Heal 15 HP after killing a hostile military unit, capped at maximum HP. Retained on upgrade.',
 'VETERAN':'Laurel Already Awarded','VETERAN_HELP':'This unit has already received its once-per-lifetime Level 3 recognition. No combat effect. Retained through upgrades and transfers.',
 'GP_MARK':'Great Person Already Recognized','GP_MARK_HELP':'Internal lifetime recognition marker. No combat or yield effect.',
 'POLICY':'Golden Excellence','POLICY_HELP':'Automatic Laureate Golden Age modifier: +15% city Great Person generation and +15% combat experience. Cannot be adopted.',
 'CIV_PEDIA':'The Laureate Commonwealth is an imagined ancient republic founded on the laurel wreath: the evergreen sign of victory, honor and lasting achievement. Its citizens celebrate the architect beside the soldier and the poet beside the scholar. Victory is not merely the conquest of an enemy. Victory is the recognition of excellence.[NEWLINE][NEWLINE]Daphne began as a sanctuary where rival communities deposited records of public service. A common charter transformed ceremonial judges into elected magistrates. Laurea, Keeper of the Unfading Crown, safeguards the charter and presides over the recognition of deeds. Her crown belongs to the office, and the office belongs to the citizens.[NEWLINE][NEWLINE]The Evergreen Crown awards normal Golden Age Points for completed global World Wonders (40 + 10 times current Era index), newly created Great People (20 + 5 times Era), and military units first reaching Level 3 (10 + 2 times Era). Ancient is Era 0. Instant rewards use the game speed GreatPeoplePercent, matching the native Golden Age threshold scaling; fractions round down. National and Team Wonders, captured Wonders, captured Great People and replacement units earn no new creation reward. Great People are recognized after native creation/conversion settles, by the next owner-turn boundary or when expended.[NEWLINE][NEWLINE]Golden Ages add 15 percentage points to city Great Person generation and to military combat XP. These modifiers follow the native additive policy system and end with the Golden Age. General/Admiral combat meters and Prophet Faith thresholds are not city specialist generation. Halls add one unscaled point per functioning building per owner turn. The ordinary engine checks the Golden Age threshold on its next normal Golden Age processing step; no custom timer or threshold is used.',
 'LEADER_PEDIA':'Laurea, Keeper of the Unfading Crown, leads through disciplined example. Proud, cultured and competitive, she prizes literature, magnificent architecture and military service. Empty boasts and dishonor receive a colder welcome than honest failure.[NEWLINE][NEWLINE]Her white robes symbolize impartial judgment; green recalls the republic\'s enduring charter, and gold the achievements entrusted to its memory. Laurea insists that greatness can be taught, tested and renewed, but never inherited.',
 'DAWN':'Laurea, Keeper of the Unfading Crown, your Commonwealth looks to you.[NEWLINE][NEWLINE]In Daphne, the wreath honors the builder, the scholar, the artist and the veteran alike. Your ancestors raised a republic where deeds outlive ambition and excellence serves the common good.[NEWLINE][NEWLINE]Build something magnificent. Create someone extraordinary. Train a legendary warrior. Let their achievements kindle an age of prosperity, and let that prosperity inspire still greater work.[NEWLINE][NEWLINE]Will your people earn an unfading place in history?',
 'CIV5_HEADING_1':'A Republic of Earned Honor',
 'LAUREA_NAME':'Laurea','LAUREA_SUBTITLE':'Keeper of the Unfading Crown',
 'LAUREA_LIVED':'The Age of the Commonwealth','LAUREA_TITLES_1':'Keeper of the Unfading Crown',
 'LAUREA_HEADING_1':'Greatness Must Be Earned',
 'GREETING_1':'Greetings. I am Laurea, Keeper of the Unfading Crown. Among our people, greatness is neither inherited nor bestowed. It must be earned. Tell me, stranger, what deeds shall history remember of you?',
 'WAR_1':'You have mistaken restraint for weakness. Let the record show that the Commonwealth answered your dishonor with resolve.',
 'ATTACKED_1':'Then your boasts shall be tested. Our citizens have defended greater things than your ambition.',
 'DEFEAT_1':'The crown passes from my hands. May those who remember us honor what we achieved, and learn from what we failed to defend.',
 'PEACE_1':'Let this peace be a deed worthy of remembrance. Our people have greater work before them.',
 'PEACE_OFFER_1':'We have measured each other in war. Let us now compete in the works that endure.',
 'FRIENDLY_1':'Your achievements have reached Daphne before you. Come, there is much we may learn from each other.',
 'NEUTRAL_1':'The council is listening. What undertaking brings you before the Commonwealth?',
 'HOSTILE_1':'We keep careful records. Your words will require better deeds to support them.',
 'TRADE_1':'A fair exchange, honestly concluded. May both our peoples prosper.',
 'NOTICE_TITLE':'The Evergreen Crown',
 'NOTICE_WONDER':'Completing {1_Name} has earned {2_Num} [ICON_GOLDEN_AGE] Golden Age Points.',
 'NOTICE_PERSON':'A newly created {1_Name} has earned {2_Num} [ICON_GOLDEN_AGE] Golden Age Points.',
 'NOTICE_VETERAN':'{1_Name} has earned its first laurel, granting {2_Num} [ICON_GOLDEN_AGE] Golden Age Points.',
 'NOTICE_GOLDEN':'During this Golden Age, Great People are generated 15% faster in cities and military units gain 15% more combat experience.',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'],LAUREA_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}':n for i,n in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}':n for i,n in enumerate(['Ilex','Clio','Dorian','Ianthe','Lysander','Thalia','Nestor','Eirene','Cassia','Phaedra'],1)})

def clone(*a,**k): return base_clone(*a,**k).replace('BCClone','LCClone')
def companions(*a,**k): return base_companions(*a,**k).replace('BCCompanion','LCCompanion')

def main():
    d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True)
    core="""-- CP v151 hooks; gameplay is scoped to Laureate players.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_PLAYER_TURN','EVENTS_GOLDEN_AGE','EVENTS_UNIT_CREATED',
  'EVENTS_UNIT_UPGRADES','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_CAPTURE','EVENTS_UNIT_PREKILL');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_LC_EMERALD',0.025,0.18,0.105,1),('COLOR_LC_GOLD',0.93,0.73,0.25,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_LC','COLOR_LC_EMERALD','COLOR_LC_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_EVERGREEN_CROWN','TXT_KEY_LC_TRAIT_HELP','TXT_KEY_LC_TRAIT');
"""
    core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_LC_CIV',ShortDescription='TXT_KEY_LC_SHORT',Adjective='TXT_KEY_LC_ADJECTIVE',Civilopedia='TXT_KEY_LC_CIV_PEDIA',CivilopediaTag='TXT_KEY_LC_CIV5',Strategy='TXT_KEY_LC_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_LC',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_LC_DAWN',DawnOfManAudio='',DawnOfManImage='LC_Dawn.dds',MapImage='LC_Map.dds',PortraitIndex=0,IconAtlas='LC_CIV_ATLAS',AlphaIconAtlas='LC_ALPHA_ATLAS')
    core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_LC_LEADER',Civilopedia='TXT_KEY_LC_LEADER_PEDIA',CivilopediaTag='TXT_KEY_LC_LAUREA',PackageID=None,PortraitIndex=0,IconAtlas='LC_LEADER_ATLAS',ArtDefineTag='LC_LeaderScene.xml',DoFWillingness=6,DiploBalance=7,Loyalty=8,Chattiness=4,Meanness=4)
    core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','{TRAIT}');\n"
    core+=clone('Units','UNIT_SWORDSMAN',UNIT,Description='TXT_KEY_LC_UNIT',Civilopedia='TXT_KEY_LC_UNIT_PEDIA',Help='TXT_KEY_LC_UNIT_HELP',Strategy='TXT_KEY_LC_UNIT_STRATEGY',IconAtlas='LC_OBJECT_ATLAS',PortraitIndex=0,UnitFlagAtlas='LC_FLAG_ATLAS',UnitFlagIconOffset=0)
    core+=clone('Buildings','BUILDING_AMPHITHEATER',HALL,Description='TXT_KEY_LC_HALL',Civilopedia='TXT_KEY_LC_HALL_PEDIA',Help='TXT_KEY_LC_HALL_HELP',Strategy='TXT_KEY_LC_HALL_STRATEGY',IconAtlas='LC_OBJECT_ATLAS',PortraitIndex=1)
    core+=f"UPDATE Buildings SET Happiness=Happiness+1 WHERE Type='{HALL}';\n"
    core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SWORDSMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_AMPHITHEATER','{HALL}');\n"
    for table,key,count in [('Civilization_CityNames','CITY',len(CITIES)),('Civilization_SpyNames','SPY',10)]:
        for i in range(1,count+1): core+=f"INSERT INTO {table} VALUES ('{CIV}','TXT_KEY_LC_{key}_{i}');\n"
    personality={'Leader_Flavors','Leader_MajorCivApproachBiases','Leader_MinorCivApproachBiases'}
    skip=tuple(t for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'") if t not in personality)
    inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON',LEADER,skip)
    for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
    inherit+=companions(d,'Unit_','UnitType','UNIT_SWORDSMAN',UNIT)
    inherit+=companions(d,'Building_','BuildingType','BUILDING_AMPHITHEATER',HALL)
    effects=f"""-- Native wounded-unit attack and post-combat military kill healing.
INSERT INTO UnitPromotions(Type,Description,Help,AttackWoundedMod,HPHealedIfDestroyEnemy,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('{CROWN}','TXT_KEY_LC_CROWN','TXT_KEY_LC_CROWN_HELP',15,15,0,1,0,'LC_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LC_CROWN');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','{CROWN}');
"""
    for promotion,key in [(VETERAN,'VETERAN'),(GP,'GP_MARK')]:
        effects+=f"INSERT INTO UnitPromotions(Type,Description,Help,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('{promotion}','TXT_KEY_LC_{key}','TXT_KEY_LC_{key}_HELP',0,0,1,0,0,'LC_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LC_{key}');\n"
    effects+=f"""-- CP IsDummy excludes this policy from policy counts. No branch makes it unselectable.
INSERT INTO Policies(Type,Description,Help,IsDummy,GreatPeopleRateModifier,ExpModifier,PortraitIndex,IconAtlas,IconAtlasAchieved)
 VALUES ('{POLICY}','TXT_KEY_LC_POLICY','TXT_KEY_LC_POLICY_HELP',1,15,15,0,'LC_CIV_ATLAS','LC_CIV_ATLAS');
"""
    for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('ATTACKED','ATTACKED'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('TRADE_ACCEPT_GENEROUS','TRADE'),('TRADE_ACCEPT_ACCEPTABLE','TRADE')]:
        effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_LC_{key}_%',1);\n"
    effects+=f"UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_CULTURE','FLAVOR_WONDER','FLAVOR_GREAT_PEOPLE');\n"
    art=''
    for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2),('LEADER','Portrait',1)]:
        for size in [16,24,32,45,48,64,80,128,256]: art+=f"INSERT INTO IconTextureAtlases VALUES ('LC_{atlas}_ATLAS',{size},'LC_{stem}{size}.dds',{cols},1);\n"
    art+="INSERT INTO IconTextureAtlases VALUES ('LC_FLAG_ATLAS',32,'LC_Flag32.dds',1,1);\n"
    text=''.join("INSERT INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_LC_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name,content in [('00_LC_Core',core),('01_LC_Inheritance',inherit),('02_LC_Effects',effects),('03_LC_Art',art),('10_LC_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content,encoding='utf-8',newline='\n')
    print('Generated Laureate identity, active Swordsman/Amphitheater inheritance and exact modifiers')

if __name__=='__main__': main()
