"""Generate The Twelfth Hour against the installed BNW/CP v151 schema."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheTwelfthHour'
CIV = 'CIVILIZATION_TWELFTH_HOUR'
LEADER = 'LEADER_TWELFTH_KEEPER'
UNIT = 'UNIT_TWELFTH_PENDULUM_GUARD'
TOWER = 'BUILDING_TWELFTH_MUNICIPAL_CLOCKTOWER'
CITIES = ['Last Minute', 'Clockhaven', 'Pendulum', 'Hourglass', 'Brassminster',
          'Secondhand', 'Gearsford', 'Chimefall', 'Twelve Bells', 'Chronopolis',
          'Midnight Spire', 'Windington', 'Tickford', 'Golden Dial', 'Stillwatch',
          'The Final Hour', 'Gearhaven', 'Bellminster', 'Sundial', "Eternity's Gate"]
TEXT = {
 'CIV': 'The Twelfth Hour', 'SHORT': 'The Twelfth Hour', 'ADJECTIVE': 'Clockwork',
 'LEADER': 'The Keeper of Seconds', 'TRAIT': 'When the Clock Strikes',
 'TRAIT_HELP': 'Every sixth played turn (6, 12, 18...), the Grand Chime grants ALL your cities +75% [ICON_PRODUCTION] Production and +50% [ICON_RESEARCH] Science for one turn. The cycle follows the saved game turn, at every game speed. The first five turns are normal.',
 'UNIT': 'Pendulum Guard',
 'UNIT_HELP': 'Replaces Pikeman and retains its normal Community Patch characteristics and promotions. +1 [ICON_MOVES] Movement and +15% Combat Strength when fighting in friendly territory. Both bonuses are retained on upgrade.',
 'UNIT_STRATEGY': 'Use the extra Movement to reinforce threatened clockwork cities. Fight in friendly territory to gain the strength bonus on attack and defense. Upgraded veterans keep their disciplined response.',
 'UNIT_PEDIA': 'The Pendulum Guard drill to a metronome that never pauses. Their polearms carry a counterweight beneath the blade, and their midnight-blue cloaks mark the watch to which they belong. A guard leaves one gate as another arrives: neither haste nor hesitation may interrupt the schedule. On the battlefield they use the standard Pikeman model.',
 'TOWER': 'Municipal Clocktower',
 'TOWER_HELP': 'Replaces Workshop, retaining ALL its normal Community Patch benefits. +1 [ICON_CULTURE] Culture permanently. During the Grand Chime only, adds +2 flat [ICON_PRODUCTION] Production, which participates in normal city yield modifiers.',
 'TOWER_STRATEGY': 'Raise Clocktowers in productive cities before the sixth turn of each cycle. Their Culture is permanent; the extra two base Production arrives only with the Chime. Existing Workshop specialists, prerequisites and modifiers remain in force.',
 'TOWER_PEDIA': 'A Municipal Clocktower is workshop, public calendar and civic monument. Beneath its polished brass dial, engineers compare factory regulators against the municipal pendulum. Its bells divide work from rest and summon the city to shared festivals. During a Grand Chime every district releases its prepared work together.',
 'CIV_PEDIA': 'The Twelfth Hour began when distant workshops agreed upon a single noon. Before the Accord of Seconds, no two city clocks agreed: trains waited at empty platforms, experiments ended too soon, and foundries poured into unready molds. A network of observatories and municipal pendulums replaced those quarrels with a shared measure.[NEWLINE][NEWLINE]Every citizen now keeps a precise schedule. Factories exchange standardized parts, researchers publish observations against the Grand Clock, and schools teach the care of an escapement alongside letters. Every sixth turn their separate preparations converge in the Grand Chime, an extraordinary interval of synchronized work and discovery.[NEWLINE][NEWLINE]Their mastery is organizational, not supernatural. A clock cannot grant another day; it can help a society use the day it has. The Twelfth Hour is an original fictional industrial civilization.',
 'LEADER_PEDIA': 'No surviving register records the Keeper of Seconds taking office. The oldest municipal ledger simply notes that the Keeper arrived on time. Cloaked among gears and celestial instruments, this mysterious figure presides over the Grand Clock and the public standards from which every lesser clock is set.[NEWLINE][NEWLINE]The Keeper demands punctuality from ministries and generals alike, but regards rest as part of a well-made schedule. Schools, workshops and observatories receive equal attention: knowledge plans the mechanism, industry builds it, and culture gives its motion purpose. Those who threaten the clockwork cities discover that their defenders have already rehearsed the response.',
 'STRATEGY': 'Plan around turns 6, 12, 18 and every sixth turn thereafter. Grow several cities to multiply the Grand Chime, develop Science infrastructure, and time important construction around its Production surge. Municipal Clocktowers preserve Workshop benefits and add Culture plus Chime Production. Pendulum Guards reinforce friendly territory quickly and keep their bonuses on upgrade. Favor Science, then industry-supported Domination; Culture and Diplomacy remain viable.',
 'DAWN': 'Keeper of Seconds, the hands of eternity turn once more.[NEWLINE][NEWLINE]Others measure greatness in gold, territory and conquest. Your people measure it in moments.[NEWLINE][NEWLINE]Your clocks have synchronized. Your workshops stand ready. Your scholars await the next stroke of the Grand Clock.[NEWLINE][NEWLINE]Will you command the passage of time, or become another civilization forgotten by it?',
 'PROMOTION': 'Disciplined Pendulum',
 'PROMOTION_HELP': '+1 [ICON_MOVES] Movement. +15% Combat Strength in friendly territory when attacking or defending. Retained on upgrade.',
 'CHIME': 'THE GRAND CHIME!',
 'CHIME_HELP': 'The clocks have synchronized! All cities receive +75% [ICON_PRODUCTION] Production and +50% [ICON_RESEARCH] Science this turn. Municipal Clocktowers add +2 flat Production. The next Grand Chime is in 6 turns.',
 'DUMMY': 'Grand Chime', 'DUMMY_HELP': 'Automatically synchronized with the Grand Clock; cannot be constructed or purchased.',
 'GREETING_1': 'Greetings, traveller. You have arrived precisely when expected. I am the Keeper of Seconds. May our meeting prove a productive use of time.',
 'WAR_1': 'Your final hour has been scheduled. I assure you, we are never late.',
 'PEACE_1': 'Let us set aside the hour of war. Our clocks shall mark a common peace, beginning now.',
 'DEFEAT_1': 'Even the grandest clock must eventually... stop.',
 'CIV5_HEADING_1': 'The Accord of Seconds',
 'KEEPER_NAME': 'The Keeper of Seconds', 'KEEPER_SUBTITLE': 'Custodian of the Grand Clock',
 'KEEPER_LIVED': 'The Synchronized Age', 'KEEPER_TITLES_1': 'The Keeper of Seconds',
 'KEEPER_HEADING_1': 'A Precisely Scheduled Mystery',
}
TEXT.update({'CIV5_TEXT_1': TEXT['CIV_PEDIA'], 'KEEPER_TEXT_1': TEXT['LEADER_PEDIA']})
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': name for i, name in enumerate([
 'Silent Tick', 'Second Hand', 'Escapement', 'Night Watch', 'Hidden Gear',
 'Minute Mark', 'Quiet Chime', 'False Noon', 'Balance Wheel', 'Last Stroke'], 1)})

def clone(*args, **kwargs):
    return base_clone(*args, **kwargs).replace('BCClone', 'TWELFTHClone')

def companions(*args, **kwargs):
    return base_companions(*args, **kwargs).replace('BCCompanion', 'TWELFTHCompanion')

def main():
    d = database()
    (V / 'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- CP v151: PlayerDoneTurn is essential: PlayerDoTurn is AFTER yield settlement.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_PLAYER_TURN','EVENTS_CITY');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_TWELFTH_MIDNIGHT',0.035,0.065,0.16,1),('COLOR_TWELFTH_GOLD',0.83,0.67,0.31,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_TWELFTH','COLOR_TWELFTH_MIDNIGHT','COLOR_TWELFTH_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_TWELFTH_WHEN_CLOCK_STRIKES','TXT_KEY_TWELFTH_TRAIT_HELP','TXT_KEY_TWELFTH_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV,
        Description='TXT_KEY_TWELFTH_CIV', ShortDescription='TXT_KEY_TWELFTH_SHORT', Adjective='TXT_KEY_TWELFTH_ADJECTIVE',
        Civilopedia='TXT_KEY_TWELFTH_CIV_PEDIA', CivilopediaTag='TXT_KEY_TWELFTH_CIV5', Strategy='TXT_KEY_TWELFTH_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_TWELFTH', Playable=1, AIPlayable=0, PackageID=None,
        DawnOfManQuote='TXT_KEY_TWELFTH_DAWN', DawnOfManAudio='', DawnOfManImage='TWELFTH_Dawn.dds', MapImage='TWELFTH_Map.dds',
        PortraitIndex=0, IconAtlas='TWELFTH_CIV_ATLAS', AlphaIconAtlas='TWELFTH_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER,
        Description='TXT_KEY_TWELFTH_LEADER', Civilopedia='TXT_KEY_TWELFTH_LEADER_PEDIA', CivilopediaTag='TXT_KEY_TWELFTH_KEEPER',
        PackageID=None, PortraitIndex=0, IconAtlas='TWELFTH_LEADER_ATLAS', ArtDefineTag='TWELFTH_LeaderScene.xml')
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_TWELFTH_WHEN_CLOCK_STRIKES');\n"
    core += clone('Units', 'UNIT_PIKEMAN', UNIT,
        Description='TXT_KEY_TWELFTH_UNIT', Civilopedia='TXT_KEY_TWELFTH_UNIT_PEDIA', Help='TXT_KEY_TWELFTH_UNIT_HELP',
        Strategy='TXT_KEY_TWELFTH_UNIT_STRATEGY', IconAtlas='TWELFTH_OBJECT_ATLAS', PortraitIndex=1,
        UnitFlagAtlas='TWELFTH_FLAG_ATLAS', UnitFlagIconOffset=0)
    core += clone('Buildings', 'BUILDING_WORKSHOP', TOWER,
        Description='TXT_KEY_TWELFTH_TOWER', Civilopedia='TXT_KEY_TWELFTH_TOWER_PEDIA', Help='TXT_KEY_TWELFTH_TOWER_HELP',
        Strategy='TXT_KEY_TWELFTH_TOWER_STRATEGY', IconAtlas='TWELFTH_OBJECT_ATLAS', PortraitIndex=0)
    core += f"""INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_PIKEMAN','{UNIT}');
INSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_WORKSHOP','{TOWER}');
INSERT INTO UnitPromotions(Type,Description,Help,MovesChange,FriendlyLandsModifier,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_TWELFTH_PENDULUM','TXT_KEY_TWELFTH_PROMOTION','TXT_KEY_TWELFTH_PROMOTION_HELP',1,15,1,0,1,'TWELFTH_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_TWELFTH_PROMOTION');
"""
    for i in range(1, len(CITIES) + 1):
        core += f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_TWELFTH_CITY_{i}');\n"
    for i in range(1, 11):
        core += f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_TWELFTH_SPY_{i}');\n"
    inherit = companions(d, 'Leader_', 'LeaderType', 'LEADER_WASHINGTON', LEADER, ('Leader_Traits',))
    for table in ['Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits']:
        inherit += companions(d, table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    inherit += companions(d, 'Unit_', 'UnitType', 'UNIT_PIKEMAN', UNIT)
    inherit += companions(d, 'Building_', 'BuildingType', 'BUILDING_WORKSHOP', TOWER)
    effects = f"""INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_TWELFTH_PENDULUM');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{TOWER}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield)
 SELECT '{TOWER}','YIELD_CULTURE',1 WHERE NOT EXISTS
 (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{TOWER}' AND YieldType='YIELD_CULTURE');
"""
    for suffix in ['GRAND_CHIME', 'CLOCKTOWER_CHIME']:
        effects += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description)
 VALUES ('BUILDINGCLASS_TWELFTH_{suffix}','BUILDING_TWELFTH_{suffix}','TXT_KEY_TWELFTH_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_TWELFTH_{suffix}','BUILDINGCLASS_TWELFTH_{suffix}','TXT_KEY_TWELFTH_DUMMY','TXT_KEY_TWELFTH_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'TWELFTH_CIV_ATLAS',0);
"""
    effects += """INSERT INTO Building_YieldModifiers(BuildingType,YieldType,Yield) VALUES
 ('BUILDING_TWELFTH_GRAND_CHIME','YIELD_PRODUCTION',75),
 ('BUILDING_TWELFTH_GRAND_CHIME','YIELD_SCIENCE',50);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES
 ('BUILDING_TWELFTH_CLOCKTOWER_CHIME','YIELD_PRODUCTION',2);
"""
    for response, text in [('FIRST_GREETING','GREETING'), ('DECLAREWAR','WAR'), ('DEFEATED','DEFEAT'),
                           ('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'), ('PEACE_OFFER','PEACE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_TWELFTH_{text}_%',1);\n"
    art = ''
    for atlas, stem, columns in [('CIV','Icon',1), ('ALPHA','Alpha',1), ('OBJECT','Objects',2), ('LEADER','Portrait',1)]:
        for size in [16,24,32,45,48,64,80,128,256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('TWELFTH_{atlas}_ATLAS',{size},'TWELFTH_{stem}{size}.dds',{columns},1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('TWELFTH_FLAG_ATLAS',32,'TWELFTH_Flag32.dds',1,1);\n"
    text = '\n'.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_TWELFTH_"+key+"','"+value.replace("'","''")+"');" for key,value in sorted(TEXT.items()))+'\n'
    for name, content in [('00_TWELFTH_Core',core), ('01_TWELFTH_Inheritance',inherit),
                          ('02_TWELFTH_Effects',effects), ('03_TWELFTH_Art',art), ('10_TWELFTH_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content, encoding='utf-8', newline='\n')
    print('Generated Twelfth Hour: human-only identity, full Pikeman/Workshop inheritance, effects, art and localization')

if __name__ == '__main__':
    main()
