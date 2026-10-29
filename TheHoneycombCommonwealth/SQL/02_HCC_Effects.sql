-- Unique Sight disappears on upgrade; the Scout's own promotions are inherited separately.
INSERT INTO UnitPromotions(Type,Description,Help,VisibilityChange,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_HCC_FORAGER_SIGHT','TXT_KEY_HCC_PROMOTION','TXT_KEY_HCC_PROMOTION_HELP',1,1,1,0,'HCC_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_HCC_PROMOTION');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_HCC_FORAGER','PROMOTION_HCC_FORAGER_SIGHT');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='BUILDING_HCC_HONEY_EXCHANGE' AND YieldType='YIELD_FOOD';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_HCC_HONEY_EXCHANGE','YIELD_FOOD',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_HCC_HONEY_EXCHANGE' AND YieldType='YIELD_FOOD');
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_PRODUCTION_1','BUILDING_HCC_PRODUCTION_1','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_PRODUCTION_1','BUILDINGCLASS_HCC_PRODUCTION_1','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_PRODUCTION_1','YIELD_PRODUCTION',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_PRODUCTION_2','BUILDING_HCC_PRODUCTION_2','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_PRODUCTION_2','BUILDINGCLASS_HCC_PRODUCTION_2','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_PRODUCTION_2','YIELD_PRODUCTION',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_PRODUCTION_3','BUILDING_HCC_PRODUCTION_3','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_PRODUCTION_3','BUILDINGCLASS_HCC_PRODUCTION_3','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_PRODUCTION_3','YIELD_PRODUCTION',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_PRODUCTION_4','BUILDING_HCC_PRODUCTION_4','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_PRODUCTION_4','BUILDINGCLASS_HCC_PRODUCTION_4','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_PRODUCTION_4','YIELD_PRODUCTION',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_CULTURE','BUILDING_HCC_CULTURE','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_CULTURE','BUILDINGCLASS_HCC_CULTURE','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_CULTURE','YIELD_CULTURE',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_GOLD_1','BUILDING_HCC_GOLD_1','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_GOLD_1','BUILDINGCLASS_HCC_GOLD_1','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_GOLD_1','YIELD_GOLD',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES
 ('BUILDINGCLASS_HCC_GOLD_2','BUILDING_HCC_GOLD_2','TXT_KEY_HCC_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_HCC_GOLD_2','BUILDINGCLASS_HCC_GOLD_2','TXT_KEY_HCC_DUMMY','TXT_KEY_HCC_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'HCC_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_HCC_GOLD_2','YIELD_GOLD',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_FIRST_GREETING','TXT_KEY_HCC_GREETING_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_DECLAREWAR','TXT_KEY_HCC_WAR_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_DEFEATED','TXT_KEY_HCC_DEFEAT_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS','TXT_KEY_HCC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS','TXT_KEY_HCC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_PEACE_OFFER','TXT_KEY_HCC_PEACE_OFFER_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_GREETING_POLITE_HELLO','TXT_KEY_HCC_FRIENDLY_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_GREETING_NEUTRAL_HELLO','TXT_KEY_HCC_NEUTRAL_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_GREETING_HOSTILE_HELLO','TXT_KEY_HCC_HOSTILE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_ATTACKED','TXT_KEY_HCC_ATTACKED_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_HCC_MELLIA','RESPONSE_TRADE_ACCEPT_GENEROUS','TXT_KEY_HCC_TRADE_%',1);
UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='LEADER_HCC_MELLIA' AND FlavorType IN ('FLAVOR_SCIENCE','FLAVOR_CULTURE','FLAVOR_GROWTH','FLAVOR_TILE_IMPROVEMENT');
