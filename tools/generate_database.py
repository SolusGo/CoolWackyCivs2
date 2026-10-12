"""Generate inherited SQL from the installed CP schema, never from guessed columns."""
from pathlib import Path
from database import database, quote
R = Path(__file__).resolve().parents[1]
V = R / 'TheBoundlessCity'

TEXT = {
 'CIV': 'The Boundless City', 'SHORT': 'The Boundless City', 'ADJECTIVE': 'Boundless',
 'LEADER': 'The First Architect', 'CAPITAL': 'The Heart of the World',
 'TRAIT': 'The World Is One City',
 'TRAIT_HELP': 'Keep only your original capital. Culture funds contiguous frontier expansion without a distance limit. Assign real citizens to distant owned tiles using The Boundless Workforce. Remote workers replace native labourers; their capacity is limited by safely reservable citizens. Military units cannot capture cities. See the civilization guide for engine limitations.',
 'CIV_PEDIA': 'There shall be no second city. For the first shall have no end.[NEWLINE][NEWLINE]The Boundless City measures civilization in streets, bridges and the citizens who walk them. Every new frontier becomes another district of the same capital. Its one production queue and one population remain the price of that ambition.',
 'LEADER_PEDIA': 'The First Architect is an original fictional master builder. Their vision unites settlement, coast and distant island within one continuously growing city. Infrastructure and patient defense matter more than occupation.',
 'STRATEGY': 'Grow your capital, build The Grand Registry, and use Surveyors to develop the frontier. Choose remote tiles in The Boundless Workforce. Science, Culture and Diplomatic victories use normal rules; foreign capitals cannot be occupied for Domination.',
 'DAWN': 'There shall be no second city. For the first shall have no end.[NEWLINE][NEWLINE]First Architect, the foundations are laid. Grow the Heart of the World, send your Surveyors beyond the familiar streets, and let every bridge join another district to your one great city.',
 'REGISTRY': 'The Grand Registry',
 'REGISTRY_HELP': '+3 Culture. +1 additional Culture per 10 owned plots, capped at +10. Reduces the separate frontier Culture cost by 15%. Retains the active Monument rules.',
 'REGISTRY_PEDIA': 'The Grand Registry records each district as part of the same city, whether it lies beside the heart or across a distant sea. The territorial Culture bonus is counted once and never exceeds ten.',
 'REGISTRY_STRATEGY': 'Build early to drive frontier growth and support ordinary Social Policies.',
 'SURVEYOR': 'Frontier Surveyor',
 'SURVEYOR_HELP': 'Replaces Worker. 3 Movement and 125% of the ordinary Worker base work rate. Completing an improvement on an owned plot more than five hexes from the capital grants 5 Culture once per plot per Boundless player. Repairs and routes do not qualify.',
 'SURVEYOR_PEDIA': 'The Frontier Surveyor treats the horizon as another street waiting to be drawn. Surveyors retain the active Worker build permissions, automation roles and upgrade relationships.',
 'SURVEYOR_STRATEGY': 'Develop strong frontier tiles. Distant work still requires citizen reservations; territory alone produces no additional tile yields.',
 'NO_CAPTURE': 'One City, One Heart', 'NO_CAPTURE_HELP': 'Cannot capture enemy cities. The Boundless City cannot safely occupy foreign capitals or additional cities.',
 'WORKFORCE': 'The Boundless Workforce', 'CLOSE': 'Close', 'ASSIGN': 'Assign', 'RELEASE': 'Release',
 'LOCK': 'Lock', 'UNLOCK': 'Unlock', 'PREVIOUS': 'Previous', 'NEXT': 'Next', 'LOCATE': 'Locate',
 'AUTO': 'Automatic', 'MANUAL': 'Manual', 'HYBRID': 'Hybrid',
 'BALANCED': 'Balanced', 'FOOD': 'Food', 'PRODUCTION': 'Production', 'GOLD': 'Gold',
 'SCIENCE': 'Science', 'CULTURE': 'Culture', 'FAITH': 'Faith',
 'DIRECTION': 'Direction', 'ANY': 'Any', 'NORTH': 'North', 'EAST': 'East', 'SOUTH': 'South', 'WEST': 'West',
 'DISTANCE': 'Distance', 'YIELD': 'Yield', 'RESOURCE': 'Resource', 'IMPROVEMENT': 'Improvement',
 'SUMMARY': 'Population: {1_Num} | Owned plots: {2_Num}[NEWLINE]Local workers: {3_Num} | Remote workers: {4_Num} | Specialists: {5_Num} | Idle: {6_Num}[NEWLINE]Free reservations: {7_Num} | Frontier Culture: {8_Num} / {9_Num}',
 'YIELDS': 'Remote plot yields: {1_String}[NEWLINE]Labourer yields removed: {2_String}',
 'CAPACITY': 'Remote reservations are limited to citizens safely withdrawn from native worked tiles. Specialists remain assigned in the city screen. Automatic and Hybrid compare local and distant tiles. See README for the native reservation limit.',
 'UNAVAILABLE': 'This command is unavailable or the plot cannot be reserved.',
 'RECOVERY': 'An additional city was returned to an eligible owner. The Heart remains your only city.',
 'QUARANTINE': 'An unexpected additional city has no safe recipient. Its construction is blocked. See Lua.log and the engine-limitations guide; no protected city was destroyed.',
 'DISABLED': 'The saved Boundless state is invalid or newer than this mod. Remote yields have been removed. Consult Lua.log before continuing.',
 'BONUS': 'Registry territorial Culture', 'BONUS_HELP': 'Automatically maintained by The Grand Registry.',
}
for n in range(1, 11): TEXT['SPY_' + str(n)] = 'Registry Envoy ' + str(n)

