"""Generate Lantern Fleet SQL from the installed BNW / CP151 schema."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheLanternFleet'
CIV = 'CIVILIZATION_LANTERN_FLEET'
LEADER = 'LEADER_LANTERN_MAREN'
UNIT = 'UNIT_LANTERN_BEACON_CUTTER'
LIGHTHOUSE = 'BUILDING_LANTERN_SIGNAL_LIGHTHOUSE'
DUMMIES = ['BUILDING_LANTERN_GUARDED_HARBOR', 'BUILDING_LANTERN_SIGNAL_GOLD']
CITIES = ['First Beacon', 'Lanternwatch', 'Safehaven', 'Stormward', 'Golden Shoal',
          'Maren Sound', 'The Returning Light', 'Keeper\'s Anchorage', 'Brasswater',
          'Last Watch', 'Hearthtide', 'North Beacon', 'Stillwater Quay', 'Seaglass',
          'Pilgrim Harbor', 'Far Lantern', 'Tideward', 'Shelter Bay', 'Dawn Passage', 'Eternal Flame']
TEXT = {
 'CIV': 'The Lantern Fleet', 'SHORT': 'The Lantern Fleet', 'ADJECTIVE': 'Lantern',
 'LEADER': 'High Keeper Maren', 'TRAIT': 'No Harbor Goes Dark',
 'TRAIT_HELP': 'At the start of your turn, each coastal city with at least one of its owner\'s naval combat units inside the CITY CENTER gains +2 [ICON_RESEARCH] Science and +1 [ICON_CULTURE] Culture for that turn. One ship is enough; additional ships do not stack. Adjacent, foreign, civilian and embarked units do not qualify. Movement after the check changes eligibility only at your next turn start. No era scaling.',
 'UNIT': 'Beacon Cutter',
 'UNIT_HELP': 'Replaces the active Trireme. Retains its normal rules, stats, requirements and upgrade path. +1 Sight and +15% Combat Strength when fighting in friendly territory, on attack and defense. No additional Strength elsewhere. These unique bonuses are retained on upgrade.',
 'UNIT_STRATEGY': 'Scout the coast with additional Sight, protect friendly waters and station a Cutter inside a coastal city center before your next turn begins. Any later naval combat unit can also guard a harbor.',
 'UNIT_PEDIA': 'Beacon Cutters escort travelers through the dangerous approaches to Lantern ports. Their crews carry powerful lanterns and know the friendly shoals intimately. Their hulls and armaments follow the ordinary Trireme tradition. The unique lantern training grants +1 Sight and +15% Strength in native friendly territory, on offense and defense, and is retained on upgrade; ordinary inherited promotions follow their normal rules.',
 'LIGHTHOUSE': 'Signal Lighthouse',
 'LIGHTHOUSE_HELP': 'Replaces the active Lighthouse and retains all its normal effects. Always provides +1 [ICON_CULTURE] Culture. Provides +2 [ICON_GOLD] Gold for an owner-turn if this city has a Signal Lighthouse and qualifies as a Guarded Harbor at that turn\'s start. Requires an owned naval combat unit inside the coastal CITY CENTER. One ship is enough; movement afterward does not change the snapshot. No era scaling.',
 'LIGHTHOUSE_STRATEGY': 'Build for its normal Lighthouse benefits and permanent Culture. Station an owned warship in the coastal city center before turn start for the additional Gold. With a qualifying guard, this building and the ability together add +2 Science, +2 Culture and +2 Gold.',
 'LIGHTHOUSE_PEDIA': 'Signal Lighthouses preserve the promise that no harbor will be left in darkness. Their keepers record safe passages, welcome returning families and coordinate the ships sheltering beneath their lights. Their +1 Culture needs no ship. Their +2 Gold requires both the Lighthouse and Guarded Harbor qualification at owner-turn start. It shares the same fixed snapshot as No Harbor Goes Dark and adds to all ordinary Lighthouse effects.',
 'CIV_PEDIA': 'The Lantern Fleet began as families crossing restless oceans in search of a peaceful shore. Storms and predatory fleets taught them a common duty: no vessel would be forgotten, no sailor abandoned, no harbor left in darkness.[NEWLINE][NEWLINE]No Harbor Goes Dark checks every owned city once at owner-turn start. The native coastal-city test must pass, and at least one living, non-embarked naval combat unit owned by that city\'s actual owner must occupy its exact city-center plot. Adjacent ships, Cargo Ships, civilians, embarked land units and friendly or allied foreign ships do not qualify. Any eligible naval military unit, including later-era warships, works; multiple ships never stack.[NEWLINE][NEWLINE]Each qualifying city receives +2 Science and +1 Culture through an invisible building. The Signal Lighthouse adds +1 permanent Culture and, when present at the same qualifying snapshot, +2 Gold. Combined: +2 Science, +2 Culture, +2 Gold, plus the ordinary Lighthouse effects. These flat base yields have no era scaling and follow ordinary native city yield modifiers.[NEWLINE][NEWLINE]Entering after the check waits until next turn. Leaving after the check retains this turn\'s bonus. Save/load retains the existing snapshot without another check or payout. Capture immediately clears both conditional bonuses, including a transfer to another Lantern player; the new owner waits for its next legitimate turn-start check.',
 'LEADER_PEDIA': 'High Keeper Maren is an elderly guardian of the sea roads. In a weathered navy coat bearing golden insignia, she carries a large brass lantern through a chamber overlooking the stormy ocean. Protective, cautious and hospitable, she values safe navigation and defensive naval strength. Threats against her harbors meet a determined response.',
 'STRATEGY': 'Defensive naval economy. Settle the coast, keep owned naval combat ships inside city centers before turn start and develop Signal Lighthouses. Science and Culture are preferred victories. A guard protects the harbor and powers a fixed economic snapshot; leaving afterward keeps the bonus until the next check.',
 'DAWN': 'High Keeper Maren, Guardian of the Eternal Flame, your people await your guidance.[NEWLINE][NEWLINE]For generations, your ancestors crossed the restless oceans, searching for shores where their families could finally find peace.[NEWLINE][NEWLINE]They endured terrible storms, treacherous waters, and the cruelty of those who preyed upon defenseless travelers.[NEWLINE][NEWLINE]Yet through every hardship, one promise endured.[NEWLINE][NEWLINE]No vessel would be forgotten. No sailor would be abandoned. No harbor would be left in darkness.[NEWLINE][NEWLINE]Now, your people have established their first permanent settlement.[NEWLINE][NEWLINE]Raise your lighthouses. Gather your fleets. Let your lanterns illuminate the darkest corners of the world.[NEWLINE][NEWLINE]Will you guide your civilization toward a brighter future?',
 'GUARD': 'Guarded Harbor', 'GUARD_HELP': 'Internal turn-start snapshot: +2 Science and +1 Culture. Cannot be constructed, purchased or sold.',
 'GOLD': 'Signal Harbor Trade', 'GOLD_HELP': 'Internal Signal Lighthouse turn-start snapshot: +2 Gold. Cannot be constructed, purchased or sold.',
 'PROMOTION': 'Keeper of Friendly Waters', 'PROMOTION_HELP': '+1 Sight. +15% Combat Strength in friendly territory on attack and defense. No bonus Strength elsewhere. Retained on upgrade; granted only to Beacon Cutters.',
 'GREETING_1': 'Welcome, traveler. You must have endured quite a journey. Come inside. The storm is growing stronger.',
 'WAR_1': 'I offered your people safe harbor. You answered with violence. Very well. Our lights shall guide our ships to yours.',
 'DEFEAT_1': "The lantern... please... don't let it go out.",
 'PEACE_1': 'Let the lights welcome our sailors home.', 'PEACE_OFFER_1': 'There is still a safe harbor for peace.',
 'FRIENDLY_1': 'Come in, friend. There is warmth by the lantern.', 'NEUTRAL_1': 'What news do you bring from the sea?',
 'HOSTILE_1': 'Our keepers are watching your sails.', 'ATTACKED_1': 'Then our harbors will stand against you.',
 'TRADE_1': 'May this agreement bring our people safely home.',
 'CIV5_HEADING_1': 'No Harbor Goes Dark', 'MAREN_NAME': 'High Keeper Maren',
 'MAREN_SUBTITLE': 'Guardian of the Eternal Flame', 'MAREN_LIVED': 'The age of the returning fleets',
 'MAREN_TITLES_1': 'High Keeper of the Lantern Fleet', 'MAREN_HEADING_1': 'The Keeper\'s Promise',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], MAREN_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': name for i, name in enumerate([
 'Wick', 'Harbor Watch', 'Sea Glass', 'North Light', 'Fog Bell', 'Brass Key',
 'Storm Petrel', 'Blue Flame', 'Night Tide', 'Last Lantern'], 1)})


def clone(*args, **kwargs):
    return base_clone(*args, **kwargs).replace('BCClone', 'LANTERN_Clone')


def companions(*args, **kwargs):
    return base_companions(*args, **kwargs).replace('BCCompanion', 'LANTERN_Companion')


def main():
    d = database()
    (V / 'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- Append after released content. CP151 active rows, never vanilla constants.
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_LANTERN_NAVY',0.035,0.09,0.18,1),('COLOR_LANTERN_GOLD',0.94,0.72,0.25,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_LANTERN','COLOR_LANTERN_NAVY','COLOR_LANTERN_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_LANTERN_NO_HARBOR_DARK','TXT_KEY_LANTERN_TRAIT_HELP','TXT_KEY_LANTERN_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV,
        Description='TXT_KEY_LANTERN_CIV', ShortDescription='TXT_KEY_LANTERN_SHORT', Adjective='TXT_KEY_LANTERN_ADJECTIVE',
        Civilopedia='TXT_KEY_LANTERN_CIV_PEDIA', CivilopediaTag='TXT_KEY_LANTERN_CIV5', Strategy='TXT_KEY_LANTERN_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_LANTERN', Playable=1, AIPlayable=0, PackageID=None,
        DawnOfManQuote='TXT_KEY_LANTERN_DAWN', DawnOfManAudio='', DawnOfManImage='LANTERN_Dawn.dds',
        MapImage='LANTERN_Map.dds', PortraitIndex=0, IconAtlas='LANTERN_CIV_ATLAS', AlphaIconAtlas='LANTERN_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER,
        Description='TXT_KEY_LANTERN_LEADER', Civilopedia='TXT_KEY_LANTERN_LEADER_PEDIA', CivilopediaTag='TXT_KEY_LANTERN_MAREN',
        PackageID=None, PortraitIndex=0, IconAtlas='LANTERN_LEADER_ATLAS', ArtDefineTag='LANTERN_LeaderScene.xml',
        Boldness=3, VictoryCompetitiveness=6, WonderCompetitiveness=6, MinorCivCompetitiveness=5,
        WarmongerHate=9, DoFWillingness=7, Loyalty=9, Meanness=2)
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_LANTERN_NO_HARBOR_DARK');\n"
    core += clone('Units', 'UNIT_TRIREME', UNIT, Description='TXT_KEY_LANTERN_UNIT', Civilopedia='TXT_KEY_LANTERN_UNIT_PEDIA',
        Help='TXT_KEY_LANTERN_UNIT_HELP', Strategy='TXT_KEY_LANTERN_UNIT_STRATEGY', IconAtlas='LANTERN_OBJECT_ATLAS',
        PortraitIndex=1, UnitFlagAtlas='LANTERN_FLAG_ATLAS', UnitFlagIconOffset=0)
    core += clone('Buildings', 'BUILDING_LIGHTHOUSE', LIGHTHOUSE, Description='TXT_KEY_LANTERN_LIGHTHOUSE',
        Civilopedia='TXT_KEY_LANTERN_LIGHTHOUSE_PEDIA', Help='TXT_KEY_LANTERN_LIGHTHOUSE_HELP',
        Strategy='TXT_KEY_LANTERN_LIGHTHOUSE_STRATEGY', IconAtlas='LANTERN_OBJECT_ATLAS', PortraitIndex=0)
    core += f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_TRIREME','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_LIGHTHOUSE','{LIGHTHOUSE}');\n"
    core += f"INSERT INTO Civilization_Start_Along_Ocean VALUES ('{CIV}',1);\n"
    for i in range(1, len(CITIES)+1):
        core += f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_LANTERN_CITY_{i}');\n"
    for i in range(1, 11):
        core += f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_LANTERN_SPY_{i}');\n"
    inherit = '-- Copy active companion relationships, including CP extensions. No inherited leader traits.\n'
    for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit += companions(d, table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    for table in ['Leader_Flavors','Leader_MajorCivApproachBiases','Leader_MinorCivApproachBiases']:
        inherit += companions(d, table, 'LeaderType', 'LEADER_WASHINGTON', LEADER)
    inherit += companions(d, 'Unit', 'UnitType', 'UNIT_TRIREME', UNIT)
    inherit += companions(d, 'Building', 'BuildingType', 'BUILDING_LIGHTHOUSE', LIGHTHOUSE)
    effects = f"""INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,VisibilityChange,FriendlyLandsModifier,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_LANTERN_FRIENDLY_WATERS','TXT_KEY_LANTERN_PROMOTION','TXT_KEY_LANTERN_PROMOTION_HELP',1,0,1,15,0,'LANTERN_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LANTERN_PROMOTION');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_LANTERN_FRIENDLY_WATERS');
