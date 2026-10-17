-- Small deterministic shape models, not executions of Civ V's map generators.
TEST.flush()
local M=MapModData.MCPVP;local s=M.State(0)
local function reset()
 local units={};for _,u in pairs(TEST.units) do units[#units+1]=u end;for _,u in ipairs(units) do u:Kill(false,-1) end
 for n=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(n)
  p.water=false;p.mountain=false;p.blocked=false;p.hidden=false;p.hill=false;p.area=0;p.owner=p.city and p.city.pid or -1;p.danger=0
 end
 TEST.turn=0;M.navigation={};s.mode='HG';s.start=0;s.finish=20;s.cycle=s.cycle+1;s.feast=nil;s.feastPending=false
end
local function choose()
 local original=Map.GetNumPlots;local nodes=M.navStats.nodes;local calls=M.navStats.native
 Map.GetNumPlots=function() error('Feast placement must not scan the entire map') end
 local ok,plot=pcall(M.ChooseFeast,s);Map.GetNumPlots=original;assert(ok,plot)
 assert(M.navStats.nodes-nodes<=1920 and M.navStats.native-calls<=6,'Each placement must respect fixed work budgets')
 if plot then
  assert(M.ValidFeast(plot) and M.Distance(TEST.cap,plot)>=4 and M.Distance(TEST.cap,plot)<=16)
  local routes=M.NavFlood(0,nil,TEST.cap:Plot(),{nodes=768,radius=22,cost=60,ignoreUnits=true})
  assert(routes[plot:GetPlotIndex()],'Feast needs a real legal capital land route')
 end
 return plot
end
-- Pangaea-like open land: reachable, neutral and accessible to a rival.
reset();local plot=choose();assert(plot and plot:GetOwner()<0)
local rivalRoutes=M.NavFlood(1,nil,TEST.enemyCap:Plot(),{nodes=384,radius=22,cost=60,ignoreUnits=true})
assert(rivalRoutes[plot:GetPlotIndex()],'Open land should encourage a genuinely accessible rival approach')
-- Tiny Islands: the capital island has no legal 4-tile-away site.
reset();for n=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(n);p.water=not p:IsCity() and M.Distance(p,TEST.cap)>2 end
assert(not choose())
-- Small Continents: same area ID alone must NOT permit crossing a water barrier.
reset();for y=0,9 do Map.GetPlot(6,y).water=true end
plot=choose();assert(plot and plot:GetX()<6)
-- Continents with a mountain-divided region: reject the inaccessible chamber.
reset();for y=0,9 do Map.GetPlot(6,y).mountain=true end
plot=choose();assert(plot and plot:GetX()<6)
-- A narrow land bridge is a valid route but not itself a three-approach Feast.
reset();for y=0,9 do if y~=5 then Map.GetPlot(6,y).water=true end end
plot=choose();assert(plot and plot~=Map.GetPlot(6,5))
-- Unavoidable closed territory is inaccessible even on a common land area.
reset();Teams[0].wars={[1]=true};for y=0,9 do Map.GetPlot(6,y).owner=2 end
plot=choose();assert(plot and plot:GetX()<6)
Teams[2].borders={[0]=true};plot=choose();assert(plot)
Teams[0].wars=nil;Teams[2].borders=nil
-- Available military units are checked against the remaining claim window.
reset();TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush();plot=choose();assert(plot)
-- Repeated failed searches stop after initial/Grace/deadline attempts.
reset();for n=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(n);p.hidden=M.Distance(p,TEST.cap)>2 end
local searches=M.navStats.feasts;s.queued='HG';M.StartMatch(s)
for turn=0,19 do TEST.turn=turn;M.UpdateFeast(s);M.UpdateFeast(s) end
assert(not s.feast and not s.feastPending and M.navStats.feasts-searches==3)
local u=TEST.new('UNIT_MCPVP_VETERAN',4,4);TEST.flush();M.Reconcile(s)
assert(u:IsHasPromotion(GameInfoTypes.PROMOTION_MCPVP_FINAL),'No-site matches retain Final Battle')
local victories=s.wins.HG;M.EndMatch(s);assert(s.wins.HG==victories,'Missing Feast cannot create a victory')
-- Turn-zero without a capital, then founding/exploration during preparation.
reset();local cities=Players[0].cities;Players[0].cities={};s.queued='HG';M.StartMatch(s)
assert(s.feastPending and not s.feast);Players[0].cities=cities
TEST.turn=3;M.UpdateFeast(s);assert(s.feast and not s.feast.announced)
local index=s.feast.plot;local version=s.version;M.Save(s);M.navigation={};M,s=TEST.mcpReload()
assert(s.version==version and s.feast.plot==index and not s.feast.announced)
TEST.turn=7;M.UpdateFeast(s);assert(s.feast.announced and s.feast.status=='PREPARING')
TEST.turn=10;M.UpdateFeast(s);assert(s.feast.status=='ACTIVE')
M.Save(s);searches=M.navStats.feasts;M.navigation={};M,s=TEST.mcpReload()
assert(s.feast.plot==index and s.feast.status=='ACTIVE' and M.navStats.feasts==searches,'Reload must preserve, not reroll, an active objective')
plot=M.FeastPlot(s);local gold=Players[1].gold;local legacy=s.current
local rival=TEST.new('UNIT_WARRIOR',plot:GetX(),plot:GetY(),1);TEST.flush()
assert(s.feast.claimant==1 and Players[1].gold==gold+75 and s.current==legacy and rival:GetExperience()==20)
M.UpdateFeast(s);M,s=TEST.mcpReload();assert(Players[1].gold==gold+75 and s.feast.claimant==1)
-- Two McPvP civilizations reserve distinct live locations.
reset();s.feast={plot=choose():GetPlotIndex(),active=10,expires=15,status='PREPARING'}
Players[2].civ=GameInfoTypes.CIVILIZATION_MCPVP;TEST.city(2,1,1)
local second=M.State(2);M.StartMatch(second)
assert(second.feast and second.feast.plot~=s.feast.plot)
print('PASS McPvP Feast models: Tiny Islands, Small Continents, Continents, Pangaea, bridges, borders, preparation limits, turn zero, multiple players, save/load and rival claims')
