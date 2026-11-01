-- OPTIONAL read-only FireTuner diagnostic. Never loaded by the gameplay XML.
-- Select LANTERN_Harbors, include("LANTERN_TimingProbe"), then record paired
-- controlled boundaries. Nothing here spawns units, alters buildings or pays yields.
if LANTERN_StopTimingProbe then LANTERN_StopTimingProbe() end
local handlers, samples, sequence = {}, {}, 0
local function Loaded()
  if not (UI and UI.IsLoadedGame) then return 'unsupported' end
  local ok,result=pcall(UI.IsLoadedGame,UI)
  return ok and tostring(result) or 'error'
end
local function Record(phase,id,tag)
  local p=Players[id]
  if not p or p:GetCivilizationType() ~= GameInfoTypes.CIVILIZATION_LANTERN_FLEET then return end
  local tech=p:GetCurrentResearch()
  local progress=tech and tech>=0 and p:GetResearchProgressTimes100(tech) or nil
  local row={turn=Game.GetGameTurn(),player=id,phase=phase,tech=tech,research100=progress,
    gold100=p:GetGoldTimes100(),culture100=p:GetJONSCultureTimes100()}
  sequence=sequence+1;samples[sequence]=row
  print('LANTERN_TIMING',sequence,phase,row.turn,id,'human='..tostring(p:IsHuman()),
    'active='..tostring(p:IsTurnActive()),'tagType='..type(tag),'tag='..tostring(tag),
    'loaded='..Loaded(),'startTurn='..tostring(Game.GetStartTurn()),
    'tech='..tostring(tech),'research100='..tostring(progress),
    'culture100='..row.culture100,'gold100='..row.gold100)
  local data=p:GetScriptData() or ''
  print('LANTERN_PHASE',data:match('%[LANTERN1|[^%]]*%]') or '-',data:match('%[LANTERN2|[^%]]*%]') or '-')
  for city in p:Cities() do
    print('LANTERN_CITY',city:GetID(),city:GetX(),city:GetY(),city:IsCoastal(-1),
      city:GetNumRealBuilding(GameInfoTypes.BUILDING_LANTERN_GUARDED_HARBOR),
      city:GetNumRealBuilding(GameInfoTypes.BUILDING_LANTERN_SIGNAL_GOLD),
      city:GetYieldRate(YieldTypes.YIELD_SCIENCE),city:GetYieldRate(YieldTypes.YIELD_CULTURE),city:GetYieldRate(YieldTypes.YIELD_GOLD))
  end
  return sequence
end
function LANTERN_TimingMark(label,id)
  return Record(label or 'manual',id or Game.GetActivePlayer())
end
function LANTERN_TimingDelta(before,after)
  local a,b=samples[before],samples[after]
  assert(a and b and a.player==b.player,'select two samples for the same player')
  assert(a.tech==b.tech and a.research100 and b.research100,'use an unchanged unfinished research target')
  local result={research100=b.research100-a.research100,culture100=b.culture100-a.culture100,gold100=b.gold100-a.gold100}
  print('LANTERN_DELTA',before,after,'research100='..result.research100,
    'culture100='..result.culture100,'gold100='..result.gold100)
  return result
end
local function Hook(event,phase)
  if not (event and event.Add) then print('LANTERN_TIMING unavailable event',phase);return end
  local f=function(id,tag)Record(phase,id,tag)end
  event.Add(f);handlers[#handlers+1]={event,f}
end
Hook(Events.AIProcessingStartedForPlayer,'candidate_status')
Hook(GameEvents.PlayerDoTurn,'after_native_economy')
function LANTERN_StopTimingProbe()
  for _,h in ipairs(handlers)do if h[1].Remove then h[1].Remove(h[2])end end
  handlers={}
end
print('LANTERN_TIMING attached: research progress and stock deltas require controlled A/B saves; no native acceptance is implied')
