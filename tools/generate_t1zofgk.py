"""T1 ZOFGK: active-schema inheritance and native CP v151 promotion effects."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R=Path(__file__).resolve().parents[1]; V=R/'T1ZOFGK'
CIV='CIVILIZATION_T1Z_ZOFGK'; LEADER='LEADER_T1Z_FAKER'
TRAIT='TRAIT_T1Z_ZOFGK'; UNIT='UNIT_T1Z_RECRUIT'; HQ='BUILDING_T1Z_HEADQUARTERS'
# Every simple upgrade path has fewer edges than unit classes. The validator
# checks the actual T1 replacement graph for cycles and the longest path.
DEVELOPMENT_TIERS=144
ROLES=['ZEUS','ONER','FAKER','GUMAYUSI','KERIA']
CITIES=['T1 HQ','ZOFGK Academy','Unkillable Hall','Zeus Summit','Oner Grove','Faker Midway',
        'Gumayusi Bastion','Keria Sanctuary','Gocheok Crown','London Legacy','Seoul Dynasty',
        'Worlds 2023','Worlds 2024','Summoner Square','Gangnam Campus','T1 Base Camp',
        'Challengers Hall','SKT Heritage','Red Wing Harbor','Five as One','Clutch Crossing',
        'Demon King Keep','Finals Avenue','Golden Roadstead','Rose Together','Legacy Library',
        'Trust Courtyard','Fourth Trophy','Fifth Star','Academy Annex','Veterans Watch','Dynasty Gate']
TEXT={
 'CIV':'T1 - The ZOFGK Dynasty','SHORT':'T1','ADJECTIVE':'T1', 'LEADER':'Faker','TRAIT':'ZOFGK',
 'TRAIT_HELP':'The first five T1 Recruits become Zeus, Oner, Faker, Gumayusi and Keria, each with a permanent role. Roster units with 3-4 distinct roles within two hexes gain +10% Strength; all five grant +15% instead. Lost roles can be recruited after a speed-scaled 10-turn cooldown by training a new land melee unit in a city with a real T1 Headquarters. Protect your veterans: every genuine Recruit upgrade adds permanent +4% Strength.',
 'STRATEGY':'Domination / Culture. Complexity: 4/5. Develop an Ancient Era core, preserve its experience through upgrades, and fight in a compact formation. Ordinary Recruits also develop, but only five units have legendary roles. Losing a veteran loses its XP and development forever; Headquarters train successors after the cooldown. Siege, ranged support, technology and a sound economy are still essential.',
 'UNIT':'T1 Recruit',
 'UNIT_HELP':'Replaces Warrior with the active Warrior strength, movement, cost and requirements. Scouted Talent: +15% combat experience, retained through upgrades. Legendary Development: each genuine change of unit type through an upgrade adds +4% permanent Strength. The first five qualifying Recruits receive the five roster roles automatically.',
 'UNIT_STRATEGY':'Train your original roster early. Rotate wounded veterans out of danger and budget Gold for upgrades. A new late-game unit has none of the development of a preserved Ancient Era Recruit. Recruits beyond the original five still receive Scouted Talent and develop through upgrades.',
 'UNIT_PEDIA':'Every legend begins as a recruit. T1 scouting identifies potential, but practice, coaching and trust turn it into enduring performance. The Recruit uses the ordinary Warrior model and statistics; its distinction is the history it builds. Genuine upgrades grant permanent strength, never level-ups, healing or promotion purchases.',
 'HQ':'T1 Headquarters',
 'HQ_HELP':'Replaces Barracks and retains all active Barracks properties and training experience. Adds +1 [ICON_CULTURE] Culture and +10% local Production toward land melee military units, excluding ranged and defensive-only units. Enables successor recruitment after a roster vacancy cooldown; only newly produced units qualify, not purchases, captures or gifts.',
 'HQ_STRATEGY':'Build Headquarters before you need a replacement. Its Production modifier applies to the city training the unit and follows normal queue and overflow rules. The first eligible unit completed after a vacancy is ready inherits its role, but receives no XP or development from the lost veteran.',
 'HQ_PEDIA':'Headquarters represent the academy, practice rooms, coaching staff and infrastructure behind a championship roster. Visible brilliance rests on years of preparation. This Barracks replacement supports local military training and Culture; it never creates a free successor.',
 'SCOUTED':'Scouted Talent','SCOUTED_HELP':'+15% experience from combat. Recruit origin marker; retained through genuine upgrades and transfers. Level-ups do not grant Legendary Development.',
 'ZEUS':'Zeus - Top Lane Prodigy','ZEUS_HELP':'+15% Strength when attacking cities. No bonus against ordinary units or on defense. Permanent ZOFGK role: top-lane pressure, duelling and decisive split pushes.',
 'ONER':'Oner - The Initiator','ONER_HELP':'+1 Sight. Double movement through Forest and Jungle using native feature movement; other movement restrictions still apply. Permanent ZOFGK role: jungle pathing, rotations and proactive engagements.',
 'FAKER':'Faker - Unkillable Demon King','FAKER_HELP':'Hostile military units within one hex suffer -10% Strength. Does not stack with another Faker aura. Civilians, friends and neutrals are unaffected. Permanent ZOFGK role: leadership, control and clutch decisions.',
 'GUMAYUSI':'Gumayusi - Unshakeable Carry','GUMAYUSI_HELP':'+15% Strength when attacking wounded enemy military units. Uses damage before combat, with current maximum HP. No bonus against cities, full-health targets or while defending. Permanent ZOFGK role: precision and finishing teamfights.',
 'KERIA':'Keria - Genius Support','KERIA_HELP':'Adjacent friendly military units receive +5 HP during otherwise legal normal healing. Keria cannot support himself. The bonus cannot enable healing after forbidden movement/attacks, while embarked or in prohibited terrain. Does not stack with another Keria aura. Permanent ZOFGK role: protection and adaptability.',
 'SYNERGY_10':'Five as One - Three or Four','SYNERGY_10_HELP':'Temporary +10% Strength. At least three distinct living ZOFGK roles, but fewer than five, are within two hexes including this unit. Replaced by the +15% tier when all five are near.',
 'SYNERGY_15':'Five as One - Full Roster','SYNERGY_15_HELP':'Temporary +15% Strength. All five distinct living ZOFGK roles are within two hexes including this unit. Replaces the +10% tier; the tiers never stack.',
 'PRESSURE':'Demon King Pressure','PRESSURE_HELP':'Temporary -10% Strength while within one hex of an enemy Faker. Removed on movement, death, transfer or peace. Non-stacking; military units only.',
 'SUPPORT':'Keria Support','SUPPORT_HELP':'Temporary +5 HP to otherwise legal normal healing while adjacent to a friendly Keria. Does not heal directly, cannot exceed maximum HP and cannot enable otherwise forbidden healing. Military units only; excludes Keria himself.',
 'ACQUIRED':'Acquired Unit History','ACQUIRED_HELP':'Internal acquisition provenance. This unit was acquired rather than locally created for the initial roster. It keeps legitimate Scouted Talent and development, but cannot automatically claim a roster role. No combat effect.',
 'CIV_PEDIA':'T1 is a Korean esports organization with a legacy rooted in SK Telecom T1. This civilization commemorates the historical ZOFGK lineup: Choi "Zeus" Woo-je (top), Moon "Oner" Hyeon-joon (jungle), Lee "Faker" Sang-hyeok (mid), Lee "Gumayusi" Min-hyeong (ADC) and Ryu "Keria" Min-seok (support).[NEWLINE][NEWLINE]After reaching the 2022 World Championship final and losing a five-game series to DRX, the five returned to win the 2023 title in Seoul against Weibo Gaming. In 2024 they defended the title in London, defeating Bilibili Gaming in another five-game final. The 2023 and 2024 victories became a defining chapter in the organization\'s history. This is a tribute to that historical roster, not a statement about the current team.[NEWLINE][NEWLINE]Five Legends, One Dynasty. The first five Recruits gain roles in Z-O-F-G-K order, including the starting Warrior replacement. Each role survives genuine upgrades. Three or four distinct roles within two hexes grant +10% Strength; all five grant +15% instead. Only roster units benefit. Normal units never count toward the formation.[NEWLINE][NEWLINE]Legendary Development adds +4% permanent Strength per real Recruit upgrade, alongside Scouted Talent\'s +15% combat XP. Level-ups and promotion choices add no development. Death erases that individual\'s XP and history. Lost roles wait 7/10/15/30 turns on Quick/Standard/Epic/Marathon, then go to the next newly produced non-ranged land military unit in a city with a real Headquarters. Purchased units can join the initial Recruit roster, but cannot fill a replacement vacancy. Gifts and captures cannot recruit. A successor receives only its role, never the deceased\'s history.',
 'LEADER_PEDIA':'Lee "Faker" Sang-hyeok became the central figure of SK Telecom T1\'s League of Legends legacy after his professional debut in 2013. Celebrated for mechanical precision, leadership, adaptability and calm under pressure, he became known as the Unkillable Demon King.[NEWLINE][NEWLINE]This tribute focuses on the ZOFGK era. Faker led a roster of developing stars through the heartbreak of the 2022 Worlds final, the 2023 championship in Seoul and a successful title defense in London in 2024. His civilization celebrates the trust and discipline of a team, not invulnerability: preserving veterans and training successors remain essential.',
 'DAWN':'Faker, the Unkillable Demon King, you stand at the heart of a dynasty that transformed five extraordinary individuals into legends. Under your leadership, Zeus, Oner, Gumayusi and Keria rose together, challenging the world\'s greatest and claiming victories that echoed across generations. Your strength was never merely the brilliance of one player, but the trust, discipline and unity of an unforgettable roster.[NEWLINE][NEWLINE]From the 2022 final to back-to-back World Championships in 2023 and 2024, your team forged a legacy through practice and perseverance.[NEWLINE][NEWLINE]Will you discover a new generation of champions, preserve their legacy through the ages, and lead T1 to victory once more?',
 'CIV5_HEADING_1':'Five Legends. One Dynasty.', 'FAKER_NAME':'Faker', 'FAKER_SUBTITLE':'The Unkillable Demon King',
 'FAKER_LIVED':'Born 1996; tribute to the 2022-2024 ZOFGK era','FAKER_TITLES_1':'Mid Laner and Team Leader','FAKER_HEADING_1':'Trust, Discipline and Legacy',
 'GREETING_1':'I am Faker. Five players, one purpose. Let us see what we can build together.',
 'WAR_1':'The time for preparation has passed. We will trust our team and commit.',
 'ATTACKED_1':'We have faced difficult games before. Stay focused; the next decision matters.',
 'DEFEAT_1':'Today belongs to you. We will remember what this team achieved together.',
 'PEACE_1':'Let us learn from this contest and prepare for a better future.',
 'PEACE_OFFER_1':'Both our peoples have fought hard. There is wisdom in choosing the next battle carefully.',
 'FRIENDLY_1':'Welcome. A strong teammate is someone you can trust under pressure.',
 'NEUTRAL_1':'I am listening. What is your plan?', 'HOSTILE_1':'Your movements have not gone unnoticed.',
 'TRADE_1':'Agreed. Good preparation benefits both sides.',
 'NOTICE_TITLE':'ZOFGK - Dynasty Roster',
 'NOTICE_JOIN':'{1_Name} has joined the roster. This unit keeps its own XP and development.',
 'NOTICE_LOST':'{1_Name} is vacant. Recruitment takes {2_Num} turns; then produce a new land melee unit in a city with a real T1 Headquarters.',
 'NOTICE_READY':'{1_Name} can now be recruited. Produce a new land melee military unit in a city with a real T1 Headquarters. Purchases, gifts and captures do not qualify.',
 'PANEL':'ZOFGK Roster','CLOSE':'Close','PANEL_HELP':'Protect the five legends. Only distinct roster roles within two hexes count toward Five as One. Development belongs to each individual unit; a successor inherits only its role.',
 'SLOT_INITIAL':'{1_Name}: awaiting an initial T1 Recruit',
 'SLOT_COOLDOWN':'{1_Name}: vacant - {2_Num} turns remaining',
 'SLOT_READY':'{1_Name}: ready - train a land melee unit at Headquarters',
 'SLOT_ALIVE':'{1_Name}: {2_Unit}[NEWLINE]Development +{3_Num}% / Formation +{4_Num}%',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'],FAKER_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}':n for i,n in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}':n for i,n in enumerate(['Scout','Analyst','Coach','Strategist','Pathfinder','Observer','Playmaker','Academy Mentor','Draftmaster','Team Manager'],1)})
for i in range(1,DEVELOPMENT_TIERS+1):
    TEXT[f'DEVELOPMENT_{i}']=f'Legendary Development - +{i*4}%'
    TEXT[f'DEVELOPMENT_{i}_HELP']=f'+{i*4}% permanent Strength from {i} genuine Recruit upgrades. Exactly +4% per real unit-type upgrade; no reward from level-ups or promotion choices. This is one exclusive cumulative tier, not an additional stacking award. Retained through upgrades.'

def clone(*a,**k): return base_clone(*a,**k).replace('BCClone','T1Z_Clone')
def companions(*a,**k): return base_companions(*a,**k).replace('BCCompanion','T1Z_Companion')

def main():
    d=database();(V/'SQL').mkdir(parents=True,exist_ok=True)
    core="""-- Community Patch v151 events; no Vox Populi dependency.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_PLAYER_TURN','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS',
  'EVENTS_UNIT_UPGRADES','EVENTS_UNIT_PREKILL','EVENTS_UNIT_CAPTURE',
  'EVENTS_MINORS_INTERACTION','EVENTS_MINORS_GIFTS');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_T1Z_RED',0.89,0.0,0.17,1),('COLOR_T1Z_BLACK',0.035,0.035,0.045,1),('COLOR_T1Z_WHITE',1,1,1,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_T1Z','COLOR_T1Z_RED','COLOR_T1Z_BLACK','COLOR_T1Z_WHITE');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_T1Z_ZOFGK','TXT_KEY_T1Z_TRAIT_HELP','TXT_KEY_T1Z_TRAIT');
