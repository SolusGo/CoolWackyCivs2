"""Generate Conical Union SQL against the installed BNW + CP v151 schema.

Scalar SELECT * clones read the active rows at mod activation, not generator time.
Companions enumerate every installed Unit*/Building* table with the owning key,
including UnitGameplay2DScripts. No native or released civilization is updated.
"""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheConicalUnion'
CIV = 'CIVILIZATION_CONICAL_UNION'
LEADER = 'LEADER_CONICAL_BOLLARD'
UNIT = 'UNIT_CONICAL_ROAD_CREW'
OFFICE = 'BUILDING_CONICAL_DETOUR_OFFICE'
CONNECTION = 'BUILDING_CONICAL_CONNECTION_DUMMY'
GOLD = 'BUILDING_CONICAL_DETOUR_GOLD_DUMMY'
CITIES = ['Permanent Detour', 'Roadblock', 'Orange Junction', 'Construction Zone',
          'Temporary Closure', 'Conefordshire', 'Diversion Point', 'No Through Road',
          'Caution Crossing', 'Reflective Heights', 'The Long Detour', 'Barricade Bay',
          'Traffic Circle', 'Pylon Harbor', 'Lane Reduction', 'Under Maintenance',
          'Permit Pending', 'Contraflow', 'Hard Shoulder', 'Civic Obstruction',
          'Stopgap', 'Surveyor\'s Rest', 'Advance Warning', 'Final Inspection',
          'Provisional Terminus', 'Yielding Fields', 'Approved Diversion', 'End of Works']
TEXT = {
 'CIV': 'The Conical Union', 'SHORT': 'The Conical Union', 'ADJECTIVE': 'Conical',
 'LEADER': 'High Marshal Bollard', 'TRAIT': 'Sorry for the Inconvenience',
 'TRAIT_HELP': 'Every non-capital city connected to the Capital receives +2 [ICON_PRODUCTION] Production and +1 [ICON_CULTURE] Culture. Uses native city connections, including qualifying Harbors. Bonuses update at lifecycle events and owner-turn reconciliation after native network refresh; see the guide for timing.',
 'UNIT': 'Road Crew',
 'UNIT_HELP': 'Replaces Worker. Retains the active Community Patch Worker rules, with +1 Movement and +25% base Work Rate for all ordinary Worker actions, including roads and repairs. Native integer rounding applies.',
 'UNIT_STRATEGY': 'Send Road Crews ahead of expansion to improve resources and connect new cities. Their additional Movement and 25% higher base Work Rate apply throughout their normal Worker duties. They receive no combat bonuses or free roads.',
 'UNIT_PEDIA': 'A Road Crew carries the authority of the Department of Temporary Permanent Works. Its members erect barriers with precision, lay roads with admirable speed and file a separate incident report for every stone. Their speed does not exempt the Union from normal construction requirements or road maintenance.',
 'OFFICE': 'Detour Office',
 'OFFICE_HELP': 'Replaces Walls and retains all active Community Patch Walls benefits and requirements. Adds +1 [ICON_CULTURE] Culture permanently. A connected non-capital city with a real Detour Office also receives +2 [ICON_GOLD] Gold. The Capital never receives this conditional Gold. Connection bonuses follow native network refresh and reconciliation.',
 'OFFICE_STRATEGY': 'Build Detour Offices to defend settlements and gain permanent Culture. Connect non-capital cities to add Gold. A disconnected Office keeps its Culture and inherited Walls benefits. The Capital can build an Office but receives no connection Gold.',
 'OFFICE_PEDIA': 'Every Detour Office contains defensive masonry, a public counter and a registry of roads that may eventually reopen. Its clerks consider a well-posted diversion a cultural achievement. Connected branches collect ordinary administrative fees; the central office is strictly a cost center.',
 'CIV_PEDIA': 'The Conical Union is a society of sentient traffic cones whose administrative competence is matched only by its commitment to road closures. Its citizens regard infrastructure as a public trust and a properly authorized obstruction as a civic virtue.[NEWLINE][NEWLINE]Roads bind its settlements into a productive empire. The Union pays normal upkeep, observes ordinary construction rules and insists that every project carry the correct permit. A closure marked temporary may outlast the civilization that requested it.',
 'LEADER_PEDIA': 'High Marshal Bollard is a towering orange traffic cone decorated with ceremonial reflective stripes. He governs from a throne assembled from discarded traffic signs, where every audience begins with a site-safety briefing.[NEWLINE][NEWLINE]His greatest achievement was keeping the same highway closed for four hundred consecutive years. Successive commissions praised the consistency of the signage. Under his direction, the Union became a remarkably effective state, provided one could reach the appropriate office.',
 'STRATEGY': 'Connect an expanding empire to turn infrastructure into flat Production and Culture. Road Crews develop every normal improvement faster. Detour Offices retain Walls defenses, add permanent Culture and provide conditional Gold outside the Capital. Growth and production support Science or conventional Domination; the civilization has no direct Science or combat bonus. Its starting Capital receives no ability yields, and broken connections disrupt its economy.',
 'DAWN': 'High Marshal Bollard, Supreme Overseer of the Conical Union![NEWLINE][NEWLINE]For centuries, your people have stood proudly upon the roads of the world, directing travelers, protecting construction sites and occasionally causing entirely unnecessary traffic congestion.[NEWLINE][NEWLINE]Now, the cones have awakened.[NEWLINE][NEWLINE]No longer shall your people be moved aside by careless travelers.[NEWLINE][NEWLINE]Build your roads. Establish your offices. Connect the world beneath your glorious orange banners.[NEWLINE][NEWLINE]Will your civilization stand the test of time, or shall it be removed by an irritated construction worker?',
 'DUMMY': 'Connected Administration', 'DUMMY_HELP': 'Automatically maintained connection yields. Cannot be constructed, purchased or sold.',
 'GREETING_1': 'Greetings, traveler. Unfortunately, this diplomatic meeting is taking place within an active construction zone. Please proceed with caution.',
 'WAR_1': 'Your empire has been designated an unauthorized construction project. Demolition begins immediately.',
 'DEFEAT_1': 'After careful consideration... we have decided to reopen the road.',
 'PEACE_1': 'Hostilities are suspended pending final inspection. Please observe the temporary speed limit.',
 'PEACE_OFFER_1': 'The demolition budget has been reviewed. We propose reopening diplomatic access.',
 'FRIENDLY_1': 'Your permit is in order. Welcome back to the approved meeting area.',
 'NEUTRAL_1': 'Take a number. The High Marshal will review your application shortly.',
 'HOSTILE_1': 'Your repeated failure to observe the signage has been entered into the permanent record.',
 'ATTACKED_1': 'This assault has neither planning approval nor a valid traffic management scheme.',
 'TRADE_1': 'All copies have been stamped. The exchange may proceed.',
 'CIV5_HEADING_1': 'A Well-Administered Obstruction',
 'BOLLARD_NAME': 'High Marshal Bollard', 'BOLLARD_SUBTITLE': 'Supreme Overseer of the Conical Union',
 'BOLLARD_LIVED': 'Until further notice', 'BOLLARD_TITLES_1': 'High Marshal and Chief Closure Authority',
 'BOLLARD_HEADING_1': 'Four Hundred Years of Temporary Works',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], BOLLARD_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': name for i, name in enumerate([
 'Inspector Chevron', 'Agent Contraflow', 'Surveyor Plumb', 'Clerk Chicane',
 'Auditor Amber', 'Officer Verge', 'Marshal Taper', 'Warden Kerb',
 'Examiner Median', 'Commissioner Stop'], 1)})

