"""Generate Unrung Bell SQL from the installed BNW/CP v151 schema.

SELECT * clones run at activation; no baseline stats are frozen here.
"""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'KingdomOfTheUnrungBell'
CIV = 'CIVILIZATION_UNRUNG_BELL'
LEADER = 'LEADER_UNRUNG_SABLE'
UNIT = 'UNIT_UNRUNG_BELLWARDEN'
BELFRY = 'BUILDING_UNRUNG_SILENT_BELFRY'
GUARD = 'PROMOTION_UNRUNG_BELLWARDEN'
TIERS = ['I', 'II', 'III']
CITIES = ['Stillhaven', 'Hushmere', 'Silver Vigil', 'Vowrest', 'Quietwatch',
          'Hollow Chime', 'Veilhaven', 'Silentreach', 'Grey Sanctuary',
          'Stillwater Abbey', 'Mournspire', 'Duskwatch', 'Pale Cloister',
          "Echo's End", 'Last Resonance', 'Chainfall', 'Vesper Gate',
          'Ashen Chapter', 'Moonlit Vigil', 'Oathdeep', 'Whisperwell',
          'Resting Peal', 'Sable Crossing', 'The Unspoken Court']
TEXT = {
 'CIV': 'The Kingdom of the Unrung Bell', 'SHORT': 'Unrung Bell', 'ADJECTIVE': 'Unrung',
 'LEADER': 'Keeper Sable', 'TRAIT': 'Silence Before the Storm',
 'TRAIT_HELP': 'Every 5 consecutive peaceful owner-turns earn Quietude (maximum 3): +1 [ICON_CULTURE] Culture per city per stack. War with a civilization or city-state consumes Quietude for the Great Toll: +5%/+10%/+15% friendly-land combat for land military units through the next 5 full owner-turn windows. Additional wars never refresh it; complete peace ends it. Barbarians do not interrupt peace. CP friendly lands include open borders; ranged attacks check the shooter tile. See guide.',
 'UNIT': 'Bellwarden',
 'UNIT_HELP': 'Replaces Pikeman; retains the active CP Pikeman properties. Permanent +1 Sight and +15% friendly-land Combat Strength, retained on upgrade. Stacks additively with the Great Toll. CP friendly lands include open-border territory; ranged upgrades check their own tile.',
 'UNIT_STRATEGY': 'Guard the kingdom with Bellwardens while Quietude grows. Their inherited Pikeman training, additional Sight and permanent friendly-land bonus support defense. Upgrade normally without losing the unique promotion. During Great Toll III their two unique modifiers total +30%.',
 'UNIT_PEDIA': 'The Bellwardens are the sworn military order of the sacred towers. Each learns to read a horizon before drawing a weapon, and each knows the chain that must be broken only once. Their pikes and armor follow ordinary Pikeman models; their long vigil survives every later change of equipment.',
 'BELFRY': 'Silent Belfry',
 'BELFRY_HELP': 'Replaces Temple; retains all active CP Temple benefits and requirements. Adds +1 [ICON_CULTURE] Culture permanently and +1 [ICON_RESEARCH] Science per current Quietude stack (maximum +3). War removes conditional Science but keeps permanent Culture. Requires a Silent Belfry, not an ordinary Temple.',
 'BELFRY_STRATEGY': 'Build Silent Belfries during peace to turn Quietude into Science. At three stacks, a city with a Belfry gains +4 Culture and +3 Science beyond the ordinary Temple: +3 Culture from the ability, +1 permanent Culture and +3 conditional Science from the Belfry. War trades the peaceful economy for temporary defense.',
 'BELFRY_PEDIA': 'A Silent Belfry is a temple built around an instrument that must never sound. Scholars work in its shadow; children learn its vow before they learn its history. The smallest bell is wrapped in felt. The greatest is bound with chains forged by generations who hoped never to see them removed.',
 'CIV_PEDIA': 'The Kingdom of the Unrung Bell is an original fictional civilization shaped by a terrible memory. Its ancestors survived an age of wars that ended when the Great Bell sounded. No chronicle agrees on what the sound did. All agree that the survivors vowed never to hear it again.[NEWLINE][NEWLINE]Stillhaven grew around the silent cathedral. Across the kingdom, contemplation became an institution: cloisters preserved learning, belfries supported scholars, and disciplined wardens guarded a peace measured in generations. Their prosperity rests on patience. Their last defense rests on breaking their oldest promise.',
 'LEADER_PEDIA': 'Keeper Sable is the elderly Guardian of the Eternal Silence. Beneath black robes embroidered with silver bells she carries the keys to the cathedral chains. She governs through measured counsel, grants long audiences to scholars and answers military threats with few words.[NEWLINE][NEWLINE]Sable knows that a vow can protect a people only while the people survive to keep it. Her solemn authority comes from accepting responsibility for the one command she hopes never to give.',
 'STRATEGY': 'An advanced, human-only Culture / Science civilization. Complete five uninterrupted peaceful owner-turns per Quietude stack, up to three. Expand to spread Culture and build Silent Belfries for Science. A qualifying war immediately consumes the economy for a five-window land defense surge. Defend patiently; additional declarations cannot renew the Toll. Complete peace is necessary before Quietude can grow again.',
 'DAWN': 'Keeper Sable, Guardian of the Eternal Silence, your people await your wisdom.[NEWLINE][NEWLINE]Long ago, your ancestors lived beneath the shadow of endless war. Kingdoms rose and fell, armies marched across the earth, and the cries of the dying echoed through every valley.[NEWLINE][NEWLINE]Then came the Great Bell.[NEWLINE][NEWLINE]Its terrible sound brought the age of bloodshed to an end.[NEWLINE][NEWLINE]From that day forward, your people swore that it would never ring again.[NEWLINE][NEWLINE]Generations passed. The kingdom prospered. Its people learned to value knowledge, patience and the quiet beauty of peace.[NEWLINE][NEWLINE]But beyond your borders, the world remains restless.[NEWLINE][NEWLINE]Raise your Silent Belfries. Guard your sacred vow. Let wisdom flourish where violence once prevailed.[NEWLINE][NEWLINE]And should the world threaten your people once more...[NEWLINE][NEWLINE]May they never hear the bell.',
 'GUARD': 'Vigil of the Bell', 'GUARD_HELP': '+1 Sight and +15% friendly-land Combat Strength. Retained on upgrade. CP friendly lands include open borders; ranged attacks check the shooter tile.',
 'DUMMY': 'Quietude', 'DUMMY_HELP': 'Automatic peaceful city yield. Cannot be constructed or purchased.',
 'GREETING_1': 'Welcome, traveler. Speak softly. Some things in this world are better left undisturbed.',
 'WAR_1': 'You have mistaken our silence for weakness. That was your final mistake.',
 'ATTACKED_1': 'The chains have been removed.', 'DEFEAT_1': 'At last... silence.',
 'PEACE_1': 'Let the chains be fastened once more.',
 'FRIENDLY_1': 'There is room for you beside the quiet fire.',
 'NEUTRAL_1': 'The Keeper is listening.', 'HOSTILE_1': 'Your footsteps disturb the cloister.',
 'TRADE_1': 'Let this agreement be kept without fanfare.',
 'CIV5_HEADING_1': 'The Vow of Stillhaven',
 'SABLE_NAME': 'Keeper Sable', 'SABLE_SUBTITLE': 'Guardian of the Eternal Silence',
 'SABLE_LIVED': 'In the long vigil', 'SABLE_TITLES_1': 'Keeper of the Great Bell',
 'SABLE_HEADING_1': 'The Keeper and the Keys',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], SABLE_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': name for i, name in enumerate(['Vesper', 'Grey Veil', 'Still Quill', 'Ash Vow', 'Pale Key', 'Hushed Step', 'Silver Thread', 'Last Candle', 'Night Cloister', 'Quiet Hand'], 1)})
