# Adding a civilization

Each civilization gets its own directory, globally unique `CIVILIZATION_*` identity, database prefix, Lua namespace and event handlers restricted to its own players. Use these files:

```text
CivilizationName/
  README.md
  CHANGELOG.md
  SQL/00_*_Core.sql
  SQL/01_*_Inheritance.sql
  SQL/02_*_Effects.sql
  SQL/03_*_Art.sql
  SQL/10_*_Text.sql
  Lua/
  UI/
  Art/
  docs/Implementation.md
  docs/Testing.md
docs/civilizations/CivilizationName.md
art-source/CivilizationName/
```

The dedicated civ page covers theme, UA/UU/UB, the player flow, strategic strengths/weaknesses and visible limitations. The README explains detailed mechanics, dependencies, installation and AI support. The changelog records dated changes and actual validation, including unverified native behavior.

Update the root roster and collection changelog. Extend the builder's civilization inventory and add one simulation-owning entry point per civilization. Include all gameplay/art files in the ModBuddy project and modinfo, load SQL in numeric order, and keep SQL and UI entry XML out of the VFS. Included Lua modules and textures must be imported.

Validate against the active BNW/CP schema, inherit all relevant replacement companion rows, decode every DDS, parse every Lua source as Lua 5.1, and exercise population/save/event invariants through meaningful tests. Never describe a mock result as an in-game test. Confirm save compatibility before changing a released identity or persistence schema. Avoid permanent frame polling and modifications to global CityView.
