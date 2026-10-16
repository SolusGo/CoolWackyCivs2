"""Generate Pigeon SQL using the installed BNW/CP schema and active baselines."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheRepublicOfPigeons'
CIV = 'CIVILIZATION_PIGEON_REPUBLIC'
LEADER = 'LEADER_PIGEON_COO'
UNIT = 'UNIT_PIGEON_CARRIER'
ROOST = 'BUILDING_PIGEON_ROOFTOP_ROOST'
CITIES = ['Coopolis', 'Nestminster', 'Featherford', 'Coochester', 'Rooftopia', 'Winghaven',
          'Breadcrumb Bay', 'Pigeonholm', 'Perchfield', 'Dovecourt', 'Greyfeather', 'Skypost',
          'Posthaven', 'Featherbridge', 'Highperch', 'Quillborough', 'Letterwick', 'Crestfall',
          'Sealstone', 'Eavesbury', 'Northwing', 'Parapet', 'Silvercrop', 'Last Perch']
TEXT = {
 'CIV': 'The Republic of Pigeons', 'SHORT': 'Pigeon Republic', 'ADJECTIVE': 'Pigeon',
 'LEADER': 'Postmaster General Coo', 'TRAIT': 'Messages on the Wing',
 'TRAIT_HELP': 'Each active outgoing LAND Trade Route grants its origin city +2 [ICON_RESEARCH] Science and +2 [ICON_CULTURE] Culture. These bonuses increase to +3 each upon reaching the Renaissance Era. Domestic and international routes qualify; multiple routes stack. Sea routes and incoming routes do not qualify.',
 'UNIT': 'Carrier Pigeon',
 'UNIT_HELP': 'Replaces the Scout. +1 Sight compared with the standard Scout. Ignores terrain movement costs, preserving the Scout\'s reconnaissance role, promotions, ancient ruin benefits and upgrade path. Normal impassable terrain and embarkation rules apply.',
 'UNIT_STRATEGY': 'Send Carrier Pigeons ahead to meet neighbors, locate ancient ruins and identify safe land trade destinations. Their extra sight helps watch approaches, but their combat strength remains that of a Scout.',
 'UNIT_PEDIA': 'Every Carrier Pigeon takes the postal oath: neither rain, nor hills, nor a particularly interesting statue shall delay the mail. These intrepid messengers survey distant lands with an eye for good routes and an even sharper eye for unattended grain. The battlefield model uses the standard Scout for clear reconnaissance behavior.',
 'ROOST': 'Rooftop Roost',
 'ROOST_HELP': 'Replaces the Caravansary and retains all of its normal benefits. +1 [ICON_CULTURE] Culture. While this city has at least one active outgoing LAND Trade Route, it also gains +2 [ICON_PRODUCTION] Production. This Production bonus does not stack with additional routes. Sea routes and incoming routes do not activate it.',
 'ROOST_STRATEGY': 'Build Rooftop Roosts in your land trade origins. One outgoing caravan activates the full +2 Production; additional caravans still multiply Messages on the Wing. Protect the routes to keep the workshops busy.',
 'ROOST_PEDIA': 'Above each bustling caravan yard stands a sheltered roost, where postal clerks sort letters and couriers compare crumbs. The daily traffic brings new songs, stories and practical ideas to the city below. When caravans leave the gates, rooftop workshops turn that correspondence into useful work.',
 'CIV_PEDIA': 'The Republic of Pigeons began as a loose compact among the rooftop roosts of Coopolis. Each tower kept its own customs, but every tower depended on messages from the next. When a winter storm scattered the couriers, the surviving roosts agreed that no letter should be abandoned merely because its destination stood beyond another flock\'s eaves.[NEWLINE][NEWLINE]From that promise grew a republic. Its assemblies meet on broad parapets; its laws are sealed with wax and, occasionally, a footprint. Caravan masters fund the relay stations, scholars exchange observations through them, and visiting artists discover an audience at every stop. Its citizens consider reliable correspondence both a public service and the foundation of civilized life.[NEWLINE][NEWLINE]The Republic is an original fictional civilization. Its history celebrates communication, curiosity and the unlikely dignity of ordinary city birds.',
 'LEADER_PEDIA': 'Before becoming Postmaster General, Coo maintained the least fashionable relay in Coopolis: a wind-battered chimney overlooking the grain market. Coo made it indispensable by delivering every message, including complaints addressed to the wrong tower.[NEWLINE][NEWLINE]Elected after the Great Misdelivery, Coo standardized postal seals, opened the courier colleges and required public officials to answer their correspondence. Behind the ceremonial cap and solemn coo lies a patient negotiator who prefers a signed agreement to a sharpened beak. Yet the General keeps watch over the caravan roads: a republic that cannot defend its messengers cannot keep its promises.',
 'STRATEGY': 'Explore early with Carrier Pigeons, then establish protected land Trade Routes. Concentrate several routes in a strong origin for stacked Science and Culture, or spread them among Rooftop Roost cities to activate several Production bonuses. Internal routes support growth while still earning the UA. Reach the Renaissance to improve every qualifying route. Favor Science, then Culture and Diplomacy; maintain enough defense to keep the correspondence moving.',
 'DAWN': 'Attend, Postmaster General Coo! From the chimneys of Coopolis to the towers beyond the horizon, your citizens await the morning mail. Where others see scattered rooftops, you see a republic joined by trust, curiosity and tireless wings.[NEWLINE][NEWLINE]Send your Carrier Pigeons into unfamiliar skies. Raise Rooftop Roosts above busy caravan yards, and let each departing messenger bring knowledge and culture home. Will your correspondence unite the world, and will your republic take its place among the enduring civilizations?',
 'SIGHT': 'Postal Lookout', 'SIGHT_HELP': '+1 Sight. A watchful courier misses neither a distant tower nor an approaching threat.',
 'DUMMY': 'Postal network', 'DUMMY_HELP': 'Automatically maintained from active outgoing land Trade Routes.',
 'GREETING_1': 'Greetings, stranger. I am Postmaster General Coo, guardian of every message that takes wing. May our correspondence be fruitful, and our breadcrumbs plentiful.',
 'PEACE_1': 'Then let the next message carry an olive branch. Our roosts shall welcome peaceful correspondence once more.',
 'WAR_1': 'You have intercepted our correspondence for the last time. The skies themselves shall carry our displeasure!',
 'DEFEAT_1': 'Our roosts lie empty, our messages undelivered. Even the mightiest wings must someday rest.',
 'SPY_1': 'Dead Letter', 'SPY_2': 'Quiet Quill', 'SPY_3': 'Grey Seal', 'SPY_4': 'Night Courier',
 'SPY_5': 'Soft Landing', 'SPY_6': 'Hidden Perch', 'SPY_7': 'Black Ink', 'SPY_8': 'Second Post',
 'SPY_9': 'Loose Feather', 'SPY_10': 'Return Address',
}
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({'CIV5_HEADING_1': 'A Republic Above the Streets', 'CIV5_TEXT_1': TEXT['CIV_PEDIA'],
             'COO_NAME': TEXT['LEADER'], 'COO_SUBTITLE': 'Keeper of the Public Post',
             'COO_LIVED': 'The Age of Open Correspondence', 'COO_TITLES_1': 'Postmaster General',
             'COO_HEADING_1': 'From Chimney Clerk to Statesbird', 'COO_TEXT_1': TEXT['LEADER_PEDIA']})

def clone(*args, **kwargs):
    return base_clone(*args, **kwargs).replace('BCClone', 'PIGEONClone')

def companions(*args, **kwargs):
    return base_companions(*args, **kwargs).replace('BCCompanion', 'PIGEONCompanion')

def main():
    d = database()
    (V / 'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- CP v151 hook options; all handlers are scoped to the Pigeon mechanics.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_NEW_ERA','EVENTS_TRADE_ROUTES','EVENTS_TRADE_ROUTE_PLUNDERED');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_PIGEON_SLATE',0.31,0.38,0.48,1),('COLOR_PIGEON_CREAM',0.95,0.91,0.77,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_PIGEON','COLOR_PIGEON_SLATE','COLOR_PIGEON_CREAM','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_PIGEON_MESSAGES','TXT_KEY_PIGEON_TRAIT_HELP','TXT_KEY_PIGEON_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV,
        Description='TXT_KEY_PIGEON_CIV', ShortDescription='TXT_KEY_PIGEON_SHORT', Adjective='TXT_KEY_PIGEON_ADJECTIVE',
        Civilopedia='TXT_KEY_PIGEON_CIV_PEDIA', CivilopediaTag='TXT_KEY_PIGEON_CIV5', Strategy='TXT_KEY_PIGEON_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_PIGEON', Playable=1, AIPlayable=1, PackageID=None,
        DawnOfManQuote='TXT_KEY_PIGEON_DAWN', DawnOfManAudio='', DawnOfManImage='PigeonDawn.dds', MapImage='PigeonMap.dds',
        PortraitIndex=0, IconAtlas='PIGEON_CIV_ATLAS', AlphaIconAtlas='PIGEON_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER,
        Description='TXT_KEY_PIGEON_LEADER', Civilopedia='TXT_KEY_PIGEON_LEADER_PEDIA', CivilopediaTag='TXT_KEY_PIGEON_COO',
        PackageID=None, Boldness=4, VictoryCompetitiveness=7, WonderCompetitiveness=5, MinorCivCompetitiveness=7,
        DiploBalance=8, WarmongerHate=8, DoFWillingness=8, DenounceWillingness=5, Loyalty=8,
        Forgiveness=7, Chattiness=8, Meanness=2, Neediness=4,
        PortraitIndex=0, IconAtlas='PIGEON_LEADER_ATLAS', ArtDefineTag='PigeonLeaderScene.xml')
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_PIGEON_MESSAGES');\n"
    # SELECT * at activation preserves ALL active scalar CP fields, even added columns.
    core += clone('Units', 'UNIT_SCOUT', UNIT,
        Description='TXT_KEY_PIGEON_UNIT', Civilopedia='TXT_KEY_PIGEON_UNIT_PEDIA', Help='TXT_KEY_PIGEON_UNIT_HELP',
        Strategy='TXT_KEY_PIGEON_UNIT_STRATEGY', IconAtlas='PIGEON_OBJECT_ATLAS', PortraitIndex=1,
        UnitFlagAtlas='PIGEON_FLAG_ATLAS', UnitFlagIconOffset=0)
    core += clone('Buildings', 'BUILDING_CARAVANSARY', ROOST,
        Description='TXT_KEY_PIGEON_ROOST', Civilopedia='TXT_KEY_PIGEON_ROOST_PEDIA', Help='TXT_KEY_PIGEON_ROOST_HELP',
        Strategy='TXT_KEY_PIGEON_ROOST_STRATEGY', IconAtlas='PIGEON_OBJECT_ATLAS', PortraitIndex=0)
    core += f"""INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SCOUT','{UNIT}');
INSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_CARAVANSARY','{ROOST}');
INSERT INTO UnitPromotions(Type,Description,Help,VisibilityChange,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_PIGEON_LOOKOUT','TXT_KEY_PIGEON_SIGHT','TXT_KEY_PIGEON_SIGHT_HELP',1,1,1,1,'PIGEON_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_PIGEON_SIGHT');
"""
    for i in range(1, len(CITIES)+1):
        core += f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_PIGEON_CITY_{i}');\n"
    for i in range(1, 11):
        core += f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_PIGEON_SPY_{i}');\n"
    inherit = companions(d, 'Leader_', 'LeaderType', 'LEADER_WASHINGTON', LEADER, ('Leader_Traits',))
    for table in ['Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits']:
        inherit += companions(d, table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    inherit += companions(d, 'Unit_', 'UnitType', 'UNIT_SCOUT', UNIT)
    inherit += companions(d, 'Building_', 'BuildingType', 'BUILDING_CARAVANSARY', ROOST)
    effects = f"""-- Scout promotions were inspected: CP v151 already grants IgnoreTerrainCost.
-- Preserve those exact promotions; only supply the standard effect if absent.
INSERT INTO Unit_FreePromotions(UnitType,PromotionType)
 SELECT '{UNIT}','PROMOTION_IGNORE_TERRAIN_COST'
 WHERE NOT EXISTS (SELECT 1 FROM Unit_FreePromotions f JOIN UnitPromotions p ON p.Type=f.PromotionType
 WHERE f.UnitType='{UNIT}' AND p.IgnoreTerrainCost=1);
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_PIGEON_LOOKOUT');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{ROOST}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield)
 SELECT '{ROOST}','YIELD_CULTURE',1 WHERE NOT EXISTS
 (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{ROOST}' AND YieldType='YIELD_CULTURE');
"""
    # IsDummy/ShowInPedia are verified CP v151 fields, in addition to the usual cost safeguards.
    for name, yield_type, amount in [('ROUTE_SCIENCE', 'SCIENCE', 1), ('ROUTE_CULTURE', 'CULTURE', 1), ('ROOST_PRODUCTION', 'PRODUCTION', 2)]:
        effects += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description)
 VALUES ('BUILDINGCLASS_PIGEON_{name}','BUILDING_PIGEON_{name}','TXT_KEY_PIGEON_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_PIGEON_{name}','BUILDINGCLASS_PIGEON_{name}','TXT_KEY_PIGEON_DUMMY','TXT_KEY_PIGEON_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'PIGEON_OBJECT_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_PIGEON_{name}','YIELD_{yield_type}',{amount});
"""
    flavors = {'SCIENCE':9,'CULTURE':8,'DIPLOMACY':8,'SPACESHIP':9,'RECON':9,'GOLD':8,
               'I_LAND_TRADE_ROUTE':10,'I_TRADE_ORIGIN':9,'I_TRADE_DESTINATION':6,'I_SEA_TRADE_ROUTE':4,
               'INFRASTRUCTURE':8,'GROWTH':7,'PRODUCTION':7,'DEFENSE':7,'CITY_DEFENSE':7,
               'OFFENSE':4,'MILITARY_TRAINING':5,'EXPANSION':6,'WONDER':5,'RELIGION':3,'USE_NUKE':2}
    for name, value in flavors.items():
        effects += f"DELETE FROM Leader_Flavors WHERE LeaderType='{LEADER}' AND FlavorType='FLAVOR_{name}';\nINSERT INTO Leader_Flavors SELECT '{LEADER}',Type,{value} FROM Flavors WHERE Type='FLAVOR_{name}';\n"
    for name, value in {'WAR':3,'HOSTILE':3,'DECEPTIVE':3,'GUARDED':5,'AFRAID':3,'FRIENDLY':8,'NEUTRAL':6}.items():
        effects += f"UPDATE Leader_MajorCivApproachBiases SET Bias={value} WHERE LeaderType='{LEADER}' AND MajorCivApproachType='MAJOR_CIV_APPROACH_{name}';\n"
    for name, value in {'IGNORE':3,'FRIENDLY':8,'PROTECTIVE':7,'CONQUEST':2,'BULLY':3}.items():
        effects += f"UPDATE Leader_MinorCivApproachBiases SET Bias={value} WHERE LeaderType='{LEADER}' AND MinorCivApproachType='MINOR_CIV_APPROACH_{name}';\n"
    # Native diplomacy handles all other situations with its generic responses.
    for response, text in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('DEFEATED','DEFEAT'),
                           ('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_OFFER','PEACE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_PIGEON_{text}_%',1);\n"
    art = ''
    for atlas, stem, columns in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2)]:
        for size in [16,24,32,45,48,64,80,128,256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('PIGEON_{atlas}_ATLAS',{size},'Pigeon{stem}{size}.dds',{columns},1);\n"
    for size in [64,128,256]:
        art += f"INSERT INTO IconTextureAtlases VALUES ('PIGEON_LEADER_ATLAS',{size},'PigeonPortrait{size}.dds',1,1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('PIGEON_FLAG_ATLAS',32,'PigeonFlag32.dds',1,1);\n"
    text = '\n'.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_PIGEON_"+key+"','"+value.replace("'","''")+"');" for key,value in sorted(TEXT.items()))+'\n'
    for name, content in [('00_PIGEON_Core',core),('01_PIGEON_Inheritance',inherit),('02_PIGEON_Effects',effects),('03_PIGEON_Art',art),('10_PIGEON_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content, encoding='utf-8', newline='\n')
    print('Generated Pigeon identity, full active Scout/Caravansary inheritance, effects, art and English text')

if __name__ == '__main__': main()