"""
    core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_T1Z_CIV',ShortDescription='TXT_KEY_T1Z_SHORT',Adjective='TXT_KEY_T1Z_ADJECTIVE',Civilopedia='TXT_KEY_T1Z_CIV_PEDIA',CivilopediaTag='TXT_KEY_T1Z_CIV5',Strategy='TXT_KEY_T1Z_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_T1Z',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_T1Z_DAWN',DawnOfManAudio='',DawnOfManImage='T1Z_Dawn.dds',MapImage='T1Z_Map.dds',PortraitIndex=0,IconAtlas='T1Z_CIV_ATLAS',AlphaIconAtlas='T1Z_ALPHA_ATLAS')
    core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_T1Z_LEADER',Civilopedia='TXT_KEY_T1Z_LEADER_PEDIA',CivilopediaTag='TXT_KEY_T1Z_FAKER',PackageID=None,PortraitIndex=0,IconAtlas='T1Z_LEADER_ATLAS',ArtDefineTag='T1Z_LeaderScene.xml',Boldness=7,VictoryCompetitiveness=9,Loyalty=10,Meanness=2,Chattiness=3)
    core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','{TRAIT}');\n"
    core+=clone('Units','UNIT_WARRIOR',UNIT,Description='TXT_KEY_T1Z_UNIT',Civilopedia='TXT_KEY_T1Z_UNIT_PEDIA',Help='TXT_KEY_T1Z_UNIT_HELP',Strategy='TXT_KEY_T1Z_UNIT_STRATEGY',IconAtlas='T1Z_OBJECT_ATLAS',PortraitIndex=0,UnitFlagAtlas='T1Z_FLAG_ATLAS',UnitFlagIconOffset=0)
    core+=clone('Buildings','BUILDING_BARRACKS',HQ,Description='TXT_KEY_T1Z_HQ',Civilopedia='TXT_KEY_T1Z_HQ_PEDIA',Help='TXT_KEY_T1Z_HQ_HELP',Strategy='TXT_KEY_T1Z_HQ_STRATEGY',IconAtlas='T1Z_OBJECT_ATLAS',PortraitIndex=1)
    core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_WARRIOR','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_BARRACKS','{HQ}');\n"
    for table,key,count in [('Civilization_CityNames','CITY',len(CITIES)),('Civilization_SpyNames','SPY',10)]:
        for i in range(1,count+1): core+=f"INSERT INTO {table} VALUES ('{CIV}','TXT_KEY_T1Z_{key}_{i}');\n"
    personality={'Leader_Flavors','Leader_MajorCivApproachBiases','Leader_MinorCivApproachBiases'}
    skip=tuple(t for t, in d.execute("SELECT name FROM sqlite_master WHERE type='table'") if t not in personality)
    inherit=companions(d,'Leader_','LeaderType','LEADER_WASHINGTON',LEADER,skip)
    for table in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit+=companions(d,table,'CivilizationType','CIVILIZATION_AMERICA',CIV)
    inherit+=companions(d,'Unit_','UnitType','UNIT_WARRIOR',UNIT)
    inherit+=companions(d,'Building_','BuildingType','BUILDING_BARRACKS',HQ)
    inherit+=companions(d,'Unit_ProductionModifierBuildings','BuildingType','BUILDING_BARRACKS',HQ)
    effects='-- Permanent identity and native conditional combat/movement effects.\n'
    def promotion(key,index,**fields):
        nonlocal effects
        values=dict(Type='PROMOTION_T1Z_'+key,Description='TXT_KEY_T1Z_'+key,Help='TXT_KEY_T1Z_'+key+'_HELP',LostWithUpgrade=0,LostOnGifting=0,CannotBeChosen=1,PortraitIndex=index,IconAtlas='T1Z_PROMOTION_ATLAS',PediaType='PEDIA_ATTRIBUTES',PediaEntry='TXT_KEY_T1Z_'+key,**fields)
        effects+='INSERT INTO UnitPromotions('+','.join(values)+') VALUES ('+','.join(str(v) if isinstance(v,int) else "'"+v+"'" for v in values.values())+');\n'
    promotion('SCOUTED',5,ExperiencePercent=15)
    for i,key in enumerate(ROLES): promotion(key,i,**({'CityAttack':15} if key=='ZEUS' else {'VisibilityChange':1} if key=='ONER' else {'AttackWoundedMod':15} if key=='GUMAYUSI' else {}))
    for feature in ['FOREST','JUNGLE']:
        effects+=f"INSERT INTO UnitPromotions_Features(PromotionType,FeatureType,DoubleMove) VALUES ('PROMOTION_T1Z_ONER','FEATURE_{feature}',1);\n"
    promotion('SYNERGY_10',7,CombatPercent=10);promotion('SYNERGY_15',8,CombatPercent=15)
    promotion('PRESSURE',9,CombatPercent=-10)
    promotion('SUPPORT',10,FriendlyHealChange=5,NeutralHealChange=5,EnemyHealChange=5)
    for i in range(1,DEVELOPMENT_TIERS+1): promotion('DEVELOPMENT_'+str(i),6,CombatPercent=4*i)
    # Append after every released promotion: existing IDs remain unchanged.
    promotion('ACQUIRED',5,ShowInUnitPanel=0)
    effects+="""-- Native delayed gifts snapshot BEFORE prekill, then copy AFTER Created.
