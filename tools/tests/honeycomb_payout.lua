-- SQL-backed modeled settlement follows audited native base-yield/modifier math.
-- This is stronger than checking markers, but is still NOT native execution.
local T=HCC_Test
local city=T.City(500,0); city.buildings[30]=1; T.Assign(city,4)
local function CityYields()
  local result={FOOD=0,PRODUCTION=0,CULTURE=0,GOLD=0}
  for building,ys in pairs(HCC_DatabaseYields) do
    local copies=city:GetNumBuilding(building)
    for yield,value in pairs(ys) do result[yield]=result[yield]+copies*value end
  end
  return result
end
local function Settle()
  local result=CityYields()
  return {production=result.PRODUCTION*100,culture=result.CULTURE*100,food=result.FOOD*100,
    gold=math.floor(result.GOLD*(100+HCC_MarketGoldModifier))}
end
local function Unique(expectedP,expectedC,expectedF,expectedG)
  local result=Settle()
  local ordinary=HCC_MarketGoldBase*(100+HCC_MarketGoldModifier)
  assert(result.production==expectedP*100 and result.culture==expectedC*100 and result.food==expectedF*100)
  assert(result.gold-ordinary==expectedG*(100+HCC_MarketGoldModifier),'Market percent modifier lost')
end
T.Boundary(); Unique(4,1,1,2)
-- The next native-like pass runs before PlayerDoTurn; mid/interturn changes do
-- not rewrite the staged state. Pillage and repair must be checked separately.
city.plots[1].pillaged=true; T.SetTurn(T.Turn()+1); Unique(4,1,1,2)
GameEvents.PlayerDoTurn.Fire(0); Unique(4,1,1,2)
GameEvents.PlayerDoneTurn.Fire(0); Unique(3,1,1,1)
city.plots[1].pillaged=false; T.SetTurn(T.Turn()+1); Unique(3,1,1,1)
GameEvents.PlayerDoTurn.Fire(0); Unique(3,1,1,1)
GameEvents.PlayerDoneTurn.Fire(0); Unique(4,1,1,2)
print('PASS HCC SQL-backed modeled next payout: Production/Culture/Food and inherited Market Gold modifier; separate interturn pillage and repair (not native)')
