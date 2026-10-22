-- Real fixture snapshots restore native-shaped building counts and unit positions.
local p,c,u=Setup();local initial=Save()
Restore(initial);p=Players[0];c=p.cities[1];AssertYields(c,1,0,0)
EndTurn(p);local interturn=Save()
Restore(interturn);p=Players[0];c=p.cities[1]
assert(c.b[107]==rawTurn+2);BeginTurn(p);local first=rawTurn
local snapshots={}
for delta=0,12 do
 if delta>0 then EndTurn(p);BeginTurn(p) end
 snapshots[delta]=Save()
end
for _,delta in ipairs({0,1,2,3,7,10,11,12}) do
 Restore(snapshots[delta]);p=Players[0];c=p.cities[1]
 local expires=c.b[105];local ready=c.b[106]
 local active=delta<3 or delta==12
 AssertYields(c,active and 4 or 1,active and 2 or 0,active and 2 or 0)
 for i=1,3 do Events.LoadScreenClose.Fire();GameEvents.PlayerDoTurn.Fire(0) end
 assert(c.b[105]==expires and c.b[106]==ready,'reload reset interval')
 local expected=(delta+1)%12<3
 EndTurn(p);local result=BeginTurn(p)[1]
 assert(result[2]==(expected and 2 or 0),'bad post-load harvest '..delta)
end
-- Pre-staging native end-turn autosave: replay deactivation after restoring it.
for _,delta in ipairs({2,10,11}) do
 Restore(snapshots[delta]);p=Players[0];local autosave=Save()
 EndTurn(p);BeginTurn(p)
 Restore(autosave);p=Players[0];EndTurn(p);local harvest=BeginTurn(p)[1]
 assert(harvest[2]==(((delta+1)%12<3) and 2 or 0))
end
-- Independent cities retain different absolute boundaries through a rewind.
p,c,u=Setup();local c2=City(p,2,false);EndTurn(p);BeginTurn(p)
Move(u,c2);EndTurn(p);BeginTurn(p);local multi=Save()
EndTurn(p);BeginTurn(p);Restore(multi);p=Players[0]
assert(p.cities[1].b[106]+1==p.cities[2].b[106])
EndTurn(p);BeginTurn(p);AssertYields(p.cities[1],4,2,2);AssertYields(p.cities[2],3,2,0)
EndTurn(p);BeginTurn(p);AssertYields(p.cities[1],1,0,0);AssertYields(p.cities[2],3,2,0)
-- Separate saves on the same raw turn cannot inherit a transient Lua ledger.
Restore(initial);p=Players[0];AssertYields(p.cities[1],1,0,0)
EndTurn(p);BeginTurn(p);AssertYields(p.cities[1],4,2,2)
-- Loading without a pending Crew cancels preparation, rather than committing it.
Restore(interturn);p=Players[0];c=p.cities[1];Kill(p.units[1]);local gone=Save()
Restore(gone);p=Players[0];c=p.cities[1];BeginTurn(p);AssertYields(c,1,0,0)
print('PASS Circus save simulations: all festival turns/cooldown/T+11, interturn/pre-staging autosaves, rewinds, independent cities and same-turn separate saves')