def clone(table, old, new, **fields):
    fields = {'ID': None, 'Type': new, **fields}
    def value(v): return 'NULL' if v is None else str(v) if isinstance(v, (int,float)) else "'"+v.replace("'", "''")+"'"
    return (f"CREATE TEMP TABLE BCClone AS SELECT * FROM {quote(table)} WHERE Type='{old}';\n"
            + 'UPDATE BCClone SET ' + ','.join(quote(k)+'='+value(v) for k,v in fields.items())
            + f';\nINSERT INTO {quote(table)} SELECT * FROM BCClone;\nDROP TABLE BCClone;\n')

def companions(d, prefix, col, old, new, skip=()):
    out = []
    for (table,) in d.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").fetchall():
        cols = [r[1] for r in d.execute('PRAGMA table_info('+quote(table)+')')]
        if table.startswith(prefix) and col in cols and table not in skip:
            ids = ',ID=NULL' if 'ID' in cols else ''
            out.append(f"CREATE TEMP TABLE BCCompanion AS SELECT * FROM {quote(table)} WHERE {col}='{old}';\n"
                       f"UPDATE BCCompanion SET {col}='{new}'{ids};\nINSERT INTO {quote(table)} SELECT * FROM BCCompanion;\nDROP TABLE BCCompanion;\n")
    return ''.join(out)

def main():
    d = database(); (V/'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- BNW and CP v151. Event options expose hooks; handlers remain civilization-scoped.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_CITY_FOUNDING','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES',
  'EVENTS_PLOT','EVENTS_TILE_IMPROVEMENTS','EVENTS_PLAYER_TURN');
INSERT INTO Colors VALUES ('COLOR_BC_BLUE',0.035,0.09,0.20,1),('COLOR_BC_GOLD',0.88,0.72,0.35,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_BC','COLOR_BC_BLUE','COLOR_BC_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription,NoAnnexing) VALUES ('TRAIT_BC_ONE_WORLD','TXT_KEY_BC_TRAIT_HELP','TXT_KEY_BC_TRAIT',1);
"""
    # Use explicit columns for Colors: the active database can contain an ID column.
    core = core.replace('INSERT INTO Colors VALUES', 'INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES')
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', 'CIVILIZATION_BOUNDLESS_CITY',
        Description='TXT_KEY_BC_CIV', ShortDescription='TXT_KEY_BC_SHORT', Adjective='TXT_KEY_BC_ADJECTIVE',
        Civilopedia='TXT_KEY_BC_CIV_PEDIA', CivilopediaTag='TXT_KEY_CIV5_BC', Strategy='TXT_KEY_BC_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_BC', Playable=1, AIPlayable=1, PackageID=None,
        DawnOfManQuote='TXT_KEY_BC_DAWN', DawnOfManAudio='', DawnOfManImage='BoundlessDawn.dds',
        MapImage='BoundlessMap.dds', PortraitIndex=0, IconAtlas='BC_CIV_ATLAS', AlphaIconAtlas='BC_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', 'LEADER_BC_ARCHITECT',
        Description='TXT_KEY_BC_LEADER', Civilopedia='TXT_KEY_BC_LEADER_PEDIA',
        CivilopediaTag='TXT_KEY_CIVILOPEDIA_LEADERS_BC_ARCHITECT', PackageID=None,
        Boldness=3, VictoryCompetitiveness=6, WonderCompetitiveness=7, MinorCivCompetitiveness=7,
        WarmongerHate=9, DoFWillingness=7, Loyalty=8, Meanness=2,
        PortraitIndex=0, IconAtlas='BC_LEADER_ATLAS', ArtDefineTag='BoundlessLeaderScene.xml')
    core += "INSERT INTO Civilization_Leaders VALUES ('CIVILIZATION_BOUNDLESS_CITY','LEADER_BC_ARCHITECT');\nINSERT INTO Leader_Traits VALUES ('LEADER_BC_ARCHITECT','TRAIT_BC_ONE_WORLD');\n"
    worker = d.execute("SELECT WorkRate FROM Units WHERE Type='UNIT_WORKER'").fetchone()[0]
    core += clone('Units','UNIT_WORKER','UNIT_BC_SURVEYOR', Moves=3, WorkRate=int(worker*1.25),
        Description='TXT_KEY_BC_SURVEYOR',Civilopedia='TXT_KEY_BC_SURVEYOR_PEDIA',Help='TXT_KEY_BC_SURVEYOR_HELP',
        Strategy='TXT_KEY_BC_SURVEYOR_STRATEGY',IconAtlas='BC_OBJECT_ATLAS',PortraitIndex=1,
        UnitFlagAtlas='BC_FLAG_ATLAS',UnitFlagIconOffset=0)
    core += clone('Buildings','BUILDING_MONUMENT','BUILDING_BC_REGISTRY',
        Description='TXT_KEY_BC_REGISTRY',Civilopedia='TXT_KEY_BC_REGISTRY_PEDIA',Help='TXT_KEY_BC_REGISTRY_HELP',
        Strategy='TXT_KEY_BC_REGISTRY_STRATEGY',IconAtlas='BC_OBJECT_ATLAS',PortraitIndex=0)
    core += """INSERT INTO Civilization_UnitClassOverrides VALUES ('CIVILIZATION_BOUNDLESS_CITY','UNITCLASS_WORKER','UNIT_BC_SURVEYOR');
