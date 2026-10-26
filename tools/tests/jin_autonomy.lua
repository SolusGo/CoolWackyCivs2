local J=MapModData.JIN
Complete('FLOWER_PAGODA');Complete('DRAGON_PAVILION');War(0,1,true)
local enemy=Spawn('UNIT_WARRIOR',10,8,1)
inMovement=true;GameEvents.UnitSetXY.Fire(1,enemy.id,10,8);inMovement=false
local uid,r=next(J.State(0).defenders);assert(uid,'approach did not deploy')
local u=Players[0]:GetUnitByID(uid);assert(not u.orders,'movement callback issued an order')
assert(not GameEvents.CanStartMission.Fire(0,uid,MissionTypes.MISSION_MOVE_TO))
assert(not GameEvents.CanStartMission.Fire(0,uid,999),'gift/upgrade mission allowed')
-- Closest-to-parent visible combat threat wins; civilians/neutrals/hidden troops are ignored.
u.x=9;u.y=8;u.moves=120
local near=Spawn('UNIT_WARRIOR',9,7,1);local far=Spawn('UNIT_WARRIOR',10,7,1)
local civilian=Spawn('UNIT_WORKER',8,7,1);local neutral=Spawn('UNIT_WARRIOR',8,9,2)
local hidden=Spawn('UNIT_WARRIOR',7,8,1);hidden.invisible=true
Pump();assert(u.orders==1 and u.lastTarget.x==near.x and u.lastTarget.y==near.y)
local damage=near.damage;for i=1,10 do J.QueuePatrol(0);Pump()end
assert(u.orders==1 and near.damage==damage,'reentrant/duplicate activation')
assert(civilian.damage==0 and neutral.damage==0 and hidden.damage==0)
local acted=J.State(0).defenders[uid].acted
LoadJin();J=MapModData.JIN;u.moves=120;Pump();assert(u.orders==1 and J.State(0).defenders[uid].acted==acted,'reload renewed order budget')
-- Return is a bounded legal neighbor step; occupied/city/impassable destinations are excluded.
for unit in Players[1]:Units()do unit.dead=true end
u.x=11;u.y=8;u.attacks=0;NextTurn();Pump()
assert(J.Distance(u:GetPlot(),cap:Plot())==2 and J.State(0).defenders[uid].mode=='RETURN')
assert(not J.CanMoveInto(0,uid,13,8,false,false));assert(not J.CanMoveInto(0,uid,8,8,true,false))
-- Active-player change cannot issue autonomous orders.
local orders=u.orders;active=1;u.moves=120;now=now+1;J.QueuePatrol(0);J.Patrol(0);assert(u.orders==orders);active=0
-- Busy expiry waits for combat to finish, then retires safely without freeing capacity early.
u.fighting=true;now=r.expires;J.Defenders(0,J.State(0),false)
assert(not u.dead and J.State(0).defenders[uid].retire)
u.fighting=false;J.Defenders(0,J.State(0),false);assert(u.dead and not J.State(0).defenders[uid])
-- Grenadier respects native range/LOS, then engages once and preserves collateral.
Learn('TECH_CHEMISTRY');enemy=Spawn('UNIT_WARRIOR',10,8,1);enemy.damage=0
local splash=Spawn('UNIT_WARRIOR',11,8,1)
local s=J.State(0);s.defense['c'..cap:Plot().index].ready=0;J.Save(0,s);J.Defenders(0,s,true)
uid=next(J.State(0).defenders);u=Players[0]:GetUnitByID(uid);assert(u.typ==J.Unit(0,'GRENADIER'))
u.x=9;u.y=8;u.moves=120;u.noLOS=true;Pump();assert(not u.lastTarget,'ignored native LOS')
NextTurn();u.noLOS=false;u.x=9;u.y=8;Pump()
assert(u.lastTarget and u.lastTarget.x==10 and enemy.damage>=20 and splash.damage>0)
-- Pillage and capture invalidate Fort parents, including outside city discovery neighborhoods.
s=J.State(0);s.upgrades.MENGAN_EMPLACEMENT=true;J.Save(0,s)
local fort=Map.GetPlot(19,19);fort:SetImprovementType(J.T.IMPROVEMENT_FORT)
local foe=Spawn('UNIT_WARRIOR',20,19,1);GameEvents.UnitSetXY.Fire(1,foe.id,20,19)
local fortUnit;for id,d in pairs(J.State(0).defenders)do if d.parent=='f'..fort.index then fortUnit=Players[0]:GetUnitByID(id)end end
assert(fortUnit);fort.pillaged=true;GameEvents.TileImprovementChanged.Fire(19,19,0,fort.improvement,fort.improvement,true);assert(fortUnit.dead)
fort.pillaged=false;GameEvents.TileImprovementChanged.Fire(19,19,0,fort.improvement,fort.improvement,false)
now=now+J.Scale(J.C.defenderCooldown);J.Defenders(0,J.State(0),true)
for id,d in pairs(J.State(0).defenders)do if d.parent=='f'..fort.index then fortUnit=Players[0]:GetUnitByID(id)end end
assert(not fortUnit.dead);fort:SetOwner(1);assert(fortUnit.dead)
-- Overlapping city emplacements keep their own caps/cooldowns.
local second=City(0,10,10);J.InvalidateSpatial(0);J.Defenders(0,J.State(0),true)
local counts={};for _,d in pairs(J.State(0).defenders)do counts[d.parent]=(counts[d.parent]or 0)+1 end
for _,n in pairs(counts)do assert(n<=J.C.defenderCapacity)end
local n=0;for _ in pairs(J.State(0).defenders)do n=n+1 end
J.Defenders(0,J.State(0),true);local n2=0;for _ in pairs(J.State(0).defenders)do n2=n2+1 end;assert(n==n2)
print('PASS Jin autonomous defenders: deferred melee/ranged orders, priorities, LOS, return/leash, budget/reload, turn ownership, busy expiry, Fort pillage/capture and overlapping caps')
