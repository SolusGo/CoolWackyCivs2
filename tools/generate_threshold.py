"""Compile active CP Market/Pikeman inheritance; never hardcode their balance."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R=Path(__file__).resolve().parents[1]
V=R/'TheThresholdCourt'
CIV='CIVILIZATION_THRESHOLD_COURT'
LEADER='LEADER_QUEEN_ELSEWHERE'
UNIT='UNIT_THRESHOLD_HINGEGUARD'
BUILDING='BUILDING_THRESHOLD_HOUSE'
TEXT={
 'CIV':'The Threshold Court','SHORT':'The Threshold Court','ADJECTIVE':'Threshold','LEADER':'Queen Elsewhere',
 'TRAIT':'A Door in Every Wall',
 'TRAIT_HELP':'Once per owner-turn, teleport an unembarked land melee military unit from an owned Threshold House city to another owned Threshold House city with a free military slot. Unlimited distance. Costs 50 + 25 per current Era index Gold, charged only on success. The origin recharges at turn T+8. Arrivals cannot move or attack until the next owner-turn. Human-only.',
 'STRATEGY':'Construct a Threshold House network before committing to a distant war. Each origin can send a unit only once every eight owner-turns; only one transfer is allowed empire-wide each turn. Keep a destination garrison slot open and reserve Gold. Domination rewards strategic redeployment; Science benefits from a wide empire that can respond quickly to invasion.',
 'CIV_PEDIA':'An ancient kingdom is joined by doors concealed within its most important buildings. Mountains and oceans divide its maps, but not its corridors. Behind the merchants and counters of each Threshold House stands a polished wooden door edged in brass. A soldier can step through and emerge on another continent. The crossings demand money, preparation and eight turns of quiet at the door that sent them.[NEWLINE][NEWLINE]Every door leads somewhere. The Court has learned to ask where before opening it.',
 'LEADER_PEDIA':'Queen Elsewhere rules an ancient kingdom whose important buildings conceal doors connected to distant locations. Her throne room contains thirteen doors. Twelve lead to different parts of her kingdom. The thirteenth has never been opened. She speaks of journeys as other rulers speak of footsteps, yet keeps careful accounts of every crossing. The last door remains locked by royal command.',
 'DAWN':'Queen Elsewhere, Sovereign of the Thresholds, the doors of destiny await your command.[NEWLINE][NEWLINE]For countless generations, humanity has been divided by mountains, oceans and the vast distances between nations.[NEWLINE][NEWLINE]Armies marched for years. Merchants crossed dangerous wildernesses. Families were separated by lands they could never hope to traverse.[NEWLINE][NEWLINE]But your ancestors discovered a secret.[NEWLINE][NEWLINE]The world is not as large as it appears.[NEWLINE][NEWLINE]Behind every wall lies another passage. Beyond every locked door waits another destination.[NEWLINE][NEWLINE]Now, your people have inherited the ancient Thresholds.[NEWLINE][NEWLINE]Establish your cities. Awaken the forgotten doorways. Let your soldiers travel where no army could ever march.[NEWLINE][NEWLINE]Will you build an empire spanning the world, or discover what waits beyond the final door?',
 'UNIT':'Hingeguard','UNIT_HELP':'Replaces Pikeman. Inherits the active Community Patch Pikeman, with +1 Movement and +15% Combat Strength when fighting on friendly territory. Retains the standard resources, promotions and upgrade path. Eligible for Threshold Transfer.',
 'UNIT_STRATEGY':'Guard your cities and prepare to reinforce distant Threshold Houses. Your extra movement aids positioning; the friendly-territory bonus helps reclaim your own ground and does not strengthen attacks in enemy territory.',
 'UNIT_PEDIA':'The Hingeguard wears heavy armor decorated with brass hinges and carries a shield resembling a reinforced wooden door. These soldiers know the kingdom by its thresholds rather than its roads. The field model and animations use the ordinary Pikeman.',
 'BUILDING':'Threshold House','BUILDING_HELP':'Replaces Market. Inherits all active Community Patch Market properties and adds exactly +1 Culture. Enables this owned city as a Threshold Transfer endpoint; does not grant a free crossing or any further passive yield.',
 'BUILDING_STRATEGY':'Build at both ends of a planned military corridor. Keep an empty military slot at the destination. Only a successful departure starts this city\'s eight-turn cooldown; receiving a unit does not.',
 'BUILDING_PEDIA':'A commercial hall of dark polished wood and restrained gothic arches. Behind the ledgers waits an ornate brass doorway, watched by the Hingeguard. Its merchants trade as other merchants do. The doorway changes the scale of the kingdom.',
 'DEFENDER':'Keeper of the Threshold','DEFENDER_HELP':'+15% Combat Strength attacking or defending on friendly territory. Retained on upgrade.',
 'EXHAUSTED':'Threshold Exhaustion','EXHAUSTED_HELP':'Cannot move or make offensive attacks until the next owner-turn. Defends normally. Upgrades are deferred until recovery.',
 'GREETING_1':'Welcome. I trust your journey was pleasant. Mine took approximately three seconds.',
 'WAR_1':'You have surrounded my city? How unfortunate. You seem to believe my army is somewhere else.',
 'DEFEAT_1':'So... this is where the last door leads.',
 'ATTACKED_1':'The walls have doors. You should have remembered that.', 'PEACE_1':'Let us close this particular door.',
 'FRIENDLY_1':'A door is always open to you.', 'NEUTRAL_1':'Where would you like this conversation to lead?',
 'HOSTILE_1':'Some doors are better left closed.', 'TRADE_1':'Our ledgers agree.',
 'TRANSFER':'Threshold Transfer','TITLE':'THRESHOLD TRANSFER','CANCEL':'Cancel','CONFIRM':'Confirm Transfer','CLOSE':'Close',
 'HEADER':'Selected Unit: {1_Name}[NEWLINE]Origin: {2_Name}[NEWLINE]Cost: {3_Num} [ICON_GOLD]',
 'AVAILABLE':'Available','NO_HOUSE':'Missing Threshold House.','OCCUPIED':'Military slot occupied.',
 'INVALID_DEST':'Destination is no longer a valid owned city.','SAME_CITY':'Choose another city.',
 'ENGINE_REJECT':'Native terrain or stacking rules reject this destination.',
 'INVALID_UNIT':'Selected unit is no longer valid.','INELIGIBLE':'Requires an unembarked land melee military unit with offensive capability.',
 'ORIGIN':'Stand on an owned city tile containing a Threshold House.',
 'NOT_TURN':'Available only during your active owner-turn.','USED':'Threshold Transfer already used this turn.',
 'COOLDOWN':'Origin portal recharging: {1_Num} turns remaining.','GOLD':'Requires {1_Num} Gold.',
 'EXHAUSTION':'This unit is exhausted from a Threshold Transfer.','NO_MOVES':'The unit has no movement remaining or is busy.',
 'NO_DEST':'No eligible destination. Build another Threshold House and leave its military slot open.',
 'PERSISTENCE':'Saved Threshold data is unavailable or corrupt. See Lua.log; transfer disabled.',
 'FAILED':'Relocation failed. No Gold or portal use consumed.','BUSY':'A Threshold Transfer is already being processed.',
 'CHANGED':'The selected unit or city has changed. Reopen Threshold Transfer.',
 'CHOOSE':'Choose a destination, then confirm.','CONFIRM_TO':'Confirm Transfer to {1_Name}',
 'SUCCESS':'{1_Unit} crossed from {2_Origin} to {3_Dest} for {4_Num} Gold. Origin ready on turn {5_Num}.',
 'CIV5_HEADING_1':'Every Door Leads Somewhere','QUEEN_NAME':'Queen Elsewhere','QUEEN_SUBTITLE':'Sovereign of the Thresholds',
 'QUEEN_LIVED':'An age beyond the threshold','QUEEN_TITLES_1':'Keeper of the Thirteenth Door','QUEEN_HEADING_1':'The Closed Door',
}
CITIES=['The First Door','Brass Threshold','Hollow Passage','Silent Arch','The Far Door','Thirteenth Hall','Ivory Lintel','The Unlit Stair','Door Without Shadow','Hinge of the World','Velvet Vestibule','Last Landing','The Inward Gate','Gilt Corridor','Noonday Chamber','Ashen Passage','The Narrow Door','Long Gallery','Beyond the Wall','The Still Room']
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'],QUEEN_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}':n for i,n in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}':n for i,n in enumerate(['Keykeeper','Latch','The Porter','No Footsteps','Brass Hand','Elsewhere','Night Hinge','The Visitor','Quiet Knock','Thirteenth Key'],1)})

def clone(*args,**kw):return base_clone(*args,**kw).replace('BCClone','THCClone')
def companions(*args,**kw):return base_companions(*args,**kw).replace('BCCompanion','THCCompanion')

def main():
 d=database();(V/'SQL').mkdir(parents=True,exist_ok=True)
 core="""-- Notifications/vetoes only; every handler is scoped to Threshold records.
