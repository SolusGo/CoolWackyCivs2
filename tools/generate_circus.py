"""Schema-derived Wandering Circus SQL; inherits active definitions at activation."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R/'TheWanderingCircus'
CIV = 'CIVILIZATION_WCIRCUS'
LEADER = 'LEADER_WCIRCUS_AURELIO'
UNIT = 'UNIT_WCIRCUS_CARNIVAL_CREW'
OFFICE = 'BUILDING_WCIRCUS_TICKET_OFFICE'
DUMMIES = ['FESTIVAL_YIELDS', 'TICKET_PRODUCTION', 'EXPIRATION', 'NEXT_ELIGIBLE', 'PENDING_START', 'STAGED_TURN']
CITIES = ['Grand Pavilion', 'Laughing Hollow', 'Golden Tent', 'Moonlit Stage', 'Velvet Arcade',
          'Lantern Square', "Ringmaster's Rest", 'Starlight Fair', "Tumbler's Crossing", 'Highwire Haven',
          'Jubilee Fields', 'Silver Carousel', 'Masquerade Point', 'Festival Hollow', 'Brightwater Fair',
          'Firelight Grove', 'Marvelous Mile', 'Crimson Canopy', 'Encore Harbor', 'Wonderwick',
          'Golden Carousel', 'Moonbeam Circus', 'Mirthborough', 'Final Encore']
TEXT = {
 'CIV':'The Wandering Circus', 'SHORT':'The Wandering Circus', 'ADJECTIVE':'Circus',
 'LEADER':'Ringmaster Aurelio', 'TRAIT':'The Show Must Go On',
 'TRAIT_HELP':'A Carnival Crew ending its turn in your city can begin a Grand Festival at the start of your next turn. Each city gains +3 [ICON_CULTURE] Culture and +2 [ICON_GOLD] Gold for exactly 3 owner-turns. A city may begin another festival 12 owner-turns after its previous start. Crews are not consumed; multiple Crews do not stack.',
 'UNIT':'Carnival Crew',
 'UNIT_HELP':'Replaces Worker, retaining all its normal Community Patch properties and build actions. +1 [ICON_MOVES] Movement compared with the active Worker. End a turn in one of your cities to prepare a Grand Festival for your next turn, if that city is eligible. The Crew is not consumed and may leave after activation.',
 'UNIT_STRATEGY':'Balance improvement work against local performances. Move into a city before ending your turn; passing through it is insufficient. Once its festival has begun, return to the fields or travel to another city. Work Rate remains the normal Worker rate.',
 'UNIT_PEDIA':'Stagehands build roads as readily as stages. The Carnival Crew carry tools, canvas, lanterns and instruments between settlements, repairing bridges in the morning and raising a pavilion at dusk. They are civilian Workers with the active Community Patch construction rules and a little more movement. Their performances require a city, not a special build action. The standard Worker model represents them on the map.',
 'OFFICE':'Ticket Office',
 'OFFICE_HELP':'Replaces Market, retaining all its normal Community Patch benefits. Adds +1 [ICON_CULTURE] Culture permanently. During this city\'s Grand Festival only, adds +2 flat [ICON_PRODUCTION] Production. This bonus never stacks with additional Carnival Crews.',
 'OFFICE_STRATEGY':'Raise Ticket Offices in cities that regularly welcome Carnival Crews. Their Market benefits and extra Culture are permanent; their additional Production lasts only while the local festival is active. Building an Office during a festival enables its Production for the remaining festival.',
 'OFFICE_PEDIA':'At the Ticket Office, the price of admission becomes a promise of wonder. Clerks arrange seating, merchants rent stalls and apprentices learn to keep accounts beside playbills. These small institutions preserve all the commercial functions of a Market. During a Grand Festival their coordinated deliveries also support the city\'s workshops.',
 'CIV_PEDIA':'The Wandering Circus is an original fictional civilization of performers, acrobats, musicians, stagehands and merchants. It began as a loose alliance of caravans that shared shelter and water at a crossroads. When winter held them there, their temporary pavilion became a school, a market and eventually a capital.[NEWLINE][NEWLINE]The Grand Pavilion remains a meeting place for travelers. Other settlements grew beside fairgrounds and river crossings, linked by roads built by the same crews who raised their stages. A festival belongs to its host city: when one city rests, another may be preparing its opening night.[NEWLINE][NEWLINE]Their history is a story of patient labor behind public delight. The roads must be repaired, the accounts balanced and the fields tended before a curtain can rise. Their people find dignity in that preparation and in the joy it makes possible.',
 'LEADER_PEDIA':'Aurelio first traveled with the circus as a lantern keeper. He learned the names of every performer, the carrying capacity of every wagon and the art of turning a delayed opening into a memorable welcome. Chosen to mediate between rival companies, he became the first Ringmaster of the Grand Pavilion.[NEWLINE][NEWLINE]His elaborate crimson coat, black top hat and golden gloves are ceremonial tools of an exacting host. Behind his theatrical greetings lies a curious and commercially minded organizer. He funds schools beside stages and welcomes foreign merchants, believing that a prosperous neighbor makes a better audience. When threatened, his warmth becomes a public promise to protect his people.',
 'STRATEGY':'Pursue Culture through local Grand Festivals and permanent Ticket Office Culture, with Science as a secondary path supported by a healthy economy. Rotate Carnival Crews between infrastructure work and performances. Each city has its own three-turn festival and twelve-turn interval between starts; a stationed Crew automatically prepares the next eligible show. Growth and additional cities can support more simultaneous festivals, but each stationed Crew is time away from improvements.',
 'DAWN':'Magnificent Ringmaster Aurelio, the world awaits your greatest performance![NEWLINE][NEWLINE]Throughout history, kings have raised armies, emperors have constructed monuments, and scholars have sought the mysteries of existence.[NEWLINE][NEWLINE]But your people have discovered something equally powerful.[NEWLINE][NEWLINE]Joy.[NEWLINE][NEWLINE]Your traveling performers have crossed mountains, deserts and oceans, bringing laughter to those who have forgotten how to smile.[NEWLINE][NEWLINE]Now, the greatest stage of all awaits you.[NEWLINE][NEWLINE]Raise your tents. Gather your performers. Let every city hear the sound of celebration.[NEWLINE][NEWLINE]Will your civilization become the greatest spectacle the world has ever witnessed?',
 'GREETING_1':'Welcome, welcome! A thousand greetings to our distinguished guest! Tell me, have you come for diplomacy, or would you prefer front-row seats?',
 'WAR_1':'Ladies and gentlemen! For our next spectacular performance... THE FALL OF AN EMPIRE!',
 'DEFEAT_1':'The lights grow dim... the audience departs... but somewhere, someday, the show will begin again.',
 'PEACE_1':'Let the drums fall silent and the lanterns shine again. There is room beneath our canopy for peace.',
 'PEACE_OFFER_1':'We have both given war its dreadful encore. Shall we close this act and begin a kinder one?',
 'FRIENDLY_1':'A familiar face! Come in, my friend. The finest seat in the pavilion is yours.',
 'NEUTRAL_1':'The curtain is raised, and I am listening. What business brings you to our stage?',
 'HOSTILE_1':'You arrive to a rather quiet audience today. Speak plainly; our patience has limits.',
 'ATTACKED_1':'You mistake kindness for an unguarded gate. Our people will stand together.',
 'TRADE_1':'A fair exchange deserves applause. Let us give our merchants something to celebrate.',
 'DUMMY':'Grand Festival', 'DUMMY_HELP':'Automatically maintained circus state. Cannot be built, purchased, sold or transferred.',
 'CIV5_HEADING_1':'A Civilization Beneath the Canopy',
 'AURELIO_NAME':'Ringmaster Aurelio', 'AURELIO_SUBTITLE':'Host of the Grand Pavilion',
 'AURELIO_LIVED':'The Age of Traveling Wonders', 'AURELIO_TITLES_1':'Ringmaster Aurelio',
 'AURELIO_HEADING_1':'The Lantern Keeper Who Became a Leader',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], AURELIO_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i,name in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}': name for i,name in enumerate(['Velvet Whisper','False Bottom','Quiet Encore','Silver Wire','Hidden Lantern','Painted Smile','Midnight Ticket','Scarlet Ribbon','Vanishing Act','Last Bow'],1)})

def clone(*args, **kwargs):
    return base_clone(*args, **kwargs).replace('BCClone','WCIRCUSClone')

def companions(*args, **kwargs):
    return base_companions(*args, **kwargs).replace('BCCompanion','WCIRCUSCompanion')

def main():
    d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True)
    core="""-- CP v151 turn-end staging is required BEFORE native next-turn economics.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_PLAYER_TURN','EVENTS_CITY');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_WCIRCUS_CRIMSON',0.53,0.035,0.10,1),('COLOR_WCIRCUS_GOLD',0.94,0.73,0.31,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_WCIRCUS','COLOR_WCIRCUS_CRIMSON','COLOR_WCIRCUS_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_WCIRCUS_SHOW_MUST_GO_ON','TXT_KEY_WCIRCUS_TRAIT_HELP','TXT_KEY_WCIRCUS_TRAIT');
"""
    core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_WCIRCUS_CIV',ShortDescription='TXT_KEY_WCIRCUS_SHORT',Adjective='TXT_KEY_WCIRCUS_ADJECTIVE',Civilopedia='TXT_KEY_WCIRCUS_CIV_PEDIA',CivilopediaTag='TXT_KEY_WCIRCUS_CIV5',Strategy='TXT_KEY_WCIRCUS_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_WCIRCUS',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_WCIRCUS_DAWN',DawnOfManAudio='',DawnOfManImage='WCIRCUS_Dawn.dds',MapImage='WCIRCUS_Map.dds',PortraitIndex=0,IconAtlas='WCIRCUS_CIV_ATLAS',AlphaIconAtlas='WCIRCUS_ALPHA_ATLAS')
    core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_WCIRCUS_LEADER',Civilopedia='TXT_KEY_WCIRCUS_LEADER_PEDIA',CivilopediaTag='TXT_KEY_WCIRCUS_AURELIO',PackageID=None,PortraitIndex=0,IconAtlas='WCIRCUS_LEADER_ATLAS',ArtDefineTag='WCIRCUS_LeaderScene.xml',DoFWillingness=8,DiploBalance=7,Loyalty=7,Chattiness=8,Meanness=2)
    core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_WCIRCUS_SHOW_MUST_GO_ON');\n"
    core+=clone('Units','UNIT_WORKER',UNIT,Description='TXT_KEY_WCIRCUS_UNIT',Civilopedia='TXT_KEY_WCIRCUS_UNIT_PEDIA',Help='TXT_KEY_WCIRCUS_UNIT_HELP',Strategy='TXT_KEY_WCIRCUS_UNIT_STRATEGY',IconAtlas='WCIRCUS_OBJECT_ATLAS',PortraitIndex=1,UnitFlagAtlas='WCIRCUS_FLAG_ATLAS',UnitFlagIconOffset=0)
    core+=f"UPDATE Units SET Moves=Moves+1 WHERE Type='{UNIT}';\n"
    core+=clone('Buildings','BUILDING_MARKET',OFFICE,Description='TXT_KEY_WCIRCUS_OFFICE',Civilopedia='TXT_KEY_WCIRCUS_OFFICE_PEDIA',Help='TXT_KEY_WCIRCUS_OFFICE_HELP',Strategy='TXT_KEY_WCIRCUS_OFFICE_STRATEGY',IconAtlas='WCIRCUS_OBJECT_ATLAS',PortraitIndex=0)
    core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_WORKER','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_MARKET','{OFFICE}');\n"
    for i in range(1,len(CITIES)+1): core+=f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_WCIRCUS_CITY_{i}');\n"
    for i in range(1,11): core+=f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_WCIRCUS_SPY_{i}');\n"
    inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON',LEADER,('Leader_Traits',))
    for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
    inherit+=companions(d,'Unit_','UnitType','UNIT_WORKER',UNIT)
    inherit+=companions(d,'Building_','BuildingType','BUILDING_MARKET',OFFICE)
    effects=f"""UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{OFFICE}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{OFFICE}','YIELD_CULTURE',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{OFFICE}' AND YieldType='YIELD_CULTURE');
