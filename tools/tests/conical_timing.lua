-- Explicit economic phases, with the native network represented ONLY by a flag.
-- This is evidence for the shipped controller's timing, not Harbor pathfinding.
local p=Player(0,true);p.capital=City(p,0,true,false)
local c=City(p,1,false,true)
LoadConical()
local function Settle(production,culture,gold)
  local a,b,d=Harvest(c)
  assert(a==production and b==culture and d==gold,'wrong settlement phase yields')
end
for _,route in ipairs({'road','railroad','Harbor','mixed','two alternative routes'}) do
  -- Old disconnected cache at end turn; no event may invent a fresh native value.
  c.connected=false;GameEvents.PlayerDoTurn.Fire(0)
  c.route=route;c.nextNativeFlag=true
  GameEvents.PlayerDoneTurn.Fire(0);Settle(0,1,0)
  -- Native start-turn refresh, then settlement, THEN PlayerDoTurn (pinned source).
  c.connected=c.nextNativeFlag;Settle(0,1,0)
  GameEvents.PlayerDoTurn.Fire(0);Settle(2,2,2)
  GameEvents.PlayerDoneTurn.Fire(0);Settle(2,2,2)
  -- Losing one alternative route while native connectivity remains true is binary.
  c.route='one remaining route';c.connected=true
  GameEvents.PlayerDoTurn.Fire(0);Settle(2,2,2)
  -- Final break / naval blockade: old true cache survives until native refresh.
  c.nextNativeFlag=false;GameEvents.PlayerDoneTurn.Fire(0);Settle(2,2,2)
  c.connected=c.nextNativeFlag;Settle(2,2,2)
  GameEvents.PlayerDoTurn.Fire(0);Settle(0,1,0)
end
-- A verified lifecycle notification AFTER refresh can repair BEFORE settlement.
c.connected=true;Events.SpecificCityInfoDirty.Fire(0,c.id);Settle(2,2,2)
c.connected=false;GameEvents.CityConstructed.Fire(0,c.id,O,false,false);Settle(0,1,0)
-- Capital exclusion is immediate at the capital notification, even with old flags.
c.connected=true;p.capital=c;GameEvents.CapitalChanged.Fire(0,c.id,0);Settle(0,1,0)
assert(GameEvents.CityConnections==nil and GameEvents.CityConnected==nil and GameEvents.TileRouteChanged==nil)
print('PASS Conical old-cache -> refresh -> first settlement -> reconciliation -> subsequent settlement; known delay, earlier lifecycle repair and binary alternative/Harbor-shaped states (synthetic)')