INSERT INTO Civilization_BuildingClassOverrides VALUES ('CIVILIZATION_BOUNDLESS_CITY','BUILDINGCLASS_MONUMENT','BUILDING_BC_REGISTRY');
INSERT INTO Civilization_CityNames VALUES ('CIVILIZATION_BOUNDLESS_CITY','TXT_KEY_BC_CAPITAL');
INSERT INTO UnitPromotions(Type,Description,Help,NoCapture,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas)
 VALUES ('PROMOTION_BC_NO_CAPTURE','TXT_KEY_BC_NO_CAPTURE','TXT_KEY_BC_NO_CAPTURE_HELP',1,1,0,0,'BC_CIV_ATLAS');
"""
    for n in range(1,11): core += f"INSERT INTO Civilization_SpyNames VALUES ('CIVILIZATION_BOUNDLESS_CITY','TXT_KEY_BC_SPY_{n}');\n"
    inherit = companions(d,'Leader_','LeaderType','LEADER_WASHINGTON','LEADER_BC_ARCHITECT',('Leader_Traits',))
    for t in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit += companions(d,t,'CivilizationType','CIVILIZATION_AMERICA','CIVILIZATION_BOUNDLESS_CITY')
    inherit += companions(d,'Unit_','UnitType','UNIT_WORKER','UNIT_BC_SURVEYOR')
    inherit += companions(d,'Building_','BuildingType','BUILDING_MONUMENT','BUILDING_BC_REGISTRY')
    effects = """DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_BC_REGISTRY' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges VALUES ('BUILDING_BC_REGISTRY','YIELD_CULTURE',3);
UPDATE Leader_Flavors SET Flavor=9 WHERE LeaderType='LEADER_BC_ARCHITECT' AND FlavorType IN ('FLAVOR_GROWTH','FLAVOR_TILE_IMPROVEMENT','FLAVOR_DEFENSE','FLAVOR_CULTURE');
UPDATE Leader_Flavors SET Flavor=0 WHERE LeaderType='LEADER_BC_ARCHITECT' AND FlavorType='FLAVOR_EXPANSION';
UPDATE Leader_Flavors SET Flavor=7 WHERE LeaderType='LEADER_BC_ARCHITECT' AND FlavorType IN ('FLAVOR_PRODUCTION','FLAVOR_SCIENCE','FLAVOR_WONDER');
"""
    # Ten separate nonstacking bits avoid relying on a building-count yield multiplier.
    for n in range(1,11):
        effects += f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_BC_REGISTRY_{n}','BUILDING_BC_REGISTRY_{n}','TXT_KEY_BC_BONUS');\n"
        effects += f"INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IconAtlas,PortraitIndex) VALUES ('BUILDING_BC_REGISTRY_{n}','BUILDINGCLASS_BC_REGISTRY_{n}','TXT_KEY_BC_BONUS','TXT_KEY_BC_BONUS_HELP',-1,-1,-1,1,1,'BC_OBJECT_ATLAS',0);\n"
        effects += f"INSERT INTO Building_YieldChanges VALUES ('BUILDING_BC_REGISTRY_{n}','YIELD_CULTURE',1);\n"
    art = ''
    for atlas, stem, columns in [('BC_CIV_ATLAS','BoundlessIcon',1),('BC_ALPHA_ATLAS','BoundlessAlpha',1),('BC_OBJECT_ATLAS','BoundlessObjects',2)]:
        for size in [16,24,32,45,48,64,80,128,256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('{atlas}',{size},'{stem}{size}.dds',{columns},1);\n"
    for size in [64,128,256]: art += f"INSERT INTO IconTextureAtlases VALUES ('BC_LEADER_ATLAS',{size},'BoundlessPortrait{size}.dds',1,1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('BC_FLAG_ATLAS',32,'BoundlessFlag32.dds',1,1);\n"
    text = '\n'.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_BC_"+k+"','"+v.replace("'","''")+"');" for k,v in sorted(TEXT.items()))+'\n'
    for name, content in [('00_BC_Core',core),('01_BC_Inheritance',inherit),('02_BC_Effects',effects),('03_BC_Art',art),('10_BC_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content,encoding='utf-8')
    print('Generated inherited civilization, Worker, Monument, art and localization SQL')

if __name__ == '__main__': main()
