"""Generate Saba SQL using the installed BNW + CP v151 schema and active rows."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R=Path(__file__).resolve().parents[1]
V=R/'KingdomOfSaba'
CIV='CIVILIZATION_SABA'
LEADER='LEADER_SABA_KARIBIL_WATAR'
UNIT='UNIT_SABA_WADI_SENTINEL'
CISTERN='BUILDING_SABA_MARIB_CISTERN'
PROMOTION='PROMOTION_SABA_WADI_GUARD'
DUMMIES=['RIVER','DESERT']
CITIES=["Ma'rib",'Sirwah','Nashq','Nashshan','Baraqish','Kaminahu','Haram',
        'Jidfir ibn Munaykhir','Al-Asahil','Wadi Raghwan','Jabal al-Lawdh',
        'Qarnaw','Timna','Shabwah','Hajar Yahirr','Hajar Kuhlan',"Na'it",'Raybun',
        "Zafar",'Baynun','Ghayman','Hawlan','Najran']
TEXT={
 'CIV':'The Kingdom of Saba','SHORT':'Saba','ADJECTIVE':'Sabaean',
 'LEADER':"Karib'il Watar",'TRAIT':'Where the Desert Blooms',
 'TRAIT_HELP':'Cities on Rivers receive +1 [ICON_FOOD] Food and +1 [ICON_PRODUCTION] Production. Cities founded on Desert (including Desert Hills) receive +1 [ICON_CULTURE] Culture. These flat city bonuses stack and apply while Saba controls the city, including acquired cities.',
 'UNIT':'Wadi Sentinel',
 'UNIT_HELP':'Replaces Spearman, retaining its normal Community Patch properties. +15% Combat Strength when defending on Desert, including Desert Hills, and +1 Sight. Both unique bonuses are lost on upgrade.',
 'UNIT_STRATEGY':'Station Wadi Sentinels on Desert approaches to your settlements. Their extra Sight helps identify threats. The unique strength bonus applies only while defending on the unit\'s own Desert tile; it gives no attacking bonus and does not require friendly territory. Upgrade normally when stronger units become available.',
 'UNIT_PEDIA':'The Wadi Sentinel represents the guards of South Arabian settlements and the channels that sustained them. A spear and shield could protect a caravan road or a sluice gate; knowledge of dry valleys mattered as much as equipment. This historically inspired unit uses the ordinary Spearman model. Its unique defensive training and extra Sight expire on upgrade.',
 'CISTERN':"Ma'rib Cistern",
 'CISTERN_HELP':'Replaces Water Mill and retains all its normal Community Patch benefits and construction requirements. Adds +1 [ICON_FOOD] Food and +1 [ICON_GOLD] Gold as flat city yields.',
 'CISTERN_STRATEGY':'Build Cisterns wherever the normal Water Mill is legal. Their additional Food supports growth and their Gold helps the treasury. In a Desert River city, the Cistern and civilization ability together add +2 Food, +1 Production, +1 Culture and +1 Gold beyond an ordinary Water Mill.',
 'CISTERN_PEDIA':'Ancient Ma\'rib depended on the management of seasonal water. Dressed-stone structures guided floodwater into channels and fields, supporting an oasis at the edge of the desert. The Ma\'rib Cistern is a small-scale gameplay tribute to that engineering tradition, rather than a claim that the ancient city used a medieval water-powered mill.',
 'CIV_PEDIA':'Saba was an ancient kingdom of South Arabia, centered on Ma\'rib in present-day Yemen. Its communities combined farming in an arid landscape with exchange along the incense routes. Temples, inscriptions and monumental masonry preserve evidence of a prosperous and organized society.[NEWLINE][NEWLINE]Water management made cultivation possible. Sluices and canals distributed seasonal flows to fields around Ma\'rib. This civilization represents that tradition through modest city yields; it does not transform Desert tiles or spread irrigation.',
 'LEADER_PEDIA':'Karib\'il Watar was a ruler of early Saba whose inscriptions at Sirwah describe campaigns, alliances and the organization of territory. Royal power joined military action with control over settlements, land and water. The chronology of early Sabaean rulers remains a subject of scholarship.[NEWLINE][NEWLINE]Here he leads a historically inspired kingdom focused on prosperous settlements. His portrait and diplomacy are original artistic interpretations, not surviving likenesses or quotations.',
 'STRATEGY':'Seek River sites for Food and Production, and Desert city centers for Culture. The bonuses stack, including on Desert Hills. Develop Ma\'rib Cisterns under the normal Water Mill requirements and defend vulnerable Desert settlements with Wadi Sentinels. Growth supports Science, while settlement Culture supports Social Policies; the ability grants neither direct Science nor Tourism.',
 'DAWN':"Karib'il Watar, ruler of mighty Saba, the people of the southern deserts look to your wisdom once more.[NEWLINE][NEWLINE]Where others see barren earth, your people see fertile valleys waiting to be awakened. Through ingenious irrigation and enduring determination, your kingdom has prospered beneath the desert sun.[NEWLINE][NEWLINE]Guard the waters of your homeland, strengthen the cities of your people, and let the wealth of Saba spread across the known world.[NEWLINE][NEWLINE]Will you transform the desert into a land of abundance, and build a kingdom remembered throughout the ages?",
 'PROMOTION':'Guardian of the Wadi','PROMOTION_HELP':'+15% Combat Strength when defending on Desert, including Desert Hills. +1 Sight. Lost on upgrade.',
 'DUMMY':'Sabaean Water Management','DUMMY_HELP':'Automatically maintained city-location yields. Cannot be constructed, purchased or sold.',
 'GREETING_1':"I am Karib'il Watar of Saba. May your journey find shade, clear water and an honorable welcome.",
 'WAR_1':'You have threatened the peace of our valleys. The spears of Saba will answer.',
 'DEFEAT_1':'Our gates have fallen. May those who follow remember how we brought water to the desert.',
 'PEACE_1':'Let the fields be tended and the roads opened again. Saba accepts this peace.',
 'PEACE_OFFER_1':'Our peoples have paid enough for war. Let us restore the channels of peace.',
 'FRIENDLY_1':'A trusted guest returns. Come, let us speak where the water runs cool.',
 'NEUTRAL_1':'You stand before the ruler of Saba. State your purpose.',
 'HOSTILE_1':'Your promises have grown as dry as an empty channel. Speak carefully.',
 'ATTACKED_1':'You would take the waters we have guarded for generations? Our people will resist.',
 'TRADE_1':'An honorable exchange. May our merchants travel safely between our lands.',
 'CIV5_HEADING_1':'The Valleys of Saba',
 'KARIBIL_NAME':"Karib'il Watar",'KARIBIL_SUBTITLE':'Ruler of Saba',
 'KARIBIL_LIVED':'Early first millennium BCE','KARIBIL_TITLES_1':'Mukarrib of Saba',
 'KARIBIL_HEADING_1':'Land, Water and Royal Power',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'],KARIBIL_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}':s for i,s in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}':s for i,s in enumerate(['Yada\'il','Sumhu\'ali','Dhamar\'ali','Yitha\'amar','Hawfi\'amm','Abikarib','Ilsharah','Nashakarib','Yakrubmalik','Wahab\'il'],1)})

def clone(*a,**k): return base_clone(*a,**k).replace('BCClone','SABAClone')
def companions(*a,**k): return base_companions(*a,**k).replace('BCCompanion','SABACompanion')

def main():
    d=database();(V/'SQL').mkdir(parents=True,exist_ok=True)
    assert {'PromotionType','TerrainType','Attack','Defense'} <= {r[1] for r in d.execute('PRAGMA table_info(UnitPromotions_TerrainModifiers)')}
    core="""-- BNW + Community Patch v151. No native or peer gameplay rows are changed.
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_SABA_TEAL',0.035,0.28,0.29,1),('COLOR_SABA_GOLD',0.91,0.70,0.33,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_SABA','COLOR_SABA_TEAL','COLOR_SABA_GOLD','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_SABA_DESERT_BLOOMS','TXT_KEY_SABA_TRAIT_HELP','TXT_KEY_SABA_TRAIT');
"""
    core+=clone('Civilizations','CIVILIZATION_ARABIA',CIV,Description='TXT_KEY_SABA_CIV',ShortDescription='TXT_KEY_SABA_SHORT',Adjective='TXT_KEY_SABA_ADJECTIVE',Civilopedia='TXT_KEY_SABA_CIV_PEDIA',CivilopediaTag='TXT_KEY_SABA_CIV5',Strategy='TXT_KEY_SABA_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_SABA',Playable=1,AIPlayable=0,PackageID=None,DawnOfManQuote='TXT_KEY_SABA_DAWN',DawnOfManAudio='',DawnOfManImage='SABA_Dawn.dds',MapImage='SABA_Map.dds',PortraitIndex=0,IconAtlas='SABA_CIV_ATLAS',AlphaIconAtlas='SABA_ALPHA_ATLAS')
    core+=clone('Leaders','LEADER_HARUN_AL_RASHID',LEADER,Description='TXT_KEY_SABA_LEADER',Civilopedia='TXT_KEY_SABA_LEADER_PEDIA',CivilopediaTag='TXT_KEY_SABA_KARIBIL',PackageID=None,PortraitIndex=0,IconAtlas='SABA_LEADER_ATLAS',ArtDefineTag='SABA_LeaderScene.xml',DoFWillingness=6,DiploBalance=7,Loyalty=7,Chattiness=4,Meanness=3)
    core+=f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_SABA_DESERT_BLOOMS');\n"
    core+=clone('Units','UNIT_SPEARMAN',UNIT,Description='TXT_KEY_SABA_UNIT',Civilopedia='TXT_KEY_SABA_UNIT_PEDIA',Help='TXT_KEY_SABA_UNIT_HELP',Strategy='TXT_KEY_SABA_UNIT_STRATEGY',IconAtlas='SABA_OBJECT_ATLAS',PortraitIndex=1,UnitFlagAtlas='SABA_FLAG_ATLAS',UnitFlagIconOffset=0)
    core+=clone('Buildings','BUILDING_WATERMILL',CISTERN,Description='TXT_KEY_SABA_CISTERN',Civilopedia='TXT_KEY_SABA_CISTERN_PEDIA',Help='TXT_KEY_SABA_CISTERN_HELP',Strategy='TXT_KEY_SABA_CISTERN_STRATEGY',IconAtlas='SABA_OBJECT_ATLAS',PortraitIndex=0)
    core+=f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_SPEARMAN','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_WATERMILL','{CISTERN}');\n"
    for i in range(1,len(CITIES)+1):core+=f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_SABA_CITY_{i}');\n"
    for i in range(1,11):core+=f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_SABA_SPY_{i}');\n"
    inherit=companions(d,'Leader_','LeaderType','LEADER_HARUN_AL_RASHID',LEADER,('Leader_Traits',))
    for t in ['Civilization_FreeBuildingClasses','Civilization_FreeTechs','Civilization_FreeUnits']:
        inherit+=companions(d,t,'CivilizationType','CIVILIZATION_ARABIA',CIV)
    inherit+=companions(d,'Unit_','UnitType','UNIT_SPEARMAN',UNIT)
    inherit+=companions(d,'Building_','BuildingType','BUILDING_WATERMILL',CISTERN)
    effects=f"""-- This CP table works on underlying Desert even with Flood Plains/Oasis/cities.