-- Add exactly one Culture to the inherited total (do not duplicate base yields).
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE rowid=(SELECT MIN(rowid) FROM Building_YieldChanges WHERE BuildingType='{LIGHTHOUSE}' AND YieldType='YIELD_CULTURE');
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{LIGHTHOUSE}','YIELD_CULTURE',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{LIGHTHOUSE}' AND YieldType='YIELD_CULTURE');
UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_NAVAL','FLAVOR_NAVAL_RECON','FLAVOR_NAVAL_TILE_IMPROVEMENT','FLAVOR_SCIENCE','FLAVOR_CULTURE','FLAVOR_DEFENSE');
UPDATE Leader_Flavors SET Flavor=3 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_OFFENSE','FLAVOR_EXPANSION');
UPDATE Leader_MajorCivApproachBiases SET Bias=2 WHERE LeaderType='{LEADER}' AND MajorCivApproachType='MAJOR_CIV_APPROACH_WAR';
"""
    for dummy, key, values in [(DUMMIES[0],'GUARD',[('SCIENCE',2),('CULTURE',1)]), (DUMMIES[1],'GOLD',[('GOLD',2)])]:
        cls = dummy.replace('BUILDING_', 'BUILDINGCLASS_', 1)
        effects += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('{cls}','{dummy}','TXT_KEY_LANTERN_{key}');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('{dummy}','{cls}','TXT_KEY_LANTERN_{key}','TXT_KEY_LANTERN_{key}_HELP',-1,-1,-1,1,1,1,0,0,'LANTERN_CIV_ATLAS',0);
"""
        for yield_type, value in values:
            effects += f"INSERT INTO Building_YieldChanges VALUES ('{dummy}','YIELD_{yield_type}',{value});\n"
    for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('DEFEATED','DEFEAT'),
        ('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),
        ('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('ATTACKED','ATTACKED'),('TRADE_ACCEPT_GENEROUS','TRADE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_LANTERN_{key}_%',1);\n"
    art = ''
    for atlas,stem,columns in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2),('LEADER','Portrait',1)]:
        for size in [16,24,32,45,48,64,80,128,256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('LANTERN_{atlas}_ATLAS',{size},'LANTERN_{stem}{size}.dds',{columns},1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('LANTERN_FLAG_ATLAS',32,'LANTERN_Flag32.dds',1,1);\n"
    text = ''.join("INSERT INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_LANTERN_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name,content in [('00_LANTERN_Core',core),('01_LANTERN_Inheritance',inherit),('02_LANTERN_Effects',effects),('03_LANTERN_Art',art),('10_LANTERN_Text',text)]:
        (V/'SQL'/(name+'.sql')).write_text(content,encoding='utf-8',newline='\n')
    print('Generated Lantern Fleet active-row SQL')


if __name__ == '__main__': main()
