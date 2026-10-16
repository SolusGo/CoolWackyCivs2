-- Optional metadata tables found in the development cache. Existing inherited
-- collection SQL copies them when present, but standalone BNW/CP does not
-- require the corresponding third-party mods. Never replace populated tables.
CREATE TABLE IF NOT EXISTS Leader_SharedTraits (
 LeaderType TEXT REFERENCES Leaders(Type) DEFAULT NULL,
 TraitOne TEXT REFERENCES Policies(Type) DEFAULT NULL,
 TraitTwo TEXT REFERENCES Policies(Type) DEFAULT NULL
);
CREATE TABLE IF NOT EXISTS Building_JFD_District (
 BuildingType TEXT REFERENCES Buildings(Type) DEFAULT NULL,
 DistrictType TEXT DEFAULT NULL
);