-- UnitPromotions_Terrain (singular) is absent; the old plural Terrains table
-- suppresses its combat bonus on features. Do not apply both tables.
INSERT INTO UnitPromotions(Type,Description,Help,VisibilityChange,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('{PROMOTION}','TXT_KEY_SABA_PROMOTION','TXT_KEY_SABA_PROMOTION_HELP',1,1,1,1,'SABA_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_SABA_PROMOTION');
INSERT INTO UnitPromotions_TerrainModifiers(PromotionType,TerrainType,Attack,Defense)
 VALUES ('{PROMOTION}','TERRAIN_DESERT',0,15);
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','{PROMOTION}');
"""
    for y in ['FOOD','GOLD']:
        effects+=f"""UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='{CISTERN}' AND YieldType='YIELD_{y}';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{CISTERN}','YIELD_{y}',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{CISTERN}' AND YieldType='YIELD_{y}');
"""
    for suffix in DUMMIES:
        effects+=f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_SABA_{suffix}','BUILDING_SABA_{suffix}','TXT_KEY_SABA_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_SABA_{suffix}','BUILDINGCLASS_SABA_{suffix}','TXT_KEY_SABA_DUMMY','TXT_KEY_SABA_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'SABA_CIV_ATLAS',0);
"""
    effects+="""INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES
 ('BUILDING_SABA_RIVER','YIELD_FOOD',1),('BUILDING_SABA_RIVER','YIELD_PRODUCTION',1),
 ('BUILDING_SABA_DESERT','YIELD_CULTURE',1);
"""
    for response,key in [('FIRST_GREETING','GREETING'),('DECLAREWAR','WAR'),('DEFEATED','DEFEAT'),('PEACE_MADE_BY_HUMAN_GRACIOUS','PEACE'),('PEACE_MADE_BY_HUMAN_UNGRACIOUS','PEACE'),('PEACE_OFFER','PEACE_OFFER'),('GREETING_POLITE_HELLO','FRIENDLY'),('GREETING_NEUTRAL_HELLO','NEUTRAL'),('GREETING_HOSTILE_HELLO','HOSTILE'),('ATTACKED','ATTACKED'),('TRADE_ACCEPT_GENEROUS','TRADE')]:
        effects+=f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_SABA_{key}_%',1);\n"
    effects+=f"UPDATE Leader_Flavors SET Flavor=7 WHERE LeaderType='{LEADER}' AND FlavorType IN ('FLAVOR_SCIENCE','FLAVOR_CULTURE','FLAVOR_GROWTH');\n"
    art=''
    for atlas,stem,cols in [('CIV','Icon',1),('ALPHA','Alpha',1),('OBJECT','Objects',2),('LEADER','Portrait',1)]:
        for size in [16,24,32,45,48,64,80,128,256]:art+=f"INSERT INTO IconTextureAtlases VALUES ('SABA_{atlas}_ATLAS',{size},'SABA_{stem}{size}.dds',{cols},1);\n"
    art+="INSERT INTO IconTextureAtlases VALUES ('SABA_FLAG_ATLAS',32,'SABA_Flag32.dds',1,1);\n"
    text=''.join("INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_SABA_"+k+"','"+v.replace("'","''")+"');\n" for k,v in sorted(TEXT.items()))
    for name,content in [('00_SABA_Core',core),('01_SABA_Inheritance',inherit),('02_SABA_Effects',effects),('03_SABA_Art',art),('10_SABA_Text',text)]:
        (V/'SQL'/f'{name}.sql').write_text(content,encoding='utf-8',newline='\n')
    print('Generated Saba active Spearman/Water Mill inheritance, two city dummies, native promotion, identity and English text')

if __name__=='__main__':main()