"""
    for suffix in DUMMIES:
        effects+=f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_WCIRCUS_{suffix}','BUILDING_WCIRCUS_{suffix}','TXT_KEY_WCIRCUS_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_WCIRCUS_{suffix}','BUILDINGCLASS_WCIRCUS_{suffix}','TXT_KEY_WCIRCUS_DUMMY','TXT_KEY_WCIRCUS_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'WCIRCUS_CIV_ATLAS',0);
"""
    effects+="""INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES
 ('BUILDING_WCIRCUS_FESTIVAL_YIELDS','YIELD_CULTURE',3),
 ('BUILDING_WCIRCUS_FESTIVAL_YIELDS','YIELD_GOLD',2),
 ('BUILDING_WCIRCUS_TICKET_PRODUCTION','YIELD_PRODUCTION',2);
"""
    for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('ATTACKED','ATTACKED'),('TRADE_ACCEPT_GENEROUS','TRADE')]:
        effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_WCIRCUS_{key}_%',1);\n"
    # Independent personality/flavor rows; no native leader is changed.
    effects+=f"UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_CULTURE','FLAVOR_GOLD','FLAVOR_SCIENCE');\n"
    effects+=f"UPDATE Leader_MajorCivApproachBiases SET Bias=8 WHERE LeaderType='{LEADER}' AND MajorCivApproachType='MAJOR_CIV_APPROACH_FRIENDLY';\n"
    art=''
    for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2),('LEADER','Portrait',1)]:
        for size in [16,24,32,45,48,64,80,128,256]: art+=f"INSERT INTO IconTextureAtlases VALUES ('WCIRCUS_{atlas}_ATLAS',{size},'WCIRCUS_{stem}{size}.dds',{cols},1);\n"
    art+="INSERT INTO IconTextureAtlases VALUES ('WCIRCUS_FLAG_ATLAS',32,'WCIRCUS_Flag32.dds',1,1);\n"
    text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_WCIRCUS_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name,content in [('00_WCIRCUS_Core',core),('01_WCIRCUS_Inheritance',inherit),('02_WCIRCUS_Effects',effects),('03_WCIRCUS_Art',art),('10_WCIRCUS_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content,encoding='utf-8',newline='\n')
    print('Generated Wandering Circus identity, active Worker/Market inheritance, six dummies, art and English text')

if __name__=='__main__': main()