-- Roles and formation/aura effects never travel as gifting privileges. Return
-- gifts ignore this native flag and are also reconciled by the controller.
UPDATE UnitPromotions SET LostOnGifting=1 WHERE Type IN
 ('PROMOTION_T1Z_ZEUS','PROMOTION_T1Z_ONER','PROMOTION_T1Z_FAKER',
  'PROMOTION_T1Z_GUMAYUSI','PROMOTION_T1Z_KERIA','PROMOTION_T1Z_SYNERGY_10',
  'PROMOTION_T1Z_SYNERGY_15','PROMOTION_T1Z_PRESSURE','PROMOTION_T1Z_SUPPORT');
"""
    effects+=f"INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_T1Z_SCOUTED');\n"
    effects+=f"""-- Add to, rather than replace, the inherited Barracks values.
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{HQ}' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield)
 SELECT '{HQ}','YIELD_CULTURE',1 WHERE NOT EXISTS
 (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{HQ}' AND YieldType='YIELD_CULTURE');
"""
    # The native per-unit building modifier handles mixed combat classes and
    # custom melee classes without Lua production/overflow transactions.
    eligible="""SELECT u.Type FROM Units u WHERE u.Domain='DOMAIN_LAND'
 AND u.Combat>0 AND COALESCE(u.RangedCombat,0)=0
 AND NOT EXISTS (SELECT 1 FROM Unit_FreePromotions f JOIN UnitPromotions p ON p.Type=f.PromotionType
                 WHERE f.UnitType=u.Type AND p.OnlyDefensive=1)"""
    effects+=f"""UPDATE Unit_ProductionModifierBuildings SET ProductionModifier=ProductionModifier+10
 WHERE BuildingType='{HQ}' AND UnitType IN ({eligible});
INSERT INTO Unit_ProductionModifierBuildings(UnitType,BuildingType,ProductionModifier)
 SELECT Type,'{HQ}',10 FROM Units WHERE Type IN ({eligible}) AND NOT EXISTS
 (SELECT 1 FROM Unit_ProductionModifierBuildings b WHERE b.BuildingType='{HQ}' AND b.UnitType=Units.Type);
"""
    for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('ATTACKED','ATTACKED'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('TRADE_ACCEPT_GENEROUS','TRADE'),('TRADE_ACCEPT_ACCEPTABLE','TRADE')]:
        effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_T1Z_{key}_%',1);\n"
    effects+=f"UPDATE Leader_Flavors SET Flavor=9 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_OFFENSE','FLAVOR_MILITARY_TRAINING');\nUPDATE Leader_Flavors SET Flavor=7 WHERE LeaderType='{LEADER}' AND FlavorType='FLAVOR_CULTURE';\n"
    art=''
    for atlas,stem,cols,rows in [('CIV','Icon',1,1),('ALPHA','Alpha',1,1),('OBJECT','Objects',2,1),('LEADER','Portrait',1,1),('PROMOTION','Promotions',4,3)]:
        for size in [16,24,32,45,48,64,80,128,256]: art+=f"INSERT INTO IconTextureAtlases VALUES ('T1Z_{atlas}_ATLAS',{size},'T1Z_{stem}{size}.dds',{cols},{rows});\n"
    art+="INSERT INTO IconTextureAtlases VALUES ('T1Z_FLAG_ATLAS',32,'T1Z_Flag32.dds',1,1);\n"
    text=''.join("INSERT INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_T1Z_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name,content in [('00_T1Z_Core',core),('01_T1Z_Inheritance',inherit),('02_T1Z_Effects',effects),('03_T1Z_Art',art),('10_T1Z_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content,encoding='utf-8',newline='\n')
    print('Generated T1 ZOFGK SQL: active Warrior/Barracks inheritance and',DEVELOPMENT_TIERS,'exclusive development tiers')

if __name__=='__main__':main()
