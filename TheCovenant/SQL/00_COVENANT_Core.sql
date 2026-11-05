-- Brave New World. New rows only; no changes to existing civilizations or assets.
INSERT INTO Colors (Type, Red, Green, Blue, Alpha) VALUES
 ('COLOR_COVENANT_INK', 0.055, 0.10, 0.18, 1.0),
 ('COLOR_COVENANT_GOLD', 0.91, 0.76, 0.36, 1.0);
INSERT INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor) VALUES
 ('PLAYERCOLOR_COVENANT_MEMORY', 'COLOR_COVENANT_INK', 'COLOR_COVENANT_GOLD', 'COLOR_PLAYER_WHITE_TEXT');

INSERT INTO Civilizations
 (Type, Description, ShortDescription, Adjective, Civilopedia, CivilopediaTag,
  Strategy, DefaultPlayerColor, ArtDefineTag, ArtStyleType, ArtStyleSuffix,
  ArtStylePrefix, PortraitIndex, IconAtlas, AlphaIconAtlas, MapImage,
  DawnOfManQuote, DawnOfManImage, SoundtrackTag, Playable, AIPlayable)
SELECT 'CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_DESC', 'TXT_KEY_COVENANT_SHORT',
 'TXT_KEY_COVENANT_ADJECTIVE', 'TXT_KEY_COVENANT_PEDIA', 'TXT_KEY_CIV5_COVENANT',
 'TXT_KEY_COVENANT_STRATEGY', 'PLAYERCOLOR_COVENANT_MEMORY', ArtDefineTag,
 ArtStyleType, ArtStyleSuffix, ArtStylePrefix, PortraitIndex, IconAtlas,
 AlphaIconAtlas, MapImage, 'TXT_KEY_COVENANT_DAWN', DawnOfManImage,
 SoundtrackTag, 1, 0
FROM Civilizations WHERE Type = 'CIVILIZATION_EGYPT';

INSERT INTO Leaders
 (Type, Description, Civilopedia, CivilopediaTag, ArtDefineTag,
  VictoryCompetitiveness, WonderCompetitiveness, Boldness, DiploBalance,
  WarmongerHate, DoFWillingness, Loyalty, Forgiveness, PortraitIndex, IconAtlas)
SELECT 'LEADER_COVENANT_SCRIBE', 'TXT_KEY_COVENANT_LEADER', 'TXT_KEY_COVENANT_LEADER_PEDIA',
 'TXT_KEY_CIVILOPEDIA_LEADERS_COVENANT', ArtDefineTag, 4, 7, 3, 7, 8, 8, 8, 7,
 PortraitIndex, IconAtlas FROM Leaders WHERE Type = 'LEADER_RAMESSES';

INSERT INTO Traits (Type, Description, ShortDescription, CityCultureBonus)
VALUES ('TRAIT_COVENANT_WRITTEN_HEART', 'TXT_KEY_COVENANT_TRAIT', 'TXT_KEY_COVENANT_TRAIT_SHORT', 1);
INSERT INTO Leader_Traits (LeaderType, TraitType)
VALUES ('LEADER_COVENANT_SCRIBE', 'TRAIT_COVENANT_WRITTEN_HEART');
INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType)
VALUES ('CIVILIZATION_COVENANT_MEMORY', 'LEADER_COVENANT_SCRIBE');

INSERT INTO Civilization_FreeUnits (CivilizationType, UnitClassType, UnitAIType, Count)
SELECT 'CIVILIZATION_COVENANT_MEMORY', UnitClassType, UnitAIType, Count
FROM Civilization_FreeUnits WHERE CivilizationType = 'CIVILIZATION_EGYPT';
INSERT INTO Civilization_FreeTechs (CivilizationType, TechType)
SELECT 'CIVILIZATION_COVENANT_MEMORY', TechType FROM Civilization_FreeTechs WHERE CivilizationType = 'CIVILIZATION_EGYPT';
INSERT INTO Civilization_FreeBuildingClasses (CivilizationType, BuildingClassType)
SELECT 'CIVILIZATION_COVENANT_MEMORY', BuildingClassType FROM Civilization_FreeBuildingClasses WHERE CivilizationType = 'CIVILIZATION_EGYPT';
INSERT INTO Civilization_Start_Along_River (CivilizationType, StartAlongRiver)
VALUES ('CIVILIZATION_COVENANT_MEMORY', 1);

