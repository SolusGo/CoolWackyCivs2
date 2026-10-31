INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,VisibilityChange,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_RFD_INK_MORTAR_SIGHT','TXT_KEY_RFD_SIGHT','TXT_KEY_RFD_SIGHT_HELP',1,1,1,0,'RFD_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_RFD_SIGHT');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_RFD_INK_MORTAR','PROMOTION_RFD_INK_MORTAR_SIGHT');
-- Add to, rather than replace, any inherited Culture.
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE rowid=(SELECT MIN(rowid) FROM Building_YieldChanges WHERE BuildingType='BUILDING_RFD_REVISION_WORKSHOP' AND YieldType='YIELD_CULTURE');
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_RFD_REVISION_WORKSHOP','YIELD_CULTURE',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_RFD_REVISION_WORKSHOP' AND YieldType='YIELD_CULTURE');
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_RFD_SCIENCE_1','BUILDING_RFD_SCIENCE_1','TXT_KEY_RFD_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_RFD_SCIENCE_1','BUILDINGCLASS_RFD_SCIENCE_1','TXT_KEY_RFD_DUMMY','TXT_KEY_RFD_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'RFD_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_RFD_SCIENCE_1','YIELD_SCIENCE',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_RFD_SCIENCE_2','BUILDING_RFD_SCIENCE_2','TXT_KEY_RFD_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_RFD_SCIENCE_2','BUILDINGCLASS_RFD_SCIENCE_2','TXT_KEY_RFD_DUMMY','TXT_KEY_RFD_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'RFD_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_RFD_SCIENCE_2','YIELD_SCIENCE',1);
INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('BUILDINGCLASS_RFD_SCIENCE_3','BUILDING_RFD_SCIENCE_3','TXT_KEY_RFD_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('BUILDING_RFD_SCIENCE_3','BUILDINGCLASS_RFD_SCIENCE_3','TXT_KEY_RFD_DUMMY','TXT_KEY_RFD_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'RFD_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_RFD_SCIENCE_3','YIELD_SCIENCE',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_FIRST_GREETING','TXT_KEY_RFD_GREETING_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_DECLAREWAR','TXT_KEY_RFD_WAR_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_DEFEATED','TXT_KEY_RFD_DEFEAT_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS','TXT_KEY_RFD_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS','TXT_KEY_RFD_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_PEACE_OFFER','TXT_KEY_RFD_PEACE_OFFER_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_GREETING_POLITE_HELLO','TXT_KEY_RFD_FRIENDLY_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_GREETING_NEUTRAL_HELLO','TXT_KEY_RFD_NEUTRAL_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_GREETING_HOSTILE_HELLO','TXT_KEY_RFD_HOSTILE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_ATTACKED','TXT_KEY_RFD_ATTACKED_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_RFD_MARGINALIA','RESPONSE_TRADE_ACCEPT_GENEROUS','TXT_KEY_RFD_TRADE_%',1);
