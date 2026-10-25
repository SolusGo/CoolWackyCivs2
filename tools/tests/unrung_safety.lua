local c=NewCity(10,0,true);local u=NewUnit(1,0)
LoadUnrung();PeaceTurns(4)
local raw=saves.UNRUNG_STATE_V1_0;NewContext();LoadUnrung();assert(saves.UNRUNG_STATE_V1_0==raw)
Turn();CheckCity(c,1,1)
for i=1,10 do NewContext();LoadUnrung() end
for _,e in pairs(GameEvents) do assert(#e.handlers==1,'duplicate gameplay registration') end
for _,e in pairs(Events) do assert(#e.handlers==1,'duplicate UI registration') end
raw=saves.UNRUNG_STATE_V1_0
for i=1,25 do Events.SequenceGameInitComplete.Fire();Events.LoadScreenClose.Fire() end
assert(saves.UNRUNG_STATE_V1_0==raw,'repeated init cannot increment progress')
-- Unrelated owner turns never scan city/unit lists.
local cs,us=counters.cityScans,counters.unitScans
for i=1,1000 do for pid=1,5 do GameEvents.PlayerDoTurn.Fire(pid);GameEvents.PlayerDoneTurn.Fire(pid) end end
assert(counters.cityScans==cs and counters.unitScans==us)
-- Save errors disable derived effects; recovery consumes the authoritative old stacks exactly once.
failSave=true;WarWith(1,true);CheckCity(c,0,0);CheckUnit(u,0)
failSave=false;Begin();assert(Read().toll==1 and Read().peace==0);CheckUnit(u,1)
-- Corrupt/newer data is preserved, never reset to award fresh effects.
saves.UNRUNG_STATE_V1_0='2|future';NewContext();LoadUnrung()
assert(saves.UNRUNG_STATE_V1_0=='2|future');CheckUnit(u,0);CheckCity(c,0,0)
print('PASS reload at 4/5, context ownership, duplicate init, 5000 foreign turns, failed persistence, unknown-version fail closed')