def clone(*args, **kwargs):
    return base_clone(*args, **kwargs).replace('BCClone', 'CONICALClone')

def companions(*args, **kwargs):
    return base_companions(*args, **kwargs).replace('BCCompanion', 'CONICALCompanion')

def main():
    d = database()
    assert {'Moves', 'WorkRate'} <= {r[1] for r in d.execute('PRAGMA table_info(Units)')}
    assert {'BuildingType', 'YieldType', 'Yield'} <= {r[1] for r in d.execute('PRAGMA table_info(Building_YieldChanges)')}
    (V / 'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- BNW + Community Patch v151; append after released civilizations.
-- Only expose verified notification hooks; no CityConnections pathfinding veto.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CITY_CAPITAL','EVENTS_PLAYER_TURN');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_CONICAL_ORANGE',1,0.30,0.035,1),('COLOR_CONICAL_CHARCOAL',0.075,0.09,0.10,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_CONICAL','COLOR_CONICAL_ORANGE','COLOR_CONICAL_CHARCOAL','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_CONICAL_INCONVENIENCE','TXT_KEY_CONICAL_TRAIT_HELP','TXT_KEY_CONICAL_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV,
        Description='TXT_KEY_CONICAL_CIV', ShortDescription='TXT_KEY_CONICAL_SHORT',
        Adjective='TXT_KEY_CONICAL_ADJECTIVE', Civilopedia='TXT_KEY_CONICAL_CIV_PEDIA',
        CivilopediaTag='TXT_KEY_CONICAL_CIV5', Strategy='TXT_KEY_CONICAL_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_CONICAL', Playable=1, AIPlayable=0, PackageID=None,
        DawnOfManQuote='TXT_KEY_CONICAL_DAWN', DawnOfManAudio='', DawnOfManImage='CONICAL_Dawn.dds',
        MapImage='CONICAL_Map.dds', PortraitIndex=0, IconAtlas='CONICAL_CIV_ATLAS', AlphaIconAtlas='CONICAL_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER, Description='TXT_KEY_CONICAL_LEADER',
        Civilopedia='TXT_KEY_CONICAL_LEADER_PEDIA', CivilopediaTag='TXT_KEY_CONICAL_BOLLARD',
        PackageID=None, PortraitIndex=0, IconAtlas='CONICAL_LEADER_ATLAS', ArtDefineTag='CONICAL_LeaderScene.xml')
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_CONICAL_INCONVENIENCE');\n"
    core += clone('Units', 'UNIT_WORKER', UNIT, Description='TXT_KEY_CONICAL_UNIT',
        Civilopedia='TXT_KEY_CONICAL_UNIT_PEDIA', Help='TXT_KEY_CONICAL_UNIT_HELP', Strategy='TXT_KEY_CONICAL_UNIT_STRATEGY',
        IconAtlas='CONICAL_OBJECT_ATLAS', PortraitIndex=1, UnitFlagAtlas='CONICAL_FLAG_ATLAS', UnitFlagIconOffset=0)
    core += f"-- Integer base work rate: CP v151 Worker 100 -> 125, before native shared modifiers.\nUPDATE Units SET Moves=Moves+1,WorkRate=WorkRate*5/4 WHERE Type='{UNIT}';\n"
    core += clone('Buildings', 'BUILDING_WALLS', OFFICE, Description='TXT_KEY_CONICAL_OFFICE',
        Civilopedia='TXT_KEY_CONICAL_OFFICE_PEDIA', Help='TXT_KEY_CONICAL_OFFICE_HELP', Strategy='TXT_KEY_CONICAL_OFFICE_STRATEGY',
        IconAtlas='CONICAL_OBJECT_ATLAS', PortraitIndex=0)
    core += f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_WORKER','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_WALLS','{OFFICE}');\n"
    for i in range(1, len(CITIES) + 1):
        core += f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_CONICAL_CITY_{i}');\n"
    for i in range(1, 11):
        core += f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_CONICAL_SPY_{i}');\n"
    inherit = '-- Runtime copies preserve all active scalar fields and installed companion effects.\n'
    for table in ['Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits']:
        inherit += companions(d, table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    inherit += companions(d, 'Unit', 'UnitType', 'UNIT_WORKER', UNIT)
    inherit += companions(d, 'Building', 'BuildingType', 'BUILDING_WALLS', OFFICE)
    effects = f"""-- Additive: retain any existing Walls Culture, including an absent yield row.
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{OFFICE}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{OFFICE}','YIELD_CULTURE',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{OFFICE}' AND YieldType='YIELD_CULTURE');
"""
    for dummy in [CONNECTION, GOLD]:
        cls = dummy.replace('BUILDING_', 'BUILDINGCLASS_', 1)
        effects += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('{cls}','{dummy}','TXT_KEY_CONICAL_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('{dummy}','{cls}','TXT_KEY_CONICAL_DUMMY','TXT_KEY_CONICAL_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'CONICAL_CIV_ATLAS',0);
"""
    effects += f"""INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES
 ('{CONNECTION}','YIELD_PRODUCTION',2),('{CONNECTION}','YIELD_CULTURE',1),('{GOLD}','YIELD_GOLD',2);
"""
    for response, key in [('FIRST_GREETING', 'GREETING'), ('DECLAREWAR', 'WAR'), ('DEFEATED', 'DEFEAT'),
        ('PEACE_MADE_BY_HUMAN_GRACIOUS', 'PEACE'), ('PEACE_MADE_BY_HUMAN_UNGRACIOUS', 'PEACE'),
        ('PEACE_OFFER', 'PEACE_OFFER'), ('GREETING_POLITE_HELLO', 'FRIENDLY'),
        ('GREETING_NEUTRAL_HELLO', 'NEUTRAL'), ('GREETING_HOSTILE_HELLO', 'HOSTILE'),
        ('ATTACKED', 'ATTACKED'), ('TRADE_ACCEPT_GENEROUS', 'TRADE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_CONICAL_{key}_%',1);\n"
    art = ''
    for atlas, stem, columns in [('CIV', 'Icon', 1), ('ALPHA', 'Alpha', 1), ('OBJECT', 'Objects', 2), ('LEADER', 'Portrait', 1)]:
        for size in [16, 24, 32, 45, 48, 64, 80, 128, 256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('CONICAL_{atlas}_ATLAS',{size},'CONICAL_{stem}{size}.dds',{columns},1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('CONICAL_FLAG_ATLAS',32,'CONICAL_Flag32.dds',1,1);\n"
    text = ''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_CONICAL_" + k + "','" + v.replace("'", "''") + "');\n" for k, v in sorted(TEXT.items()))
    for name, content in [('00_CONICAL_Core', core), ('01_CONICAL_Inheritance', inherit),
                          ('02_CONICAL_Effects', effects), ('03_CONICAL_Art', art), ('10_CONICAL_Text', text)]:
        (V / 'SQL' / (name + '.sql')).write_text(content, encoding='utf-8', newline='\n')
    print('Generated Conical Union identity, runtime Worker/Walls inheritance, two dummies, art and English text')

if __name__ == '__main__':
    main()
