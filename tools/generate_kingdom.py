"""Generate Kingdom SQL from the installed BNW/CP v151 schema and live baselines."""
from pathlib import Path
from database import database
from generate_database import clone, companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheChildrenOfTheKingdom'
CIV = 'CIVILIZATION_CK_KINGDOM'
LEADER = 'LEADER_CK_FAITHFUL'
UNIT = 'UNIT_CK_KEEPER'
HOUSE = 'BUILDING_CK_HOUSE'
STAGES = [
 ('ADDRESS', 'Our Father in heaven.', 'Capital: +2 Faith and +1 Food per turn for {1_Turns} turns.'),
 ('OPENING GLORY', 'Hallowed be Your name.', 'Immediately receive {2_Faith} Faith (10 per Era level).'),
 ('SEEK', 'Your kingdom come, Your will be done.', 'Every owned city: +15% Culture for {1_Turns} turns.'),
 ('ASK', 'Give us this day our daily bread.', 'Capital: immediately gain {3_Yield} Food and {3_Yield} Production (8 each per Era level). Production beyond the current item, or without a finite queue, is safely held in a saved reserve.'),
 ('REPENT', 'Forgive us our debts, as we forgive our debtors.', '+2 Global Happiness for {1_Turns} turns.'),
 ('PROTECTION', 'Lead us not into temptation, but deliver us from evil.', 'All owned cities: +20% City Strength for {1_Turns} turns. Military units: +15% strength only when defending in friendly territory for the same duration.'),
 ('CLOSING GLORY', 'For Yours is the kingdom, the power, and the glory forever.', 'Gain {4_GAP} Golden Age Points (20 per Era level), one permanent Grace (maximum 7), and 10 Faith per completed House of Prayer. At 7 Grace, gain {5_Excess} extra Golden Age Points (25 per Era level) instead. The next petition is Address.'),
]
TEXT = {
 'CIV':'The Children of the Kingdom', 'SHORT':'Children of the Kingdom', 'ADJECTIVE':'Kingdom',
 'LEADER':'The Faithful', 'TRAIT':'Thy Kingdom Come',
 'TRAIT_HELP':'Human players only. Open Prayer to activate seven petitions in order, once every 5 turns on Standard speed (scaled with game speed). Complete a cycle for one permanent Grace, maximum 7: each gives the capital +1 Faith and +1 Culture per turn. Closing Glory also grants 20 Golden Age Points per Era level and 10 Faith per completed House of Prayer. At maximum Grace, each further cycle gives 25 additional Golden Age Points per Era level. See Prayer for every blessing.',
 'UNIT':'Keeper of the Faith',
 'UNIT_HELP':'Replaces Pikeman and retains its normal characteristics and anti-mounted role. For human Kingdom players, Stand Firm grants +15% strength only when defending in friendly territory and +5 HP per eligible healing turn in friendly territory. Stand Firm persists through upgrades. Protection is a separate +15% defensive bonus; neither strengthens attacks.',
 'UNIT_STRATEGY':'Hold friendly ground, protect cities and preserve experienced defenders through upgrades. Normal movement, healing eligibility and anti-mounted rules apply. Stand Firm does not enable healing after moving or during every turn.',
 'UNIT_PEDIA':'Keepers understand steadfastness as service. They guard homes, pilgrims and the quiet labor of their neighbors. Their pikes retain the ordinary battlefield role of the Pikeman; their distinction is perseverance rather than a desire for conquest. The standard Pikeman model is deliberately retained.',
 'HOUSE':'House of Prayer',
 'HOUSE_HELP':'Replaces Temple, retaining its active costs, prerequisites, maintenance and all ordinary Temple effects. A completed House in a human Kingdom city additionally provides +1 Faith and +1 Culture. Each currently owned, completed House grants 10 Faith whenever Closing Glory is prayed.',
 'HOUSE_STRATEGY':'Build Houses where you can support the normal Temple maintenance. Their additional Faith and Culture support cultural and diplomatic development; completing prayer cycles rewards every House currently owned.',
 'HOUSE_PEDIA':'A House of Prayer is a place for devotion, reconciliation and the sharing of daily bread. Within its stone walls, neighbors learn that humility and forgiveness are practices to renew throughout a lifetime. The building preserves the Temple\'s ordinary role while supporting the prayer cycle.',
 'STAND':'Stand Firm', 'STAND_HELP':'+15% defensive strength in friendly territory and +5 HP per eligible healing turn there. Retained on upgrade. Human Kingdom players only.',
 'DEFENDER':'Stand Firm — defending at home', 'DEFENDER_HELP':'+15% strength when defending. Active only in friendly territory. No attack bonus.',
 'SHIELD':'Protection — defending at home', 'SHIELD_HELP':'+15% strength when defending in friendly territory during Protection. Separate from Stand Firm. No attack bonus.',
 'DUMMY':'Kingdom blessing', 'DUMMY_HELP':'Automatically maintained by Prayer; cannot be built or purchased.',
 'REPENT_POLICY':'Forgiveness', 'REPENT_POLICY_HELP':'+2 Global Happiness during Repent; counted once in the empire.',
 'PROTECTION_POLICY':'Deliverance', 'PROTECTION_POLICY_HELP':'+20% City Strength in all owned cities during Protection.',
 'CIV_PEDIA':'The Children of the Kingdom are a fictional community inspired by the Lord\'s Prayer in Matthew 6:9–13. Their common life begins in Sanctuary and grows through devotion, humility, forgiveness and trust in God\'s will. Their strength comes from steady prayer rather than conquest.[NEWLINE][NEWLINE]The seven petitions move from addressing the Father, through praise, seeking, daily provision, repentance and protection, to a closing doxology. The familiar closing words belong to the traditional doxology; Christian traditions differ in their liturgical use and textual placement. The seven-stage cycle is a gameplay structure, not a claim that every tradition divides the prayer in this way.[NEWLINE][NEWLINE]Grace represents enduring spiritual growth within this fictional civilization. It is not an assertion that divine favor can be measured or earned as a game currency.',
 'LEADER_PEDIA':'The Faithful represents a community\'s shared commitment to prayer and service. This fictional leader seeks neither personal glory nor a kingdom built by violence. Their task is to preserve a people who can ask for daily bread, forgive their neighbors and persevere through hardship.',
 'STRATEGY':'Pray consistently, develop Houses of Prayer, and defend your cities while Grace slowly strengthens the capital. Culture and Diplomatic victories suit this patient civilization. Early blessings are modest; protecting experienced Keepers and completing seven-stage cycles matters more than conquest.',
 'DAWN':'Faithful servant, the people of Sanctuary gather in the morning light. Teach them to seek the kingdom, share their daily bread and forgive as they hope to be forgiven.[NEWLINE][NEWLINE]Let prayer sustain their work and steadfast defenders preserve their peace. Through patient devotion, may this humble beginning become a civilization of enduring faith and culture.',
 'FAITHFUL_NAME':'The Faithful', 'FAITHFUL_SUBTITLE':'A servant among the people', 'FAITHFUL_LIVED':'The age of faithful perseverance', 'FAITHFUL_TITLES_1':'The Faithful', 'FAITHFUL_HEADING_1':'Prayer and service',
 'CIV5_HEADING_1':'A life shaped by prayer',
 'TITLE':'THE CHILDREN OF THE KINGDOM — PRAYER', 'OPEN':'[ICON_PEACE] Prayer', 'CLOSE':'Close', 'PRAY':'PRAY',
 'CURRENT':'Current Petition: {1_Name}', 'PROGRESS':'Grace: {1_Grace}/7     Cycle: {2_Stage}/7',
 'AVAILABLE':'Next Prayer: Available', 'WAIT':'Next Prayer: {1_Turns} turns',
 'PERMANENT':'Permanent capital blessing: +{1_Grace} Faith and +{1_Grace} Culture per turn.',
 'ACTIVE':'Active blessings', 'NONE':'No temporary blessings are active.',
 'ACTIVE_LINE':'{1_Name}: {2_Turns} turns remaining', 'BLESSING':'Blessing: {1_Effect}',
 'READY_HELP':'Pray the current petition once. The next petition becomes available after {1_Turns} turns.',
 'WAIT_HELP':'This petition is not yet available. Wait {1_Turns} turns; changing screens or reloading does not reset the cooldown.',
 'UNAVAILABLE':'Prayer requires an active human Kingdom turn and an owned capital. Multiplayer and hotseat are unsupported.',
 'DISABLED':'Prayer state could not be read safely. Effects are disabled; see Lua.log. The original saved data has been preserved.',
 'CONFIRM':'{1_Name} prayed. The next petition is {2_Next}; available in {3_Turns} turns.',
 'GRACE_GAIN':'A full prayer is complete. Grace: {1_Grace}/7. Each Grace gives the capital +1 Faith and +1 Culture per turn.',
 'GRACE_CAP':'A full prayer is complete. Grace remains 7/7; receive {1_GAP} additional Golden Age Points.',
 'HOUSE_REWARD':'Completed Houses of Prayer: {1_Count}. Closing Glory grants {2_Faith} additional Faith.',
 'RESERVE':'Daily bread Production reserve: {1_Amount}. Applied safely to a finite capital queue; it moves with the capital.',
 'CYCLE_HELP':'Petitions follow this fixed order: Address, Opening Glory, Seek, Ask, Repent, Protection, Closing Glory. Cycle shows the NEXT petition. Era level is 1 in Ancient, 2 in Classical, and so on. Durations and cooldown use the active speed\'s TrainPercent.',
}
TEXT['FAITHFUL_TEXT_1']=TEXT['LEADER_PEDIA']; TEXT['CIV5_TEXT_1']=TEXT['CIV_PEDIA']
for i,(name,quote,effect) in enumerate(STAGES,1):
    TEXT[f'STAGE_{i}']=name; TEXT[f'QUOTE_{i}']=quote; TEXT[f'EFFECT_{i}']=effect
