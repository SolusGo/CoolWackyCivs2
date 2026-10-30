"""Generate HCC definitions from installed BNW/CP schema; inherit active rows at activation."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheHoneycombCommonwealth'
CIV = 'CIVILIZATION_HCC_COMMONWEALTH'
LEADER = 'LEADER_HCC_MELLIA'
UNIT = 'UNIT_HCC_FORAGER'
EXCHANGE = 'BUILDING_HCC_HONEY_EXCHANGE'
PROMOTION = 'PROMOTION_HCC_FORAGER_SIGHT'
DUMMIES = ['PRODUCTION_1', 'PRODUCTION_2', 'PRODUCTION_3', 'PRODUCTION_4', 'CULTURE', 'GOLD_1', 'GOLD_2']
CITIES = ['First Comb', 'Amber Council', 'Nectarhaven', 'Waxminster', 'Pollenford',
          'Thousand Hives', 'Sunflower Reach', 'Golden Orchard', 'Clover Commons',
          'Royal Jelly', 'Honeywell', 'Dancing Meadow', 'Council of Wings', 'Saffron Gate',
          'Sweetwater', 'Acacia Hall', 'The Great Hexagon', 'Blossomwatch', 'Waxbridge',
          'Marigold Assembly', 'Heathercomb', 'Apricot Terrace', 'Lavender Court', 'Last Bloom']
TIMING = ('Plantations are snapshotted when you end your turn, staging the next owner-turn payout. '
          'Assignments changed during a turn do not change its existing bonuses. '
          'Interturn changes wait for the following snapshot (CP v151 hook limitation).')
TEXT = {
 'CIV': 'The Honeycomb Commonwealth', 'SHORT': 'Honeycomb Commonwealth', 'ADJECTIVE': 'Commonwealth',
 'LEADER': 'Speaker Mellia', 'TRAIT': 'A Thousand Small Hands',
 'TRAIT_HELP': 'Each worked, unpillaged Plantation on your own land adds +1 [ICON_PRODUCTION] Production to its city (maximum +4). Cities working at least two also receive +1 [ICON_CULTURE] Culture. These are flat city bonuses. ' + TIMING,
 'UNIT': 'Forager', 'UNIT_HELP': 'Replaces Scout. Retains all active Scout properties, requirements, terrain rules and upgrades, with +1 Movement and +1 Sight. The extra Sight is lost on upgrade; no additional combat or Worker abilities.',
 'UNIT_STRATEGY': 'Explore flowering valleys and locate Plantation resources. Extra Movement and Sight help survey future settlement sites; a Forager cannot construct improvements. Use normal Scout upgrades when available.',
 'UNIT_PEDIA': 'Foragers travel far beyond the hive to assess nectar, pollen and the safety of agricultural land. Their maps are conveyed through precise dances before the Council of Hives. Their skill lies in reconnaissance, not battle or cultivation.',
 'EXCHANGE': 'Honey Exchange',
 'EXCHANGE_HELP': 'Replaces Market and retains all active Market benefits, specialists and requirements. Adds +1 [ICON_FOOD] Food permanently while present. Each two worked, unpillaged Plantations on your land add +1 [ICON_GOLD] Gold (maximum +2 per city), using the same snapshot as A Thousand Small Hands. ' + TIMING + ' A new Exchange begins conditional Gold at the next snapshot. Building loss clears conditional Gold when detected; rebuilding waits for a new snapshot.',
 'EXCHANGE_STRATEGY': 'Build Honey Exchanges to support growth and trade. Two qualifying worked Plantations add +1 Gold; four add +2. Unworked, pillaged and foreign Plantations never qualify. The Market class preserves ordinary policy and technology interactions.',
 'EXCHANGE_PEDIA': 'The Honey Exchange gathers honey, wax and pollen in vast hexagonal storage halls. Representative councils organize fair distribution, reserve supplies for lean seasons and match workers to the fields that need them. Its prosperity depends on active agricultural work.',
 'CIV_PEDIA': 'The Honeycomb Commonwealth is a federation of intelligent honeybees governed through representative hive councils. Separate colonies joined around a common agricultural charter: every worker has a voice, every storehouse has a ledger, and every field has a steward.[NEWLINE][NEWLINE]Its golden cities are built from hexagonal wax structures. Cooperation sustains research, public life and the careful cultivation of flowering resources. Disagreements are settled through elaborate interpretive dances, often followed by extremely detailed committee minutes.',
 'STRATEGY': 'Favor Science or Culture victories. Scout for Plantation resources, improve them with ordinary Workers and actually assign citizens to work them. Reach two worked Plantations per city for Culture and Exchange Gold; four reaches both economic caps. Protect agricultural land. No direct Science, Happiness or combat bonus is granted. ' + TIMING,
 'LEADER_PEDIA': 'Speaker Mellia, an intelligent golden honeybee with a polished amber ceremonial crown, was elected by the Council of Hives. Polite, organized and diplomatically cautious, she sees collective labor and agricultural security as the foundation of freedom.[NEWLINE][NEWLINE]Mellia listens carefully, speaks precisely and protects the workers above all else. Her sharpest disagreements are expressed through elaborate interpretive dances; foreign envoys are advised to bring a patient interpreter.',
 'DAWN': 'Honorable Speaker Mellia, Voice of the Thousand Hives, your people await your guidance.[NEWLINE][NEWLINE]Since the dawn of time, your ancestors have traveled from flower to flower, gathering the riches of the earth and transforming them into the golden treasure of the hive.[NEWLINE][NEWLINE]Alone, each worker was small.[NEWLINE][NEWLINE]Together, they accomplished wonders.[NEWLINE][NEWLINE]Now, the scattered colonies have united beneath a common purpose.[NEWLINE][NEWLINE]No longer shall your people live merely to survive.[NEWLINE][NEWLINE]Establish your settlements. Cultivate the fertile earth. Let every worker contribute to the prosperity of the Commonwealth.[NEWLINE][NEWLINE]Will your civilization become the greatest hive the world has ever known?',
 'PROMOTION': 'Forager Reconnaissance', 'PROMOTION_HELP': '+1 Sight. Lost on upgrade.',
 'DUMMY': 'Commonwealth Collective Labor', 'DUMMY_HELP': 'Automatic Plantation snapshot bonus; cannot be built, bought or sold.',
 'GREETING_1': 'Greetings, traveler! Welcome to the Commonwealth. Please remain calm. The thirty thousand bees surrounding you are merely conducting routine security inspections.',
 'WAR_1': 'You have threatened the hive. The entire hive. Do you understand what that means?',
 'DEFEAT_1': 'The workers... protect the workers... the hive must endure...',
 'PEACE_1': 'Let the workers return to the fields. The Council accepts peace.',
 'PEACE_OFFER_1': 'Our gardens need tending. Let us conclude this disagreement before another dance is required.',
 'FRIENDLY_1': 'A welcome guest! We have prepared honey and a very short committee agenda.',
 'NEUTRAL_1': 'The Council is assembled. Please state your business clearly.',
 'HOSTILE_1': 'Your conduct has inspired a most severe interpretive dance. I suggest you take it seriously.',
 'ATTACKED_1': 'You have endangered our workers. Every hive will hear of this.',
 'TRADE_1': 'The ledgers agree. May this exchange nourish both our peoples.',
 'CIV5_HEADING_1': 'The Council of Hives', 'MELLIA_NAME': 'Speaker Mellia',
 'MELLIA_SUBTITLE': 'Voice of the Thousand Hives', 'MELLIA_LIVED': 'The Age of the Commonwealth',
 'MELLIA_TITLES_1': 'Elected Speaker of the Council of Hives', 'MELLIA_HEADING_1': 'For the Good of the Hive',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], MELLIA_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': name for i, name in enumerate(['Clover', 'Heather', 'Saffron', 'Acacia', 'Marigold', 'Lavender', 'Borage', 'Linden', 'Verbena', 'Rosemary'], 1)})

def clone(*a, **k): return base_clone(*a, **k).replace('BCClone', 'HCCClone')
def companions(*a, **k): return base_companions(*a, **k).replace('BCCompanion', 'HCCCompanion')

def main():
    d = database()
    (V / 'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- CP v151 only. Hooks exposed through the collection's existing option convention.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_PLAYER_TURN','EVENTS_CITY');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_HCC_AMBER',0.24,0.10,0.015,1),('COLOR_HCC_HONEY',1,0.73,0.12,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_HCC','COLOR_HCC_AMBER','COLOR_HCC_HONEY','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_HCC_SMALL_HANDS','TXT_KEY_HCC_TRAIT_HELP','TXT_KEY_HCC_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV, Description='TXT_KEY_HCC_CIV', ShortDescription='TXT_KEY_HCC_SHORT', Adjective='TXT_KEY_HCC_ADJECTIVE', Civilopedia='TXT_KEY_HCC_CIV_PEDIA', CivilopediaTag='TXT_KEY_HCC_CIV5', Strategy='TXT_KEY_HCC_STRATEGY', DefaultPlayerColor='PLAYERCOLOR_HCC', Playable=1, AIPlayable=0, PackageID=None, DawnOfManQuote='TXT_KEY_HCC_DAWN', DawnOfManAudio='', DawnOfManImage='HCC_Dawn.dds', MapImage='HCC_Map.dds', PortraitIndex=0, IconAtlas='HCC_CIV_ATLAS', AlphaIconAtlas='HCC_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER, Description='TXT_KEY_HCC_LEADER', Civilopedia='TXT_KEY_HCC_LEADER_PEDIA', CivilopediaTag='TXT_KEY_HCC_MELLIA', PackageID=None, PortraitIndex=0, IconAtlas='HCC_LEADER_ATLAS', ArtDefineTag='HCC_LeaderScene.xml', DoFWillingness=5, DiploBalance=8, Loyalty=8, Chattiness=5, Meanness=2)
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_HCC_SMALL_HANDS');\n"
    core += clone('Units', 'UNIT_SCOUT', UNIT, Description='TXT_KEY_HCC_UNIT', Civilopedia='TXT_KEY_HCC_UNIT_PEDIA', Help='TXT_KEY_HCC_UNIT_HELP', Strategy='TXT_KEY_HCC_UNIT_STRATEGY', IconAtlas='HCC_OBJECT_ATLAS', PortraitIndex=0, UnitFlagAtlas='HCC_FLAG_ATLAS', UnitFlagIconOffset=0)
    core += f"UPDATE Units SET Moves=Moves+1 WHERE Type='{UNIT}';\n"
    core += clone('Buildings', 'BUILDING_MARKET', EXCHANGE, Description='TXT_KEY_HCC_EXCHANGE', Civilopedia='TXT_KEY_HCC_EXCHANGE_PEDIA', Help='TXT_KEY_HCC_EXCHANGE_HELP', Strategy='TXT_KEY_HCC_EXCHANGE_STRATEGY', IconAtlas='HCC_OBJECT_ATLAS', PortraitIndex=1)
    core += f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SCOUT','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_MARKET','{EXCHANGE}');\n"
    for table, suffix, count in [('Civilization_CityNames', 'CITY', len(CITIES)), ('Civilization_SpyNames', 'SPY', 10)]:
        for i in range(1, count + 1): core += f"INSERT INTO {table} VALUES ('{CIV}','TXT_KEY_HCC_{suffix}_{i}');\n"
    personality = {'Leader_Flavors', 'Leader_MajorCivApproachBiases', 'Leader_MinorCivApproachBiases'}
    skip = tuple(t for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'") if t not in personality)
    inherit = companions(d, 'Leader_', 'LeaderType', 'LEADER_WASHINGTON', LEADER, skip)
    for t in ['Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits']:
        inherit += companions(d, t, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    inherit += companions(d, 'Unit_', 'UnitType', 'UNIT_SCOUT', UNIT)
    inherit += companions(d, 'Building_', 'BuildingType', 'BUILDING_MARKET', EXCHANGE)
    effects = f"""-- Unique Sight disappears on upgrade; the Scout's own promotions are inherited separately.
