"""Regenerate McPvP SQL using the installed BNW/CP v151 schema."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'McPvP'
CIV, LEADER = 'CIVILIZATION_MCPVP', 'LEADER_MCPVP_OLD_GUARD'
UNIT, HUB = 'UNIT_MCPVP_VETERAN', 'BUILDING_MCPVP_HUB'
KITS = {
 'KANGAROO': ('Kangaroo', '+1 land Movement; -10% defensive Combat Strength.'),
 'STOMPER': ('Stomper', 'From a hill, deal 20 damage to one adjacent visible enemy land military unit on flat ground. Consumes movement. Five-turn cooldown.'),
 'ENDERMAGE': ('Endermage', 'Pull one visible enemy land military unit within two tiles onto a legal empty adjacent land tile. Consumes movement. Seven-turn cooldown.'),
 'THOR': ('Thor', 'Deal 15 damage to one visible enemy military unit within two tiles. Consumes movement. Five-turn cooldown.'),
 'VIPER': ('Viper', 'Direct attacks that damage an enemy military unit poison it for 5 damage at the start of its next two turns. Refreshes; never stacks.'),
}
TEXT = {
 'CIV': 'McPvP - The Endless Lobby', 'SHORT': 'McPvP', 'ADJECTIVE': 'McPvP',
 'LEADER': 'The Old Guard', 'TRAIT': 'Just One More Game',
 'TRAIT_HELP': 'Queue Hardcore Games, Capture the Flag or Sabotage in the Server Browser. Matches last 20 turns on Standard speed. Earn Server Legacy from contested Feasts, returned flags, infiltration and Server Hub training. Every 25 Lifetime Legacy grants +1 capital Culture (maximum +8). In the Information Era, Legacy Unforgotten grants permanent +10% military combat XP and up to +10 additional capital Culture. Five mutually exclusive kits give units distinct tactical abilities.',
 'CIV_PEDIA': 'The match ends. The memories do not.[NEWLINE][NEWLINE]McPvP remembers an early Minecraft multiplayer community through turn-based competition: choosing a kit, racing to the Feast, bringing a flag home and spotting an infiltrator. The Old Guard represents its players, friendships and rivalries rather than a single historical ruler. This is an unofficial fan civilization; no external music or Minecraft textures are included.',
 'LEADER_PEDIA': 'The Old Guard is the player who knows every route out of spawn and still makes room for a beginner in the lobby. Competitive, adaptable and opportunistic, they build a legacy through skill and participation. Their story belongs to all who returned for just one more game.',
 'STRATEGY': 'Preserve your Veterans and select kits for the terrain. Kangaroo excels at flags; Stomper controls hills; Endermage disrupts formations; Thor punishes exposed units; Viper rewards repeated skirmishing. Hubs preserve Barracks benefits and train kit-ready armies. Queue objectives your position can support. Culture comes from participation, not idle conquest.',
 'DAWN': 'Welcome back, Old Guard.[NEWLINE][NEWLINE]Lobby One is filling. Someone is choosing Kangaroo. Someone swears Stomper is the only kit worth playing. Beyond spawn lies a world of Feasts, flags and uncertain alliances.[NEWLINE][NEWLINE]Build the Original Server Hub, choose your next match in the Server Browser, and give your players a story worth remembering.[NEWLINE][NEWLINE]The match ends. The memories don\'t.',
 'UNIT': 'Veteran PvPer', 'UNIT_HELP': 'Replaces Scout: 6 Combat Strength, normal active Scout mobility and reconnaissance, +25% combat XP. Select a kit immediately. Change kits in a friendly city every 15 turns; identity and cooldowns survive normal upgrades.',
 'UNIT_PEDIA': 'Every expert was once the beginner at spawn. Veteran PvPers carry the lessons of countless matches into new eras; their battlefield model and normal upgrade path follow the active Scout.',
 'UNIT_STRATEGY': 'Scout, survive and adapt. Veterans keep their identity and kit privileges after upgrades. Kit changes consume movement and preserve outstanding ability cooldowns.',
 'HUB': 'Original Server Hub', 'HUB_HELP': 'Replaces Barracks and retains its active benefits. +1 Culture and +1 Gold. Eligible military units trained or purchased here may select a kit and grant +2 Server Legacy once.',
 'HUB_PEDIA': 'A few blocks, a sign and a familiar crowd: a whole world begins in the lobby. The Original Server Hub trains competitors and records their first steps into the arena.',
 'HUB_STRATEGY': 'Build Hubs in military training cities to unlock kits and steadily earn Legacy. Free, captured and upgraded units do not grant training Legacy.',
 'DUMMY': 'Server Legacy', 'DUMMY_HELP': 'Automatically maintained capital Culture or temporary Sabotage effects. Cannot be built or captured.',
 'VETERAN': 'Old Guard Veteran', 'VETERAN_HELP': '+25% combat XP; kit eligibility and city retraining survive upgrades.',
 'GRACE': 'Grace Period', 'GRACE_HELP': '+10% defensive Combat Strength during the opening phase of Hardcore Games.',
 'FINAL': 'Final Battle', 'FINAL_HELP': '+20% combat XP after the Feast activates, until the match ends.',
 'FLAG': 'Flag Carrier', 'FLAG_HELP': 'Carrying an enemy flag: cannot initiate attacks; -15% defensive Combat Strength. Return it on land belonging to one of your cities. Embarking or changing ownership loses the flag; ordinary upgrade, gift and disband commands are blocked.',
 'POISON': 'Viper Poison', 'POISON_HELP': '5 damage at the start of each of the next two owner turns. Further Viper attacks refresh the duration without stacking.',
 'MEMORY': 'Legacy Unforgotten', 'MEMORY_HELP': 'Permanent +10% military combat XP. The servers fall silent; the memories remain.',
 'BROWSER': 'McPvP Server Browser', 'CLOSE': 'Close', 'LOCATE': 'Locate Feast',
 'HG': 'Hardcore Games', 'CTF': 'Capture the Flag', 'SAB': 'Sabotage',
 'QUEUE_HG': 'Queue Hardcore Games', 'QUEUE_CTF': 'Queue Capture the Flag', 'QUEUE_SAB': 'Queue Sabotage',
 'TARGET': 'Next target', 'ACTIVATE': 'Use kit ability', 'STEAL': 'Steal flag', 'RETURN': 'Return flag', 'INFILTRATE': 'Infiltrate',
 'PANEL_HELP': 'Select a military unit on the map. Choose a kit or cycle valid targets, then use its action. All durations scale with game speed. Queued modes begin next match. Target buttons show why an action is unavailable.',
 'THANKS': 'THANKS FOR PLAYING',
 'REMEMBRANCE': 'Legacy Unforgotten[NEWLINE][NEWLINE]The servers have fallen silent.[NEWLINE][NEWLINE]The lobbies that once held thousands now stand empty.[NEWLINE][NEWLINE]But the friendships, rivalries, victories and defeats remain.[NEWLINE][NEWLINE]A match can end.[NEWLINE][NEWLINE]A memory doesn\'t have to.',
 'GREETING_1': 'Welcome to the lobby. Pick a kit, learn the map, and make yourself a name.',
 'WAR_1': 'Grace period is over. See you at the Feast.', 'PEACE_1': 'Good game. Same lobby next time?',
 'DEFEAT_1': 'The match ends. The memories don\'t. Thanks for playing.',
}
for key, (name, help_) in KITS.items():
    TEXT[key], TEXT[key+'_HELP'] = name, help_
CITIES = ['Lobby One', 'Hunger Games Arena', 'Feast Grounds', 'CTF Lobby', 'Sabotage Hub', 'Kit Arena', "Veteran's Hall", 'Spawn Point', 'Deathmatch Arena', 'Old Spawn', 'Final Circle', 'Spectator Stand', 'Legacy Lobby']
for i, name in enumerate(CITIES, 1): TEXT['CITY_'+str(i)] = name
for i, name in enumerate(['Spectator', 'Hidden Name', 'Night Shift', 'Quiet Lobby', 'False Team', 'Back Route', 'Disguise', 'Watchtower', 'Old Rival', 'Last Login'], 1): TEXT['SPY_'+str(i)] = name
TEXT.update({'CIV5':'McPvP', 'OLD_GUARD':'The Old Guard', 'CIV5_HEADING_1':'The Endless Lobby', 'CIV5_TEXT_1':TEXT['CIV_PEDIA'],
 'OLD_GUARD_NAME':TEXT['LEADER'], 'OLD_GUARD_SUBTITLE':'Just One More Game', 'OLD_GUARD_LIVED':'The age of the crowded lobby',
 'OLD_GUARD_TITLES_1':'Keeper of the Server', 'OLD_GUARD_HEADING_1':'A Legacy Shared', 'OLD_GUARD_TEXT_1':TEXT['LEADER_PEDIA']})

def clone(*a, **k): return base_clone(*a, **k).replace('BCClone','MCPClone')
def companions(*a, **k): return base_companions(*a, **k).replace('BCCompanion','MCPCompanion')

def main():
 d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True)
 core="""-- CP v151 event contracts, verified against the pinned official source.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES',
  'EVENTS_UNIT_ACTIONS','EVENTS_COMMAND','EVENTS_NEW_ERA','EVENTS_PLAYER_TURN',
  'EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_ABORT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_MCPVP_GREEN',0.14,0.36,0.19,1),('COLOR_MCPVP_GOLD',0.94,0.77,0.32,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_MCPVP','COLOR_MCPVP_GREEN','COLOR_MCPVP_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_MCPVP_MORE_GAME','TXT_KEY_MCPVP_TRAIT_HELP','TXT_KEY_MCPVP_TRAIT');
"""
 core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_MCPVP_CIV',ShortDescription='TXT_KEY_MCPVP_SHORT',Adjective='TXT_KEY_MCPVP_ADJECTIVE',Civilopedia='TXT_KEY_MCPVP_CIV_PEDIA',CivilopediaTag='TXT_KEY_MCPVP_CIV5',Strategy='TXT_KEY_MCPVP_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_MCPVP',Playable=1,AIPlayable=1,PackageID=None,DawnOfManQuote='TXT_KEY_MCPVP_DAWN',DawnOfManAudio='',DawnOfManImage='MCP_Dawn.dds',MapImage='MCP_Map.dds',PortraitIndex=0,IconAtlas='MCPVP_CIV_ATLAS',AlphaIconAtlas='MCPVP_ALPHA_ATLAS')
 core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_MCPVP_LEADER',Civilopedia='TXT_KEY_MCPVP_LEADER_PEDIA',CivilopediaTag='TXT_KEY_MCPVP_OLD_GUARD',PackageID=None,Boldness=8,VictoryCompetitiveness=8,WonderCompetitiveness=3,MinorCivCompetitiveness=5,WarmongerHate=3,DoFWillingness=5,DenounceWillingness=5,Loyalty=6,Forgiveness=5,Chattiness=6,Meanness=5,PortraitIndex=0,IconAtlas='MCPVP_LEADER_ATLAS',ArtDefineTag='MCP_LeaderScene.xml')
 core+=clone('Units','UNIT_SCOUT',UNIT,Combat=6,Description='TXT_KEY_MCPVP_UNIT',Civilopedia='TXT_KEY_MCPVP_UNIT_PEDIA',Help='TXT_KEY_MCPVP_UNIT_HELP',Strategy='TXT_KEY_MCPVP_UNIT_STRATEGY',IconAtlas='MCPVP_OBJECT_ATLAS',PortraitIndex=0)
 core+=clone('Buildings','BUILDING_BARRACKS',HUB,Description='TXT_KEY_MCPVP_HUB',Civilopedia='TXT_KEY_MCPVP_HUB_PEDIA',Help='TXT_KEY_MCPVP_HUB_HELP',Strategy='TXT_KEY_MCPVP_HUB_STRATEGY',IconAtlas='MCPVP_OBJECT_ATLAS',PortraitIndex=1)
 core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_MCPVP_MORE_GAME');\nINSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SCOUT','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_BARRACKS','{HUB}');\n"
 for group,count in [('CITY',len(CITIES)),('SPY',10)]:
  for i in range(1,count+1): core+=f"INSERT INTO Civilization_{'CityNames' if group=='CITY' else 'SpyNames'} VALUES ('{CIV}','TXT_KEY_MCPVP_{group}_{i}');\n"
 inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON',LEADER,('Leader_Traits',))
 for t in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']: inherit+=companions(d,t,'CivilizationType','CIVILIZATION_AMERICA',CIV)
 inherit+=companions(d,'Unit_','UnitType','UNIT_SCOUT',UNIT)
 inherit+=companions(d,'Building_','BuildingType','BUILDING_BARRACKS',HUB)
 effects=f"INSERT INTO Unit_FreePromotions VALUES ('{UNIT}','PROMOTION_MCPVP_VETERAN');\n"
 for yield_ in ['CULTURE','GOLD']:
  effects+=f"UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{HUB}' AND YieldType='YIELD_{yield_}';\nINSERT INTO Building_YieldChanges SELECT '{HUB}','YIELD_{yield_}',1 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{HUB}' AND YieldType='YIELD_{yield_}');\n"
 for name in ['LEGACY_0','LEGACY_1','LEGACY_2','LEGACY_3','LEGACY_4','SABOTAGE']:
  effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_MCPVP_{name}','BUILDING_MCPVP_{name}','TXT_KEY_MCPVP_DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex) VALUES ('BUILDING_MCPVP_{name}','BUILDINGCLASS_MCPVP_{name}','TXT_KEY_MCPVP_DUMMY','TXT_KEY_MCPVP_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'MCPVP_OBJECT_ATLAS',1);\n"
  if name!='SABOTAGE': effects+=f"INSERT INTO Building_YieldChanges VALUES ('BUILDING_MCPVP_{name}','YIELD_CULTURE',{2**int(name[-1])});\n"
 effects+="INSERT INTO Building_YieldModifiers VALUES ('BUILDING_MCPVP_SABOTAGE','YIELD_PRODUCTION',-20),('BUILDING_MCPVP_SABOTAGE','YIELD_GOLD',-15);\n"
 for name,value in {'OFFENSE':8,'DEFENSE':6,'RECON':10,'MILITARY_TRAINING':9,'CULTURE':8,'GOLD':6,'EXPANSION':5,'SCIENCE':5,'WONDER':3}.items():
  effects+=f"DELETE FROM Leader_Flavors WHERE LeaderType='{LEADER}' AND FlavorType='FLAVOR_{name}';\nINSERT INTO Leader_Flavors SELECT '{LEADER}',Type,{value} FROM Flavors WHERE Type='FLAVOR_{name}';\n"
 for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('DEFEATED','DEFEAT'),('PEACE_OFFER','PEACE'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE')]: effects+=f"INSERT INTO Diplomacy_Responses VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_MCPVP_{key}_%',1);\n"
 promos={'VETERAN':{'ExperiencePercent':25},'GRACE':{'DefenseMod':10},'FINAL':{'ExperiencePercent':20},'FLAG':{'OnlyDefensive':1,'DefenseMod':-15},'POISON':{},'MEMORY':{'ExperiencePercent':10},**{k:({'MovesChange':1,'DefenseMod':-10} if k=='KANGAROO' else {}) for k in KITS}}
 for i,(name,fields) in enumerate(promos.items()):
  values={'Type':'PROMOTION_MCPVP_'+name,'Description':'TXT_KEY_MCPVP_'+name,'Help':'TXT_KEY_MCPVP_'+name+'_HELP','CannotBeChosen':1,'LostWithUpgrade':0,'LostOnGifting':1,'ShowInUnitPanel':1,'IsVisibleAboveFlag':1,'PortraitIndex':i,'IconAtlas':'MCPVP_PROMO_ATLAS',**fields}
  def val(v):return str(v) if isinstance(v,int) else "'"+v+"'"
  effects+='INSERT INTO UnitPromotions('+','.join(values)+') VALUES ('+','.join(val(v) for v in values.values())+');\n'
 art=''
 for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('LEADER','Portrait',1),('OBJECT','Objects',2),('PROMO','Promotions',11)]:
  for size in [16,24,32,45,48,64,80,128,256]:art+=f"INSERT INTO IconTextureAtlases VALUES ('MCPVP_{atlas}_ATLAS',{size},'MCP_{stem}{size}.dds',{cols},1);\n"
 text='\n'.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_MCPVP_"+k+"','"+v.replace("'","''")+"');" for k,v in sorted(TEXT.items()))+'\n'
 for name,content in [('00_MCP_Core',core),('01_MCP_Inheritance',inherit),('02_MCP_Effects',effects),('03_MCP_Art',art),('10_MCP_Text',text)]: (V/'SQL'/(name+'.sql')).write_text(content,encoding='utf-8',newline='\n')
 print('Generated McPvP identity, active Scout/Barracks inheritance, effects and localization')

if __name__=='__main__':main()
