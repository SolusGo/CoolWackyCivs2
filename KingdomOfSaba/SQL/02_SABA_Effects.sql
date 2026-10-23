-- This CP table works on underlying Desert even with Flood Plains/Oasis/cities.
-- UnitPromotions_Terrain (singular) is absent; the old plural Terrains table
-- suppresses its combat bonus on features. Do not apply both tables.
INSERT INTO UnitPromotions(Type,Description,Help,VisibilityChange,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_SABA_WADI_GUARD','TXT_KEY_SABA_PROMOTION','TXT_KEY_SABA_PROMOTION_HELP',1,1,1,1,'SABA_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_SABA_PROMOTION');
INSERT INTO UnitPromotions_TerrainModifiers(PromotionType,TerrainType,Attack,Defense)
 VALUES ('PROMOTION_SABA_WADI_GUARD','TERRAIN_DESERT',0,15);
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_SABA_WADI_SENTINEL','PROMOTION_SABA_WADI_GUARD');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='BUILDING_SABA_MARIB_CISTERN' AND YieldType='YIELD_FOOD';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_SABA_MARIB_CISTERN','YIELD_FOOD',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_SABA_MARIB_CISTERN' AND YieldType='YIELD_FOOD');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='BUILDING_SABA_MARIB_CISTERN' AND YieldType='YIELD_GOLD';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_SABA_MARIB_CISTERN','YIELD_GOLD',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_SABA_MARIB_CISTERN' AND YieldType='YIELD_GOLD');
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_SABA_RIVER','BUILDING_SABA_RIVER','TXT_KEY_SABA_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_SABA_RIVER','BUILDINGCLASS_SABA_RIVER','TXT_KEY_SABA_DUMMY','TXT_KEY_SABA_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'SABA_CIV_ATLAS',0);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_SABA_DESERT','BUILDING_SABA_DESERT','TXT_KEY_SABA_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_SABA_DESERT','BUILDINGCLASS_SABA_DESERT','TXT_KEY_SABA_DUMMY','TXT_KEY_SABA_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'SABA_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES
 ('BUILDING_SABA_RIVER','YIELD_FOOD',1),('BUILDING_SABA_RIVER','YIELD_PRODUCTION',1),
 ('BUILDING_SABA_DESERT','YIELD_CULTURE',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_FIRST_GREETING','TXT_KEY_SABA_GREETING_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_DECLAREWAR','TXT_KEY_SABA_WAR_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_DEFEATED','TXT_KEY_SABA_DEFEAT_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS','TXT_KEY_SABA_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS','TXT_KEY_SABA_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_PEACE_OFFER','TXT_KEY_SABA_PEACE_OFFER_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_GREETING_POLITE_HELLO','TXT_KEY_SABA_FRIENDLY_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_GREETING_NEUTRAL_HELLO','TXT_KEY_SABA_NEUTRAL_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_GREETING_HOSTILE_HELLO','TXT_KEY_SABA_HOSTILE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_ATTACKED','TXT_KEY_SABA_ATTACKED_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_SABA_KARIBIL_WATAR','RESPONSE_TRADE_ACCEPT_GENEROUS','TXT_KEY_SABA_TRADE_%',1);
UPDATE Leader_Flavors SET Flavor=7 WHERE LeaderType='LEADER_SABA_KARIBIL_WATAR' AND FlavorType IN ('FLAVOR_SCIENCE','FLAVOR_CULTURE','FLAVOR_GROWTH');