INSERT INTO UnitPromotions(Type,Description,Help,VisibilityChange,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('{PROMOTION}','TXT_KEY_HCC_PROMOTION','TXT_KEY_HCC_PROMOTION_HELP',1,1,1,0,'HCC_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_HCC_PROMOTION');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','{PROMOTION}');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{EXCHANGE}' AND YieldType='YIELD_FOOD';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{EXCHANGE}','YIELD_FOOD',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{EXCHANGE}' AND YieldType='YIELD_FOOD');
"""
    for suffix in DUMMIES:
        y = suffix.split('_')[0]
        effects += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_{suffix}','BUILDING_HCC_{suffix}','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_{suffix}','BUILDINGCLASS_HCC_{suffix}','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_{suffix}','YIELD_{y}',1);
"""
    for response, key in [('FIRST_GREETING','GREETING'), ('DECLAREWAR','WAR'), ('DEFEATED','DEFEAT'), ('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'), ('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'), ('PEACE_OFFER','PEACE_OFFER'), ('GREETING_POLITE_HELLO','FRIENDLY'), ('GREETING_NEUTRAL_HELLO','NEUTRAL'), ('GREETING_HOSTILE_HELLO','HOSTILE'), ('ATTACKED','ATTACKED'), ('TRADE_ACCEPT_GENEROUS','TRADE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_HCC_{key}_%',1);\n"
    effects += f"UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_SCIENCE','FLAVOR_CULTURE','FLAVOR_GROWTH','FLAVOR_TILE_IMPROVEMENT');\n"
    art = ''
    for atlas, stem, cols in [('CIV','Icon',1), ('ALPHA','Alpha',1), ('OBJECT','Objects',2), ('LEADER','Portrait',1)]:
        for size in [16,24,32,45,48,64,80,128,256]: art += f"INSERT INTO IconTextureAtlases VALUES ('HCC_{atlas}_ATLAS',{size},'HCC_{stem}{size}.dds',{cols},1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('HCC_FLAG_ATLAS',32,'HCC_Flag32.dds',1,1);\n"
    text = ''.join("INSERT INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_HCC_" + k + "','" + v.replace("'", "''") + "');\n" for k,v in sorted(TEXT.items()))
    for name, content in [('00_HCC_Core',core), ('01_HCC_Inheritance',inherit), ('02_HCC_Effects',effects), ('03_HCC_Art',art), ('10_HCC_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content, encoding='utf-8', newline='\n')
    print('Generated HCC active Scout/Market inheritance, identity, seven distinct dummies and localization')

if __name__ == '__main__': main()
