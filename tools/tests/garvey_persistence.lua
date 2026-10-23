-- A late foundation sets the first cooldown from founding, not game start.
p.cities={};local G=Reload();assert(not G.State(0))
turn=turn+5;city=NewCity(p,1);GameEvents.PlayerCityFounded(0,4,5)
local founded=turn;assert(G.State(0).ready==founded+12)
Tick(founded+11);assert(not G.CanRoll(0))
Tick(founded+12);randomValue=50;assert(G.Roll(0,3,G.State(0).ready))
assert(G.State(0).insub==0,'50 is outside the 50% correction interval')
local originalTurn=turn;local originalSave=Store['GARVEY:v1:state:0']
local count=#notifications;Tick(turn);Tick(turn);assert(#notifications==count)
Tick(turn+12);randomValue=49;assert(G.Roll(0,1,G.State(0).ready));assert(G.State(0).insub==1)
-- Restore an earlier save and repair persisted native markers from its ledger.
turn=originalTurn;Store['GARVEY:v1:state:0']=originalSave;G=Reload()
assert(G.Student(G.State(0))==3 and G.State(0).insub==0)
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_AARON)==0)
assert(city:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_JACQUELINE)==1)
Tick(turn+12);randomValue=0;assert(G.Roll(0,4,G.State(0).ready));assert(G.State(0).insub==1)
-- Nonhuman control ages existing deadlines and strips all temporary bonuses.
p.human=false;Tick(turn+20)
assert(not hall:IsHasPromotion(G.promotions.BLAKE) and G.State(0).insub==1)
p.human=true;G=Reload();assert(G.Student(G.State(0))==0 and G.State(0).insub==1)
-- Loss of every city does not reset patience or first founding time.
p.cities={};p.alive=false;Tick(turn+1);p.alive=true;p.cities={city};G=Reload()
assert(G.State(0).founded==founded and G.State(0).insub==1)
-- A silently rejected write cannot activate an uncommitted selection.
local ready=G.State(0).ready;local before=Store['GARVEY:v1:state:0']
RejectWrites=true;assert(not G.Roll(0,5,ready));assert(not G.State(0))
assert(Store['GARVEY:v1:state:0']==before)
for _,name in ipairs(G.dummies) do assert(city:GetNumBuilding(GameInfoTypes['BUILDING_GARVEY_'..name])==0) end
RejectWrites=false;G=Reload();assert(G.State(0).insub==1 and G.CanRoll(0,ready))
-- Existing human units: reconciliation is linear and no idle callback remains.
for i=10,109 do NewCity(p,i,i%2==0) end
for i=30,1029 do NewUnit(p,i,-6,20) end
assert(G.Roll(0,5,ready));Flush()
local n=0;for c in p:Cities() do assert(c:GetNumBuilding(GameInfoTypes.BUILDING_GARVEY_TIMOTHY)==1);n=n+1 end
assert(n==101 and ContextPtr.update==nil)
