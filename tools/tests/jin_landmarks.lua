local J=MapModData.JIN
Complete('FLOWER_PAGODA');assert(not Action('LANDMARK','GREAT_PASTURE'))
local garden
for _,p in ipairs(J.Near(cap:Plot(),3))do if J.SiteLegal(0,p)then garden=p;break end end
assert(Action('GARDEN',garden.index));local worker=Spawn('MOUNTED_VILLAGER',garden.x,garden.y);local soldier=Spawn('UNIT_WARRIOR',garden.x,garden.y)
assert(worker:IsHasPromotion(J.Promotion('GARDEN_WORK')) and soldier:IsHasPromotion(J.Promotion('GARDEN_COMBAT')))
local second
for _,p in ipairs(J.Near(cap:Plot(),3))do if J.SiteLegal(0,p)then second=p;break end end
assert(not Action('GARDEN',second.index));local deadline=J.State(0).gardenReady;LoadJin();J=MapModData.JIN;assert(J.State(0).gardenReady==deadline)
now=deadline;assert(Action('GARDEN',second.index));assert(garden.improvement==-1)
Complete('MOUNTAIN_HALL');assert(Players[0]:HasPolicy(GameInfoTypes.POLICY_JIN_MONASTERY))
local s=J.State(0);s.karma=999;J.Save(0,s);NextTurn();s=J.State(0);assert(s.karma==0 and s.blessing==now+4 and cap:GetNumBuilding(J.Building('BLESSING'))==1)
local blessing=s.blessing;LoadJin();J=MapModData.JIN;assert(J.State(0).blessing==blessing)
for _,p in pairs(plots)do p.worked=false end
NextTurn(3);assert(cap:GetNumBuilding(J.Building('BLESSING'))==1);NextTurn();assert(cap:GetNumBuilding(J.Building('BLESSING'))==0)
s=J.State(0);s.karma=100;J.Save(0,s);local victim=Spawn('UNIT_WORKER',9,8);GameEvents.UnitPrekill.Fire(0,victim.id,victim.typ,9,8,true,1);GameEvents.UnitPrekill.Fire(0,victim.id,victim.typ,9,8,false,1);assert(J.State(0).karma==75)
Complete('PAGODA_FOREST');assert(J.Tier(J.State(0))==3 and not Action('LANDMARK','GREAT_WALL_BASTION'))
-- All named upgrades have actual effects; test representative native promotions and yields.
for _,up in ipairs(J.C.upgrades)do Learn(up.tech);assert(Action('UPGRADE',up.key))end
assert(worker:IsHasPromotion(J.Promotion('DRAFT_WORK')))
local mounted=Spawn('IRON_PAGODA',8,9);assert(mounted:IsHasPromotion(J.Promotion('QUILTED_ARMOR')) and mounted:IsHasPromotion(J.Promotion('STORM_LANCES')))
assert(cap:GetNumBuilding(J.Building('UP_COLLECTIVE_HUNTING'))==1)
local secondCity=City(0,4,16);local thirdCity=City(0,16,18)
NextTurn(J.Scale(J.C.groveInterval)*18);s=J.State(0);local n=0;local per={};for _,r in pairs(s.groves)do n=n+1;per[r.plot]=(per[r.plot]or 0)+1 end
assert(n==15);for _,v in pairs(per)do assert(v<=5)end
local index=next(s.groves);local grove=plots[index];War(0,1,true);local enemy=Spawn('UNIT_WARRIOR',grove.x,grove.y,1);enemy.moves=120
GameEvents.UnitSetXY.Fire(1,enemy.id,enemy.x,enemy.y);assert(enemy.moves==60);GameEvents.UnitSetXY.Fire(1,enemy.id,enemy.x,enemy.y);assert(enemy.moves==60)
grove:SetImprovementType(-1);J.Groves(0,J.State(0));assert(not J.State(0).groves[index])
-- Ineligible/crowded/coastal offers contain fewer real sites and remain pending.
local pstate=J.State(0);pstate.pending[3]={plot=cap:Plot().index,founded=cap.born,sites={}}
for _,p in ipairs(J.Near(cap:Plot(),J.C.siteRadius))do p.water=true end
J.Save(0,pstate);assert(#J.Candidates(0,pstate,3)==0 and J.State(0).pending[3])
print('PASS Jin landmarks: permanent paired choices, Garden relocation, Karma/death/blessing windows, named upgrades, Grove caps/slowing and crowded sites')
