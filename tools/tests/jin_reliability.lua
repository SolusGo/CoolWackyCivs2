local J=MapModData.JIN
Complete('GREAT_PASTURE');Complete('DRAGON_PAVILION');Complete('GREAT_WALL_BASTION')
local s=J.State(0)
for tier=1,3 do local candidates=J.Candidates(0,s,tier);assert(Action('SITE',tier,candidates[1]));s=J.State(0)end
for _,g in pairs(s.grass)do g.horses=5 end;J.Save(0,s)
local cavalry=Spawn('IRON_PAGODA',10,10);local ranged=Spawn('MOHE',10,11);local infantry=Spawn('UNIT_WARRIOR',11,10)
assert(cavalry:GetMaxHitPoints()==140 and cavalry.damage==0 and ranged:GetMaxHitPoints()==120 and infantry:GetMaxHitPoints()==100)
-- Wounded-cap changes cannot kill, heal repeatedly, or affect enemy recipients.
cavalry.damage=139;s=J.State(0);s.grass[1].horses=0;J.Save(0,s);J.SyncUnit(0,cavalry,s);assert(cavalry:GetMaxHitPoints()==130 and cavalry.damage==129)
s.grass[1].horses=5;J.Save(0,s);J.SyncUnit(0,cavalry,s);assert(cavalry:GetMaxHitPoints()==140 and cavalry.damage==139)
Players[0].units[cavalry.id]=nil;cavalry.owner=1;Players[1].units[cavalry.id]=cavalry;GameEvents.UnitConverted.Fire(0,1,cavalry.id,cavalry.id,false)
assert(cavalry:GetMaxHitPoints()==100 and cavalry.damage==99)
local upgraded=Spawn('UNIT_CAVALRY',10,10);GameEvents.UnitConverted.Fire(0,0,ranged.id,upgraded.id,true);assert(upgraded:GetMaxHitPoints()==140)
-- A blocked or capped Pavilion award remains pending and is issued once, later.
local s=J.State(0);s.freeEmissary=true;J.Save(0,s);cap.blocked=true;J.FreeEmissary(0,s);assert(J.State(0).freeEmissary)
cap.blocked=false;J.FreeEmissary(0,J.State(0));assert(J.Count(0,'EMISSARY')==2 and not J.State(0).freeEmissary)
s=J.State(0);s.freeEmissary=true;J.Save(0,s);J.FreeEmissary(0,s);assert(J.State(0).freeEmissary)
-- Twenty-six Mounted Villagers are legal with two active Tributaries, twenty-seven are not.
s=J.State(0);s.trib[2]=J.CityRecord(minor);s.trib[3]=J.CityRecord(minor2);J.Save(0,s)
for i=1,25 do Spawn('MOUNTED_VILLAGER',7,7)end
assert(J.TrainAllowed(0,cap.id,GameInfoTypes.UNIT_JIN_MOUNTED_VILLAGER));Spawn('MOUNTED_VILLAGER',7,7);assert(not J.TrainAllowed(0,cap.id,GameInfoTypes.UNIT_JIN_MOUNTED_VILLAGER))
-- Site destruction loses its Horses permanently; repair/pillage alone does not reset them.
local site=s.grass[1].plot;plots[site]:SetImprovementType(-1);assert(J.State(0).grass[1]==nil)
plots[site]:SetImprovementType(GameInfoTypes.IMPROVEMENT_JIN_GRASSLAND);assert(J.State(0).grass[1]==nil)
-- Defensive response cannot create units or consume cooldown if all nearby deployment plots are illegal.
War(0,1,true);local enemy=Spawn('UNIT_WARRIOR',cap.x+2,cap.y,1)
for _,p in ipairs(J.Near(cap:Plot(),1))do p.water=true end
s=J.State(0);J.Defenders(0,s,true);assert(next(J.State(0).defenders)==nil)
local before=J.State(0).defense['c'..cap:Plot().index].ready;assert(before==0)
for _,p in ipairs(J.Near(cap:Plot(),1))do p.water=false end
J.Defenders(0,J.State(0),true);assert(next(J.State(0).defenders))
local uid=next(J.State(0).defenders);local defender=Players[0]:GetUnitByID(uid)
defender.x=23;defender.y=23;GameEvents.UnitSetXY.Fire(0,uid,23,23);assert(defender.dead)
print('PASS Jin reliability: 40/20 HP, wounded transitions, gift/upgrade, deferred awards, 20/+3 caps, destruction and blocked/displaced defenders')