for i,name in enumerate(['Sanctuary','Bethany','Haven of Peace','Stillwater','New Hope','Olive Grove','Mercy Hill','Pilgrim\'s Rest','Living Spring','Gracehaven','Covenant','Morning Light','Good Shepherd','Breadfield','Peacebridge','Cornerstone','Cedars of Hope','Watchful Gate','Lily Vale','Faithful Harbor'],1): TEXT[f'CITY_{i}']=name
for i,name in enumerate(['Olive Branch','Quiet Witness','Pilgrim','Peacemaker','Watchful Servant','Lampbearer','Morning Star','Still Voice','Open Hand','Dove'],1): TEXT[f'SPY_{i}']=name

def main():
    d=database(); (V/'SQL').mkdir(parents=True,exist_ok=True)
    core="""-- Verified CP v151 options; no AI routines or changes to another civilization.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_CITY_CAPITAL','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_TILE_IMPROVEMENTS','EVENTS_MINORS');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES ('COLOR_CK_BLUE',0.23,0.36,0.49,1),('COLOR_CK_GOLD',0.94,0.85,0.60,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES ('PLAYERCOLOR_CK','COLOR_CK_BLUE','COLOR_CK_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_CK_KINGDOM','TXT_KEY_CK_TRAIT_HELP','TXT_KEY_CK_TRAIT');
"""
    core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_CK_CIV',ShortDescription='TXT_KEY_CK_SHORT',Adjective='TXT_KEY_CK_ADJECTIVE',Civilopedia='TXT_KEY_CK_CIV_PEDIA',CivilopediaTag='TXT_KEY_CK_CIV5',Strategy='TXT_KEY_CK_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_CK',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_CK_DAWN',DawnOfManAudio='',DawnOfManImage='CKDawn.dds',MapImage='CKMap.dds',PortraitIndex=0,IconAtlas='CK_CIV_ATLAS',AlphaIconAtlas='CK_ALPHA_ATLAS')
    core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_CK_LEADER',Civilopedia='TXT_KEY_CK_LEADER_PEDIA',CivilopediaTag='TXT_KEY_CK_FAITHFUL',PackageID=None,PortraitIndex=0,IconAtlas='CK_LEADER_ATLAS',ArtDefineTag='CKLeaderScene.xml')
    core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_CK_KINGDOM');\n"
    core+=clone('Units','UNIT_PIKEMAN',UNIT,Description='TXT_KEY_CK_UNIT',Civilopedia='TXT_KEY_CK_UNIT_PEDIA',Help='TXT_KEY_CK_UNIT_HELP',Strategy='TXT_KEY_CK_UNIT_STRATEGY',IconAtlas='CK_OBJECT_ATLAS',PortraitIndex=1,UnitFlagAtlas='CK_FLAG_ATLAS',UnitFlagIconOffset=0)
    core+=clone('Buildings','BUILDING_TEMPLE',HOUSE,Description='TXT_KEY_CK_HOUSE',Civilopedia='TXT_KEY_CK_HOUSE_PEDIA',Help='TXT_KEY_CK_HOUSE_HELP',Strategy='TXT_KEY_CK_HOUSE_STRATEGY',IconAtlas='CK_OBJECT_ATLAS',PortraitIndex=0)
    core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_PIKEMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_TEMPLE','{HOUSE}');\n"
    for i in range(1,21): core+=f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_CK_CITY_{i}');\n"
    for i in range(1,11): core+=f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_CK_SPY_{i}');\n"
    inherit=''
    for t in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']: inherit+=companions(d,t,'CivilizationType','CIVILIZATION_AMERICA',CIV)
    inherit+=companions(d,'Unit_','UnitType','UNIT_PIKEMAN',UNIT)
    inherit+=companions(d,'Building_','BuildingType','BUILDING_TEMPLE',HOUSE)
    # The Temple remains an exact native clone. Human-only extras use a removable dummy.
    effects='-- No native free Stand Firm: Lua grants it only to human Kingdom Keepers.\n'
    for name,defense,heal,lost in [('STAND',0,5,0),('DEFENDER',15,0,1),('SHIELD',15,0,1)]:
        effects+=f"INSERT INTO UnitPromotions(Type,Description,Help,DefenseMod,FriendlyHealChange,CannotBeChosen,LostWithUpgrade,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('PROMOTION_CK_{name}','TXT_KEY_CK_{name}','TXT_KEY_CK_{name}_HELP',{defense},{heal},1,{lost},1,'CK_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_CK_{name}');\n"
    for name in ['ADDRESS','SEEK','HOUSE_BONUS','GRACE_0','GRACE_1','GRACE_2']:
        effects+=f"INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_CK_{name}','BUILDING_CK_{name}','TXT_KEY_CK_DUMMY');\nINSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex) VALUES ('BUILDING_CK_{name}','BUILDINGCLASS_CK_{name}','TXT_KEY_CK_DUMMY','TXT_KEY_CK_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'CK_OBJECT_ATLAS',2);\n"
    for name,yields in [('ADDRESS',{'FAITH':2,'FOOD':1}),('HOUSE_BONUS',{'FAITH':1,'CULTURE':1})]+[(f'GRACE_{i}',{'FAITH':2**i,'CULTURE':2**i}) for i in range(3)]:
        for kind,amount in yields.items(): effects+=f"INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_CK_{name}','YIELD_{kind}',{amount});\n"
    effects+="UPDATE Buildings SET CultureRateModifier=15 WHERE Type='BUILDING_CK_SEEK';\n"
    for name,column,value in [('REPENT','ExtraHappiness',2),('PROTECTION','CityStrengthMod',20)]:
        effects+=f"INSERT INTO Policies(Type,Description,Help,{column},IsDummy,PortraitIndex,IconAtlas) VALUES ('POLICY_CK_{name}','TXT_KEY_CK_{name}_POLICY','TXT_KEY_CK_{name}_POLICY_HELP',{value},1,2,'CK_OBJECT_ATLAS');\n"
    art=''
    for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',3)]:
        for size in [16,24,32,45,48,64,80,128,256]: art+=f"INSERT INTO IconTextureAtlases VALUES ('CK_{atlas}_ATLAS',{size},'CK{stem}{size}.dds',{cols},1);\n"
    for size in [64,128,256]: art+=f"INSERT INTO IconTextureAtlases VALUES ('CK_LEADER_ATLAS',{size},'CKPortrait{size}.dds',1,1);\n"
    art+="INSERT INTO IconTextureAtlases VALUES ('CK_FLAG_ATLAS',32,'CKFlag32.dds',1,1);\n"
    text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_CK_"+key+"','"+value.replace("'","''")+"');\n" for key,value in sorted(TEXT.items()))
    for name,content in [('00_CK_Core',core),('01_CK_Inheritance',inherit),('02_CK_Effects',effects),('03_CK_Art',art),('10_CK_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content.replace('BCClone','CKClone').replace('BCCompanion','CKCompanion'),encoding='utf-8',newline='\n')
    print('Generated Kingdom identity, exact Pikeman/Temple inheritance, human-only effects and localization')

if __name__=='__main__': main()
