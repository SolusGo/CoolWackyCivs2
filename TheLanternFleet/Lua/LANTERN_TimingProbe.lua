-- OPTIONAL read-only native diagnostic. Not included by the gameplay entry.
-- In FireTuner select LANTERN_Harbors, then include("LANTERN_TimingProbe").
-- Attach before ending a turn. Remove with LANTERN_StopTimingProbe().
if LANTERN_StopTimingProbe then LANTERN_StopTimingProbe() end
local handlers = {}
local function Record(phase,id,tag)
  local p = Players[id]
  if not p or p:GetCivilizationType() ~= GameInfoTypes.CIVILIZATION_LANTERN_FLEET then return end
  print('LANTERN_TIMING',phase,Game.GetGameTurn(),id,tostring(tag),p:IsTurnActive(),
    p:GetGoldTimes100(),p:GetJONSCultureTimes100(),p:GetScience())
  for c in p:Cities() do
    print('LANTERN_CITY',c:GetID(),c:IsCoastal(-1),
      c:GetNumRealBuilding(GameInfoTypes.BUILDING_LANTERN_GUARDED_HARBOR),
      c:GetNumRealBuilding(GameInfoTypes.BUILDING_LANTERN_SIGNAL_GOLD),
      c:GetYieldRate(YieldTypes.YIELD_SCIENCE),c:GetYieldRate(YieldTypes.YIELD_CULTURE),c:GetYieldRate(YieldTypes.YIELD_GOLD))
  end
end
for _,item in ipairs({{Events.AIProcessingStartedForPlayer,'status_start'},
    {GameEvents.PlayerDoTurn,'after_native_economy'}}) do
  local event,phase=item[1],item[2]
  local f=function(id,tag)Record(phase,id,tag)end
  event.Add(f);handlers[#handlers+1]={event,f}
end
function LANTERN_StopTimingProbe()
  for _,h in ipairs(handlers) do h[1].Remove(h[2]) end
  handlers={}
end
print('LANTERN_TIMING probe attached; stock/yield logs alone need controlled paired-save comparison; see Testing.md')
