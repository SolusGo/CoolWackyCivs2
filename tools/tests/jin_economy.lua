local J=MapModData.JIN;local S=J.S
assert(J.IsJin(0) and not J.IsJin(1));assert(J.State(0).started)
local before=0;for _,p in pairs(plots)do if p.resource==GameInfoTypes.RESOURCE_DEER then before=before+1 end end;assert(before==2)
local raw=Players[0].raw;J.Bootstrap();assert(Players[0].raw==raw,'bootstrap changed settled state')
Complete('GREAT_PASTURE');local s=J.State(0);assert(s.grass.pasture and #J.Candidates(0,s,1)==3)
local sites=J.Candidates(0,s,1);local serial=s.serial
assert(J.Action(0,serial,'SITE',1,sites[1]));assert(not J.Action(0,serial,'SITE',1,sites[2]),'stale click accepted')
s=J.State(0);assert(s.pending[1]==nil and s.grass[1]);assert(J.Plot(sites[2]):GetImprovementType()~=GameInfoTypes.IMPROVEMENT_JIN_GRASSLAND)
assert(J.Plot(sites[1]).builder==0,'Jin improvement builder was omitted')
local interval=J.Scale(J.C.horseIntervals[1]);NextTurn(interval-1);assert(J.State(0).grass[1].horses==0)
NextTurn();s=J.State(0);assert(s.grass[1].horses==1 and s.grass.pasture.horses==1)
local saved=Players[0].raw;GameEvents.PlayerDoTurn.Fire(0);assert(Players[0].raw==saved,'duplicate turn mutated state')
LoadJin();J=MapModData.JIN;GameEvents.PlayerDoTurn.Fire(0);assert(J.State(0).grass[1].horses==1,'reload generated Horse')
NextTurn(interval*7);s=J.State(0);assert(s.grass[1].horses==5 and s.grass.pasture.horses==5)
local cavalry=Spawn('IRON_PAGODA',9,8);local archer=Spawn('MOHE',9,9);local infantry=Spawn('UNIT_WARRIOR',10,8)
assert(cavalry:GetMaxHitPoints()==120 and archer:GetMaxHitPoints()==110 and infantry:GetMaxHitPoints()==100)
local plot=J.Plot(s.grass[1].plot);plot.pillaged=true;GameEvents.TileImprovementChanged.Fire(plot.x,plot.y,0,plot.improvement,plot.improvement,true)
assert(cavalry:GetMaxHitPoints()==110);local inventory=J.State(0).grass[1].horses;NextTurn(interval);assert(J.State(0).grass[1].horses==inventory)
plot.pillaged=false;GameEvents.TileImprovementChanged.Fire(plot.x,plot.y,0,plot.improvement,plot.improvement,false)
Learn('TECH_HORSEBACK_RIDING');local gold=Players[0].gold;local horses=J.Horses(0,J.State(0))
cap.blocked=true;assert(not Action('RECRUIT',cap.id,GameInfoTypes.UNIT_JIN_IRON_PAGODA));assert(Players[0].gold==gold and J.Horses(0,J.State(0))==horses)
cap.blocked=false;Players[0].resources=0;assert(not Action('RECRUIT',cap.id,GameInfoTypes.UNIT_JIN_IRON_PAGODA));Players[0].resources=10
Players[0].failSpawn=true;assert(not Action('RECRUIT',cap.id,GameInfoTypes.UNIT_JIN_IRON_PAGODA));Players[0].failSpawn=false;assert(J.Horses(0,J.State(0))==horses)
assert(Action('RECRUIT',cap.id,GameInfoTypes.UNIT_JIN_IRON_PAGODA));assert(Players[0].gold==gold-math.ceil(145*4*.65));assert(J.Horses(0,J.State(0))==horses-1)
assert(cavalry:GetMaxHitPoints()==100+(horses-1)*2)
-- Old saves and distinct games are authoritative even at identical turn numbers.
local later=Players[0].raw;Players[0].raw=saved;LoadJin();J=MapModData.JIN;assert(J.State(0).grass[1].horses==1)
local buildings=cap.buildings;cap.buildings={};Players[0].raw='foreign-mod-data';LoadJin();J=MapModData.JIN;assert(J.Horses(0,J.State(0))==0 and J.State(0).serial==0);cap.buildings=buildings
Players[0].raw=later;LoadJin();J=MapModData.JIN;assert(J.Horses(0,J.State(0))==horses-1)
plot:SetOwner(1);assert(J.State(0).grass[1]==nil);plot:SetOwner(0);assert(J.State(0).grass[1]==nil,'captured Horses resurrected')
-- Cap permits 20, not an arbitrary smaller Worker cap.
for i=1,20 do Spawn('MOUNTED_VILLAGER',7,7)end
assert(not J.TrainAllowed(0,cap.id,GameInfoTypes.UNIT_JIN_MOUNTED_VILLAGER))
assert(J.TrainAllowed(0,cap.id,GameInfoTypes.UNIT_WORKER))
local data={a={x=5,y=-2},b=true,c='brackets [] ; :',n=0};assert(S.Encode(S.Decode(S.Encode(data)))==S.Encode(data));assert(S.Decode('zz')==nil)
print('PASS Jin economy: candidates, cap, HP, pillage, purchase legality, stale clicks, four-speed timing, save rollback and ownership')
