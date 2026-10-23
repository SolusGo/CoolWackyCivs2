local D = GameInfoTypes.TERRAIN_DESERT
local c = MakeCity(0, 1, 1, D, true, false)
LoadSaba(); Counts(c, 1, 1)
-- Save reconstruction retains only native building counts and plot/owner data.
local saved = {}
for k, n in pairs(c.b) do saved[k] = n end
Raze(c)
local restored = MakeCity(0, 1, 1, D, true, false)
restored.b = saved
ResetContext(); LoadSaba(); Counts(restored, 1, 1)
-- Load after ownership changed and without any city markers.
Transfer(restored, 1, false)
ResetContext(); LoadSaba(); Counts(restored, 0, 0)
Transfer(restored, 0, false); restored.b = {}
ResetContext(); LoadSaba(); Counts(restored, 1, 1)
-- Large empire plus non-Saba peers. No frame hooks or plot enumeration exists.
local cities = {}
for i = 1, 256 do
  cities[i] = MakeCity(i % 2, 10 + i, 10, i % 3 == 0 and D or -100, i % 5 == 0, i % 7 == 0)
end
Events.SequenceGameInitComplete.Fire()
local before = writes
for i = 1, 100 do GameEvents.PlayerDoTurn.Fire(0); GameEvents.PlayerDoTurn.Fire(1) end
assert(before == writes)
for i, city in ipairs(cities) do
  Counts(city, i % 2 == 0 and i % 5 == 0 and 1 or 0,
               i % 2 == 0 and i % 3 == 0 and 1 or 0)
end
-- No Saba game is a no-op, even when a peer owns qualifying terrain.
Players[0].civ = -1
Events.SequenceGameInitComplete.Fire(); Counts(restored, 0, 0)
before = writes
for p = 0, 63 do GameEvents.PlayerDoTurn.Fire(p) end
assert(writes == before)
print('PASS Saba simulated native-count reload, owner change across load, 256-city stress and no-Saba no-op')