for i, tier in enumerate(TIERS, 1):
    TEXT['TOLL_' + tier] = 'The Great Toll ' + tier
    TEXT['TOLL_' + tier + '_HELP'] = f'+{i*5}% friendly-land Combat Strength during the Great Toll. Ends at complete peace or after five full owner-turn windows. CP friendly lands include open borders; ranged attacks check the shooter tile.'

def clone(*a, **kw): return base_clone(*a, **kw).replace('BCClone', 'UNRUNGClone')
def companions(*a, **kw): return base_companions(*a, **kw).replace('BCCompanion', 'UNRUNGCompanion')

def main():
    d = database()
    assert {'FriendlyLandsModifier', 'VisibilityChange', 'LostWithUpgrade'} <= {r[1] for r in d.execute('PRAGMA table_info(UnitPromotions)')}
    (V/'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- Event switches expose notifications only; handlers are civilization-scoped.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_PLAYER_TURN','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES','EVENTS_CITY','EVENTS_CITY_FOUNDING');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_UNRUNG_NAVY',0.035,0.06,0.12,1),('COLOR_UNRUNG_SILVER',0.74,0.77,0.81,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_UNRUNG','COLOR_UNRUNG_SILVER','COLOR_UNRUNG_NAVY','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_UNRUNG_SILENCE','TXT_KEY_UNRUNG_TRAIT_HELP','TXT_KEY_UNRUNG_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV, Description='TXT_KEY_UNRUNG_CIV', ShortDescription='TXT_KEY_UNRUNG_SHORT', Adjective='TXT_KEY_UNRUNG_ADJECTIVE', Civilopedia='TXT_KEY_UNRUNG_CIV_PEDIA', CivilopediaTag='TXT_KEY_UNRUNG_CIV5', Strategy='TXT_KEY_UNRUNG_STRATEGY', DefaultPlayerColor='PLAYERCOLOR_UNRUNG', Playable=1, AIPlayable=0, PackageID=None, DawnOfManQuote='TXT_KEY_UNRUNG_DAWN', DawnOfManAudio='', DawnOfManImage='UNRUNG_Dawn.dds', MapImage='UNRUNG_Map.dds', PortraitIndex=0, IconAtlas='UNRUNG_CIV_ATLAS', AlphaIconAtlas='UNRUNG_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER, Description='TXT_KEY_UNRUNG_LEADER', Civilopedia='TXT_KEY_UNRUNG_LEADER_PEDIA', CivilopediaTag='TXT_KEY_UNRUNG_SABLE', PackageID=None, PortraitIndex=0, IconAtlas='UNRUNG_LEADER_ATLAS', ArtDefineTag='UNRUNG_LeaderScene.xml')
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_UNRUNG_SILENCE');\n"
    core += clone('Units', 'UNIT_PIKEMAN', UNIT, Description='TXT_KEY_UNRUNG_UNIT', Civilopedia='TXT_KEY_UNRUNG_UNIT_PEDIA', Help='TXT_KEY_UNRUNG_UNIT_HELP', Strategy='TXT_KEY_UNRUNG_UNIT_STRATEGY', IconAtlas='UNRUNG_OBJECT_ATLAS', PortraitIndex=1)
    core += clone('Buildings', 'BUILDING_TEMPLE', BELFRY, Description='TXT_KEY_UNRUNG_BELFRY', Civilopedia='TXT_KEY_UNRUNG_BELFRY_PEDIA', Help='TXT_KEY_UNRUNG_BELFRY_HELP', Strategy='TXT_KEY_UNRUNG_BELFRY_STRATEGY', IconAtlas='UNRUNG_OBJECT_ATLAS', PortraitIndex=0)
    core += f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_PIKEMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_TEMPLE','{BELFRY}');\n"
    for table, count in [('City', len(CITIES)), ('Spy', 10)]:
        for i in range(1, count+1):
            core += f"INSERT INTO Civilization_{table}Names VALUES ('{CIV}','TXT_KEY_UNRUNG_{table.upper()}_{i}');\n"
    inherit = '-- Enumerated installed companion tables; contents copied at activation.\n'
    for table in ['Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits']:
        inherit += companions(d, table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    inherit += companions(d, 'Unit', 'UnitType', 'UNIT_PIKEMAN', UNIT)
    inherit += companions(d, 'Building', 'BuildingType', 'BUILDING_TEMPLE', BELFRY)
    effects = f"""-- Native territory modifier: see documented CP ownership/ranged limitations.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,VisibilityChange,FriendlyLandsModifier,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('{GUARD}','TXT_KEY_UNRUNG_GUARD','TXT_KEY_UNRUNG_GUARD_HELP','AS2D_IF_LEVELUP',1,0,1,15,0,'UNRUNG_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_UNRUNG_GUARD');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','{GUARD}');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{BELFRY}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{BELFRY}','YIELD_CULTURE',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{BELFRY}' AND YieldType='YIELD_CULTURE');
"""
    for i, tier in enumerate(TIERS, 1):
        effects += f"INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,FriendlyLandsModifier,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('PROMOTION_UNRUNG_GREAT_TOLL_{tier}','TXT_KEY_UNRUNG_TOLL_{tier}','TXT_KEY_UNRUNG_TOLL_{tier}_HELP','AS2D_IF_LEVELUP',1,1,{i*5},{i},'UNRUNG_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_UNRUNG_TOLL_{tier}');\n"
        for kind, yield_type in [('QUIETUDE', 'CULTURE'), ('SCIENCE', 'SCIENCE')]:
            dummy = f'BUILDING_UNRUNG_{kind}_{tier}'
            cls = dummy.replace('BUILDING_', 'BUILDINGCLASS_', 1)
            effects += f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('{cls}','{dummy}','TXT_KEY_UNRUNG_DUMMY');\n"
            effects += f"INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex) VALUES ('{dummy}','{cls}','TXT_KEY_UNRUNG_DUMMY','TXT_KEY_UNRUNG_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'UNRUNG_CIV_ATLAS',0);\n"
            effects += f"INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('{dummy}','YIELD_{yield_type}',1);\n"
    for response, key in [('FIRST_GREETING','GREETING'), ('DECLAREWAR','WAR'), ('ATTACKED','ATTACKED'), ('DEFEATED','DEFEAT'), ('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'), ('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'), ('PEACE_OFFER','PEACE'), ('GREETING_POLITE_HELLO','FRIENDLY'), ('GREETING_NEUTRAL_HELLO','NEUTRAL'), ('GREETING_HOSTILE_HELLO','HOSTILE'), ('TRADE_ACCEPT_GENEROUS','TRADE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_UNRUNG_{key}_%',1);\n"
    art = ''
    for atlas, stem, columns in [('CIV','Icon',1), ('ALPHA','Alpha',1), ('OBJECT','Objects',2), ('LEADER','Portrait',1), ('PROMOTION','Promotions',4)]:
        for size in [16,24,32,45,48,64,80,128,256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('UNRUNG_{atlas}_ATLAS',{size},'UNRUNG_{stem}{size}.dds',{columns},1);\n"
    text = ''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_UNRUNG_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name, content in [('00_UNRUNG_Core',core), ('01_UNRUNG_Inheritance',inherit), ('02_UNRUNG_Effects',effects), ('03_UNRUNG_Art',art), ('10_UNRUNG_Text',text)]:
        (V/'SQL'/(name+'.sql')).write_text(content, encoding='utf-8', newline='\n')
    print('Generated human-only Unrung Bell, active Pikeman/Temple inheritance, six binary yield buildings and four promotions')

if __name__ == '__main__': main()
