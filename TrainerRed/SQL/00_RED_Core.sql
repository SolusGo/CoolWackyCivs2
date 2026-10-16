-- Authoritative CP v151 events; one Red simulation owner, single-player only.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_NEW_ERA','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES',
  'EVENTS_PLAYER_TURN','EVENTS_BARBARIANS','EVENTS_BATTLES','EVENTS_BATTLES_DAMAGE',
  'EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED','EVENTS_CITY_AIRLIFT','EVENTS_AIRLIFT');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_RED_CRIMSON',0.68,0.055,0.09,1),('COLOR_RED_SILVER',0.93,0.95,0.97,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_RED_INDIGO','COLOR_RED_CRIMSON','COLOR_RED_SILVER','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_RED_LIVING_LEGEND','TXT_KEY_RED_TRAIT_HELP','TXT_KEY_RED_TRAIT');
CREATE TEMP TABLE REDClone AS SELECT * FROM "Civilizations" WHERE Type='CIVILIZATION_AMERICA';
UPDATE REDClone SET "ID"=NULL,"Type"='CIVILIZATION_RED_INDIGO_CHAMPION',"Description"='TXT_KEY_RED_CIV',"ShortDescription"='TXT_KEY_RED_SHORT',"Adjective"='TXT_KEY_RED_ADJECTIVE',"Civilopedia"='TXT_KEY_RED_CIV_PEDIA',"CivilopediaTag"='TXT_KEY_RED_CIV5',"Strategy"='TXT_KEY_RED_STRATEGY',"DefaultPlayerColor"='PLAYERCOLOR_RED_INDIGO',"Playable"=1,"AIPlayable"=1,"PackageID"=NULL,"DawnOfManQuote"='TXT_KEY_RED_DAWN',"DawnOfManAudio"='',"DawnOfManImage"='RED_Dawn.dds',"MapImage"='RED_Map.dds',"PortraitIndex"=0,"IconAtlas"='RED_CIV_ATLAS',"AlphaIconAtlas"='RED_ALPHA_ATLAS';
INSERT INTO "Civilizations" SELECT * FROM REDClone;
DROP TABLE REDClone;
CREATE TEMP TABLE REDClone AS SELECT * FROM "Leaders" WHERE Type='LEADER_WASHINGTON';
UPDATE REDClone SET "ID"=NULL,"Type"='LEADER_RED_TRAINER',"Description"='TXT_KEY_RED_LEADER',"Civilopedia"='TXT_KEY_RED_LEADER_PEDIA',"CivilopediaTag"='TXT_KEY_RED_TRAINER',"PackageID"=NULL,"VictoryCompetitiveness"=9,"WonderCompetitiveness"=6,"Boldness"=8,"DiploBalance"=4,"WarmongerHate"=5,"DenounceWillingness"=2,"DoFWillingness"=2,"Loyalty"=9,"Forgiveness"=3,"Meanness"=2,"Chattiness"=0,"MinorCivCompetitiveness"=3,"PortraitIndex"=0,"IconAtlas"='RED_LEADER_ATLAS',"ArtDefineTag"='RED_LeaderScene.xml';
INSERT INTO "Leaders" SELECT * FROM REDClone;
DROP TABLE REDClone;
INSERT INTO Civilization_Leaders(CivilizationType,LeaderheadType) VALUES ('CIVILIZATION_RED_INDIGO_CHAMPION','LEADER_RED_TRAINER');
INSERT INTO Leader_Traits(LeaderType,TraitType) VALUES ('LEADER_RED_TRAINER','TRAIT_RED_LIVING_LEGEND');
CREATE TEMP TABLE REDClone AS SELECT * FROM "Units" WHERE Type='UNIT_GREAT_GENERAL';
UPDATE REDClone SET "ID"=NULL,"Type"='UNIT_RED_POKEMON_ACE',"Description"='TXT_KEY_RED_ACE',"Help"='TXT_KEY_RED_ACE_HELP',"Civilopedia"='TXT_KEY_RED_ACE_PEDIA',"Strategy"='TXT_KEY_RED_ACE_HELP',"IconAtlas"='RED_OBJECT_ATLAS',"PortraitIndex"=0,"Moves"=3,"UnitFlagAtlas"='RED_FLAG_ATLAS',"UnitFlagIconOffset"=0;
INSERT INTO "Units" SELECT * FROM REDClone;
DROP TABLE REDClone;
CREATE TEMP TABLE REDClone AS SELECT * FROM "Buildings" WHERE Type='BUILDING_HOSPITAL';
UPDATE REDClone SET "ID"=NULL,"Type"='BUILDING_RED_POKEMON_CENTER',"Description"='TXT_KEY_RED_CENTER',"Help"='TXT_KEY_RED_CENTER_HELP',"Civilopedia"='TXT_KEY_RED_CENTER_PEDIA',"Strategy"='TXT_KEY_RED_CENTER_HELP',"IconAtlas"='RED_OBJECT_ATLAS',"PortraitIndex"=1,"PrereqTech"='TECH_BIOLOGY',"GoldMaintenance"=4,"FoodKept"=25,"HealRateChange"=5,"Airlift"=0;
INSERT INTO "Buildings" SELECT * FROM REDClone;
DROP TABLE REDClone;
CREATE TEMP TABLE REDClone AS SELECT * FROM "Buildings" WHERE Type='BUILDING_HEROIC_EPIC';
UPDATE REDClone SET "ID"=NULL,"Type"='BUILDING_RED_INDIGO_PLATEAU',"Description"='TXT_KEY_RED_PLATEAU',"Help"='TXT_KEY_RED_PLATEAU_HELP',"Civilopedia"='TXT_KEY_RED_PLATEAU_PEDIA',"Strategy"='TXT_KEY_RED_PLATEAU_HELP',"IconAtlas"='RED_OBJECT_ATLAS',"PortraitIndex"=2,"MilitaryProductionModifier"=15,"TrainedFreePromotion"='PROMOTION_MORALE';
INSERT INTO "Buildings" SELECT * FROM REDClone;
DROP TABLE REDClone;
INSERT INTO Civilization_UnitClassOverrides(CivilizationType,UnitClassType,UnitType) VALUES ('CIVILIZATION_RED_INDIGO_CHAMPION','UNITCLASS_GREAT_GENERAL','UNIT_RED_POKEMON_ACE');
INSERT INTO Civilization_BuildingClassOverrides(CivilizationType,BuildingClassType,BuildingType) VALUES ('CIVILIZATION_RED_INDIGO_CHAMPION','BUILDINGCLASS_HOSPITAL','BUILDING_RED_POKEMON_CENTER');
INSERT INTO Civilization_BuildingClassOverrides(CivilizationType,BuildingClassType,BuildingType) VALUES ('CIVILIZATION_RED_INDIGO_CHAMPION','BUILDINGCLASS_HEROIC_EPIC','BUILDING_RED_INDIGO_PLATEAU');