-- Native building models are inherited; 03_COVENANT_Art.sql replaces the 2D portraits.
INSERT INTO Buildings
 (Type, BuildingClass, Description, Civilopedia, Strategy, Help, Cost, FaithCost,
  PrereqTech, GoldMaintenance, HurryCostModifier, MinAreaSize, ConquestProb,
  ArtDefineTag, PortraitIndex, IconAtlas, NeverCapture, ArtInfoCulturalVariation,
  ArtInfoEraVariation, ArtInfoRandomVariation)
SELECT 'BUILDING_COVENANT_SCRIPTORIUM', BuildingClass, 'TXT_KEY_COVENANT_SCRIPTORIUM',
 'TXT_KEY_COVENANT_SCRIPTORIUM_PEDIA', 'TXT_KEY_COVENANT_SCRIPTORIUM_STRATEGY',
 'TXT_KEY_COVENANT_SCRIPTORIUM_HELP', Cost, FaithCost, PrereqTech, GoldMaintenance,
 HurryCostModifier, MinAreaSize, ConquestProb, ArtDefineTag, PortraitIndex,
 IconAtlas, NeverCapture, ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation
FROM Buildings WHERE Type = 'BUILDING_SHRINE';

INSERT INTO Buildings
 (Type, BuildingClass, Description, Civilopedia, Strategy, Help, Cost, FaithCost,
  PrereqTech, GoldMaintenance, HurryCostModifier, MinAreaSize, ConquestProb,
  ArtDefineTag, PortraitIndex, IconAtlas, NeverCapture, ArtInfoCulturalVariation,
  ArtInfoEraVariation, ArtInfoRandomVariation)
SELECT 'BUILDING_COVENANT_TABERNACLE', BuildingClass, 'TXT_KEY_COVENANT_TABERNACLE',
 'TXT_KEY_COVENANT_TABERNACLE_PEDIA', 'TXT_KEY_COVENANT_TABERNACLE_STRATEGY',
 'TXT_KEY_COVENANT_TABERNACLE_HELP', Cost, FaithCost, PrereqTech, GoldMaintenance,
 HurryCostModifier, MinAreaSize, ConquestProb, ArtDefineTag, PortraitIndex,
 IconAtlas, NeverCapture, ArtInfoCulturalVariation, ArtInfoEraVariation, ArtInfoRandomVariation
FROM Buildings WHERE Type = 'BUILDING_TEMPLE';

INSERT INTO Civilization_BuildingClassOverrides (CivilizationType, BuildingClassType, BuildingType) VALUES
 ('CIVILIZATION_COVENANT_MEMORY', 'BUILDINGCLASS_SHRINE', 'BUILDING_COVENANT_SCRIPTORIUM'),
 ('CIVILIZATION_COVENANT_MEMORY', 'BUILDINGCLASS_TEMPLE', 'BUILDING_COVENANT_TABERNACLE');
INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield) VALUES
 ('BUILDING_COVENANT_SCRIPTORIUM', 'YIELD_FAITH', 2),
 ('BUILDING_COVENANT_SCRIPTORIUM', 'YIELD_CULTURE', 1),
 ('BUILDING_COVENANT_TABERNACLE', 'YIELD_FAITH', 3),
 ('BUILDING_COVENANT_TABERNACLE', 'YIELD_SCIENCE', 1);
INSERT INTO Building_ClassesNeededInCity (BuildingType, BuildingClassType)
SELECT 'BUILDING_COVENANT_TABERNACLE', BuildingClassType
FROM Building_ClassesNeededInCity WHERE BuildingType = 'BUILDING_TEMPLE';
INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT 'BUILDING_COVENANT_SCRIPTORIUM', FlavorType, Flavor FROM Building_Flavors WHERE BuildingType = 'BUILDING_SHRINE';
INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT 'BUILDING_COVENANT_TABERNACLE', FlavorType, Flavor FROM Building_Flavors WHERE BuildingType = 'BUILDING_TEMPLE';

INSERT INTO Civilization_CityNames (CivilizationType, CityName) VALUES
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_1'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_2'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_3'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_4'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_5'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_6'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_7'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_8'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_9'),
 ('CIVILIZATION_COVENANT_MEMORY', 'TXT_KEY_COVENANT_CITY_10');
