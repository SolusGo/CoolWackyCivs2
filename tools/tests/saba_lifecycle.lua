local D = GameInfoTypes.TERRAIN_DESERT
local c = MakeCity(0, 1, 1, D, true, true)
local other = MakeCity(1, 2, 1, D, true, false)
LoadSaba(); Counts(c, 1, 1); Counts(other, 0, 0)
-- Model ordinary capture, recapture, nonconquest trade and liberation through
-- the common post-acquire hook. Native paths are audited separately in Python.
for _, reason in ipairs({'capture', 'recapture', 'trade', 'liberation'}) do
  Transfer(c, 1, true); Counts(c, 0, 0)
  Transfer(c, 0, true); Counts(c, 1, 1)
end
-- Missed optional event: next relevant owner's turn repairs the ledger.
Transfer(c, 1, false)
GameEvents.PlayerDoTurn.Fire(1); Counts(c, 0, 0)
Transfer(c, 0, false)
GameEvents.PlayerDoTurn.Fire(0); Counts(c, 1, 1)
-- Corrupt/stale save marker values are replaced rather than incremented.
c.b[GameInfoTypes.BUILDING_SABA_RIVER] = 9
other.b[GameInfoTypes.BUILDING_SABA_DESERT] = 6
Events.SequenceGameInitComplete.Fire(); Counts(c, 1, 1); Counts(other, 0, 0)
-- A second Saba player also receives the location ability.
Players[2].civ = GameInfoTypes.CIVILIZATION_SABA
Transfer(c, 2, true); Counts(c, 1, 1)
Raze(c)
GameEvents.PlayerDoTurn.Fire(2); Events.SequenceGameInitComplete.Fire()
GameEvents.CityCaptureComplete.Fire(0, false, 999, 999, 1)
GameEvents.PlayerDoTurn.Fire(-1)
local rebuilt = MakeCity(0, 1, 1, -100, false, false)
GameEvents.PlayerCityFounded.Fire(0, 1, 1); Counts(rebuilt, 0, 0)
print('PASS Saba ownership cleanup/restoration, periodic fallback, stale-count repair, destruction and city-site reuse')