UPDATE CustomModOptions SET Value=1 WHERE Name IN ('EVENTS_CAN_MOVE_INTO','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_THRESHOLD_BRASS',0.82,0.65,0.32,1),('COLOR_THRESHOLD_WOOD',0.09,0.13,0.14,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_THRESHOLD','COLOR_THRESHOLD_BRASS','COLOR_THRESHOLD_WOOD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_DOOR_IN_EVERY_WALL','TXT_KEY_THC_TRAIT_HELP','TXT_KEY_THC_TRAIT');
"""
 core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_THC_CIV',ShortDescription='TXT_KEY_THC_SHORT',Adjective='TXT_KEY_THC_ADJECTIVE',Civilopedia='TXT_KEY_THC_CIV_PEDIA',CivilopediaTag='TXT_KEY_THC_CIV5',Strategy='TXT_KEY_THC_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_THRESHOLD',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_THC_DAWN',DawnOfManAudio='',DawnOfManImage='THC_Dawn.dds',MapImage='THC_Map.dds',PortraitIndex=0,IconAtlas='THC_CIV_ATLAS',AlphaIconAtlas='THC_ALPHA_ATLAS')
 core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_THC_LEADER',Civilopedia='TXT_KEY_THC_LEADER_PEDIA',CivilopediaTag='TXT_KEY_THC_QUEEN',PackageID=None,PortraitIndex=0,IconAtlas='THC_LEADER_ATLAS',ArtDefineTag='THC_LeaderScene.xml')
 core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_DOOR_IN_EVERY_WALL');\n"
 core+=clone('Units','UNIT_PIKEMAN',UNIT,Description='TXT_KEY_THC_UNIT',Civilopedia='TXT_KEY_THC_UNIT_PEDIA',Help='TXT_KEY_THC_UNIT_HELP',Strategy='TXT_KEY_THC_UNIT_STRATEGY',IconAtlas='THC_OBJECT_ATLAS',PortraitIndex=1)
 core+=f"UPDATE Units SET Moves=Moves+1 WHERE Type='{UNIT}';\n"
 core+=clone('Buildings','BUILDING_MARKET',BUILDING,Description='TXT_KEY_THC_BUILDING',Civilopedia='TXT_KEY_THC_BUILDING_PEDIA',Help='TXT_KEY_THC_BUILDING_HELP',Strategy='TXT_KEY_THC_BUILDING_STRATEGY',IconAtlas='THC_OBJECT_ATLAS',PortraitIndex=0)
 core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_PIKEMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_MARKET','{BUILDING}');\n"
 for kind,count in [('City',len(CITIES)),('Spy',10)]:
  for i in range(1,count+1):core+=f"INSERT INTO Civilization_{kind}Names VALUES ('{CIV}','TXT_KEY_THC_{kind.upper()}_{i}');\n"
 inherit='-- SELECT * clones active dependency extension columns at activation.\n'
 for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
 for prefix,col,old,new in [('Unit','UnitType','UNIT_PIKEMAN',UNIT),('Building','BuildingType','BUILDING_MARKET',BUILDING),('Leader','LeaderType','LEADER_WASHINGTON',LEADER)]:inherit+=companions(d,prefix,col,old,new)
 effects=f"""-- Native generic modifier checks the battle plot on attack and defense.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,FriendlyLandsModifier,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_THRESHOLD_DEFENDER','TXT_KEY_THC_DEFENDER','TXT_KEY_THC_DEFENDER_HELP','AS2D_IF_LEVELUP',1,0,15,0,'THC_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_THC_DEFENDER');
-- OnlyDefensive prevents melee offense even with Blitz/restored movement; defense is normal.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,LostOnGifting,OnlyDefensive,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_THRESHOLD_EXHAUSTED','TXT_KEY_THC_EXHAUSTED','TXT_KEY_THC_EXHAUSTED_HELP','AS2D_IF_LEVELUP',1,0,0,1,1,'THC_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_THC_EXHAUSTED');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_THRESHOLD_DEFENDER');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{BUILDING}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{BUILDING}','YIELD_CULTURE',1 WHERE NOT EXISTS(SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{BUILDING}' AND YieldType='YIELD_CULTURE');
-- CP requires a per-type opt-in to dispatch CanMoveInto. This changes no unit
-- statistics/permissions. The veto returns true for every unmarked unit.
UPDATE Units SET SendCanMoveIntoEvent=1 WHERE Domain='DOMAIN_LAND' AND Combat>0;
"""
 for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('ATTACKED','ATTACKED'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('TRADE_ACCEPT_GENEROUS','TRADE')]:effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_THC_{key}_%',1);\n"
 art=''
 for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('LEADER','Portrait',1),('OBJECT','Objects',2),('PROMOTION','Promotions',2)]:
  for size in [16,24,32,45,48,64,80,128,256]:art+=f"INSERT INTO IconTextureAtlases VALUES ('THC_{atlas}_ATLAS',{size},'THC_{stem}{size}.dds',{cols},1);\n"
 text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_THC_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
 for n,content in [('00_THC_Core',core),('01_THC_Inheritance',inherit),('02_THC_Effects',effects),('03_THC_Art',art),('10_THC_Text',text)]: (V/'SQL'/(n+'.sql')).write_text(content,encoding='utf-8',newline='\n')
 print('Generated Threshold Court: active Market/Pikeman, exact +1 Culture/+1 Movement, human only')

if __name__=='__main__':main()
