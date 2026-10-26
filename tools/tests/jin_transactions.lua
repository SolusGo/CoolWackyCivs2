local J=MapModData.JIN
Complete('GREAT_PASTURE');Complete('DRAGON_PAVILION');Learn('TECH_HORSEBACK_RIDING')
local typ=J.Unit(0,'MOHE');local s=J.State(0);s.grass.pasture.horses=5;J.Save(0,s)
local legal,_,source,cost=J.RecruitCheck(0,s,cap.id,typ);assert(legal)
local gold=Players[0].gold;local units=J.Count(0,'MOHE');local serial=s.serial
assert(Action('RECRUIT',cap.id,typ));assert(Players[0].gold==gold-cost and J.State(0).grass[source].horses==4 and J.Count(0,'MOHE')==units+1)
assert(not J.Action(0,serial,'RECRUIT',cap.id,typ),'stale callback spent twice')
Players[0].resources=0;assert(not Action('RECRUIT',cap.id,J.Unit(0,'IRON_PAGODA')));Players[0].resources=10
cap.blocked=true;assert(not Action('RECRUIT',cap.id,typ));cap.blocked=false
-- Native spawn throws AFTER synchronous UnitCreated: rollback must find the unreturned unit.
local init=Players[0].InitUnit;gold=Players[0].gold;s=J.State(0);units=J.Count(0,'MOHE')
Players[0].InitUnit=function(self,...)init(self,...);error('injected return failure')end
assert(not Action('RECRUIT',cap.id,typ));Players[0].InitUnit=init
assert(J.Count(0,'MOHE')==units and Players[0].gold==gold and J.State(0).grass[source].horses==s.grass[source].horses and not J.State(0).transaction)
-- A silent Player ScriptData write failure is detected, with no paid deployment.
local write=Players[0].SetScriptData;local fail=true
Players[0].SetScriptData=function(self,raw)if fail then fail=false;return end;write(self,raw)end
assert(not Action('RECRUIT',cap.id,typ));Players[0].SetScriptData=write
assert(J.Count(0,'MOHE')==units and Players[0].gold==gold and not J.State(0).transaction)
-- Saved receipt: charge already happened, ledger acknowledgement was interrupted.
local created=Spawn('MOHE',8,8);s=J.State(0);s.grass[source].horses=s.grass[source].horses-1
s.transaction={kind='recruit',token=s.serial+1,turn=now,unitType=typ,plot=cap:Plot().index,source=source,sourcePlot=s.grass[source].plot,cost=cost,paid=0,before={},horse=true,unit=created.id,born=created.born,intent={gold=gold,delta=cost,total=cost}}
Players[0].gold=gold-cost;J.Save(0,s);local raw=Players[0].raw
LoadJin();J=MapModData.JIN;assert(not J.State(0).transaction and Players[0].gold==gold-cost and not created.dead)
local horses=J.State(0).grass[source].horses;LoadJin();J=MapModData.JIN;assert(J.State(0).grass[source].horses==horses and Players[0].gold==gold-cost)
-- Loading the older same-turn save reconstructs, without a second charge.
Players[0].raw=raw;LoadJin();J=MapModData.JIN;assert(not J.State(0).transaction and Players[0].gold==gold-cost)
-- Missing deployment refunds the reserved Horse and acknowledged payment once.
s=J.State(0);s.transaction={kind='recruit',token=s.serial+2,turn=now,unitType=typ,plot=cap:Plot().index,source=source,sourcePlot=s.grass[source].plot,cost=cost,paid=cost,before={},horse=true,unit=99999,born=now};J.Save(0,s)
LoadJin();J=MapModData.JIN;assert(Players[0].gold==gold and J.State(0).grass[source].horses==horses+1)
-- Partial multi-target Bribe: completed first conversion paid; later native failure rolls back only its clone.
War(0,1,true);local emissary;for u in Players[0]:Units()do if u.typ==J.Unit(0,'EMISSARY')then emissary=u end end
emissary.x=11;emissary.y=10;emissary.moves=120
local first=Spawn('UNIT_WARRIOR',12,10,1);local second=Spawn('UNIT_WARRIOR',12,11,1)
local ok,_,targets=J.BribeCheck(0,J.State(0),emissary.id,first:GetPlot().index);assert(ok and #targets==2)
local original=Players[4].InitUnit;local calls=0;local printOriginal=print;local logs={}
print=function(...)local words={...};logs[#logs+1]=table.concat(words,' ')end
Players[4].InitUnit=function(self,...)calls=calls+1;local clone=original(self,...);if calls==2 then error('injected second clone failure')end;return clone end
gold=Players[0].gold;assert(Action('BRIBE',emissary.id,first:GetPlot().index));Players[4].InitUnit=original;print=printOriginal
assert(#logs==1 and logs[1]:find('partial failure',1,true));assert(Players[0].gold==gold-targets[1].cost)
local converted=Players[1]:GetUnitByID(targets[1].uid);local remaining=Players[1]:GetUnitByID(targets[2].uid)
assert(not converted and remaining and not remaining.dead)
local n=0;for u in Players[4]:Units()do n=n+1;assert(J.State(0).rebels[u.id])end;assert(n==1)
assert(not J.State(0).transaction and J.State(0).emissaryCooldown[emissary.id])
local after=Players[0].gold;LoadJin();J=MapModData.JIN;assert(Players[0].gold==after and not Players[1]:GetUnitByID(targets[1].uid))
-- Reload a pending partial receipt: retain the paid conversion, remove the uncommitted clone.
local rebel;for u in Players[4]:Units()do rebel=u end
local orphan=Spawn('UNIT_WARRIOR',14,13,4)
s=J.State(0);local a=targets[1];local b=targets[2]
a.clone=rebel.id;a.cloneBorn=rebel.born;a.expires=s.rebels[rebel.id].expires;a.converted=true
b.clone=orphan.id;b.cloneBorn=orphan.born;b.expires=now+J.Scale(J.C.rebelLifetime)
s.transaction={kind='bribe',token=s.serial+3,turn=now,emissary=emissary.id,emissaryBorn=emissary.born,ready=now+J.Scale(J.C.bribeCooldown),paid=a.cost,targets={a,b}}
J.Save(0,s);LoadJin();J=MapModData.JIN
assert(orphan.dead and not rebel.dead and not remaining.dead and Players[0].gold==after and not J.State(0).transaction)
-- Altered Barbarian diplomacy must refuse conversion before deleting an enemy.
now=now+J.Scale(J.C.bribeCooldown);emissary.moves=120;War(0,4,false)
assert(not Action('BRIBE',emissary.id,remaining:GetPlot().index) and not remaining.dead and Players[0].gold==after)
print('PASS Jin receipts: stale clicks/native eligibility, synchronous spawn and silent-write rollback, exact saved payment/refund, same-turn older save, partial Bribe charge/cleanup and altered Barbarian diplomacy')
