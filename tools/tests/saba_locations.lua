local D = GameInfoTypes.TERRAIN_DESERT
local grass = -100
local a = MakeCity(0, 1, 1, D, true, false)
local b = MakeCity(0, 2, 1, D, false, false)
local c = MakeCity(0, 3, 1, grass, true, false)
local d = MakeCity(0, 4, 1, grass, false, false)
local e = MakeCity(0, 5, 1, D, false, true)
local f = MakeCity(0, 6, 1, D, true, false, 'FLOOD_PLAINS')
local peer = MakeCity(1, 7, 1, D, true, true)
peer.b[99999] = 7
LoadSaba()
Counts(a, 1, 1); Counts(b, 0, 1); Counts(c, 1, 0)
Counts(d, 0, 0); Counts(e, 0, 1); Counts(f, 1, 1); Counts(peer, 0, 0)
assert(peer.b[99999] == 7)
-- Harvest reads the actual SQL dummy yields, supplied by Python.
local food, prod, culture = Harvest(a)
assert(food == 1 and prod == 1 and culture == 1)
food, prod, culture = Harvest(b); assert(food == 0 and prod == 0 and culture == 1)
food, prod, culture = Harvest(c); assert(food == 1 and prod == 1 and culture == 0)
food, prod, culture = Harvest(d); assert(food == 0 and prod == 0 and culture == 0)
local before = writes
for i = 1, 100 do GameEvents.PlayerDoTurn.Fire(0); GameEvents.PlayerDoTurn.Fire(1) end
Events.SequenceGameInitComplete.Fire()
LoadSaba()
assert(writes == before, 'unnecessary writes or bonus stacking')
assert(#GameEvents.PlayerDoTurn.handlers == 1, 'duplicate controller')
assert(plotLookups == 0, 'turn processing should iterate cities, not map plots')
-- Neighboring Desert/river terrain does not make a grassland center qualify.
plots['4:1'].neighborTerrain = D; plots['4:1'].neighborRiver = true
GameEvents.PlayerDoTurn.Fire(0); Counts(d, 0, 0)
local born = MakeCity(0, 20, 1, D, true, true)
GameEvents.PlayerCityFounded.Fire(0, 20, 1); Counts(born, 1, 1)
print('PASS Saba location/SQL yield matrix, Desert Hills/features, independent cities, birth, no stacking/writes or neighbor substitution')
