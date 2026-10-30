-- Fault-path regressions exercise the shipped controller, never a copied formula.
local T=HCC_Test
local function Reload()
  __HCC_CONTEXT_CONTROLLER=nil; ContextPtr={SetShutdown=function() end}; LoadHCC()
  Events.LoadScreenClose.Fire()
end
local cases={}
function cases.partial_reload()
  local c=T.City(100,0); c.buildings[30]=1; T.Assign(c,4); c.failBefore=2
  T.Boundary(); T.Assign(c,1); local q=T.Queries()
  Reload(); T.Check(c,4,1,1,2)
  assert(T.Queries()==q,'recovery recounted changed assignments')
end
function cases.silent_setter()
  local c=T.City(101,0); c.buildings[30]=1; T.Assign(c,4); c.silent=1
  T.Boundary(); T.Check(c,4,1,1,2)
end
function cases.reentrant_sale()
  local c=T.City(102,0); c.buildings[30]=1; T.Assign(c,4)
  HCCOnSet=function(city)
    if city==c then HCCOnSet=nil; c.buildings[30]=0; GameEvents.CitySoldBuilding.Fire(0,c.id,30) end
  end
  T.Boundary(); T.Check(c,4,1,0,0)
end
function cases.city_failure_isolation()
  local bad=T.City(103,0); T.Assign(bad,4); bad.failBefore=2
  local good=T.City(104,0); T.Assign(good,4)
  -- Make the iterator deterministic so the fault precedes the healthy city.
  local original=Players[0].Cities
  Players[0].Cities=function() local i=0; local list={bad,good}; return function() i=i+1; return list[i] end end
  T.Boundary(); Players[0].Cities=original
  T.Check(good,4,1,0,0)
  Reload(); T.Check(bad,4,1,0,0)
end
function cases.receipt_failure()
  local c=T.City(105,0); c.buildings[30]=1; T.Assign(c,4)
  Players[0].failReceipt=true; T.Boundary()
  T.Assign(c,1); GameEvents.PlayerDoneTurn.Fire(0); T.Check(c,4,1,1,2)
end
function cases.reentrant_rebuild()
  local c=T.City(106,0); c.buildings[30]=1; T.Assign(c,4)
  HCCOnSet=function(city)
    if city==c then
      HCCOnSet=nil; c.buildings[30]=0; GameEvents.CitySoldBuilding.Fire(0,c.id,30)
      c.buildings[30]=1; GameEvents.CityConstructed.Fire(0,c.id,30,false,false)
    end
  end
  T.Boundary(); T.Check(c,4,1,1,0)
  T.Boundary(); T.Check(c,4,1,1,2)
end
function cases.exchange_eligibility_frozen()
  local a,b=T.City(107,0),T.City(108,0); T.Assign(a,4); T.Assign(b,4)
  local original=Players[0].Cities
  Players[0].Cities=function() local i=0; local list={a,b}; return function() i=i+1; return list[i] end end
  HCCOnSet=function(city)
    if city==a then HCCOnSet=nil; b.buildings[30]=1; GameEvents.CityConstructed.Fire(0,b.id,30,false,false) end
  end
  T.Boundary(); Players[0].Cities=original
  T.Check(b,4,1,1,0)
end
function cases.pending_sale_rebuild()
  local c=T.City(109,0); c.buildings[30]=1; T.Assign(c,4); c.failBefore=2
  T.Boundary(); c.buildings[30]=0; GameEvents.CitySoldBuilding.Fire(0,c.id,30)
  c.buildings[30]=1; GameEvents.CityConstructed.Fire(0,c.id,30,false,false)
  T.Assign(c,0); Reload(); T.Check(c,4,1,1,0)
end
function cases.pending_capture_recapture()
  local c=T.City(110,0); c.buildings[30]=1; T.Assign(c,4); c.failBefore=2
  T.Boundary(); T.Transfer(c,1); T.Check(c,0,0,1,0)
  T.Transfer(c,0); Reload(); T.Check(c,0,0,1,0)
  T.Assign(c,2); T.Boundary(); T.Check(c,2,1,1,1)
end
function cases.pending_destroy_reuse()
  local c=T.City(111,0); T.Assign(c,4); c.failBefore=2; T.Boundary()
  Players[0].cities[c.id]=nil
  local replacement=T.City(111,0); replacement.founded=T.Turn()
  local queries=T.Queries(); Reload(); T.Check(replacement,0,0,0,0)
  assert(T.Queries()==queries,'destroyed-city recovery counted new city')
end
function cases.retry_owner_and_script_coexistence()
  local c=T.City(112,0); T.Assign(c,4); c.failBefore=100
  T.Boundary(); T.Assign(c,0); c.failBefore=0
  local queries=T.Queries(); GameEvents.PlayerDoTurn.Fire(0); T.Check(c,4,1,0,0)
  assert(T.Queries()==queries,'owner repair recounted')
  HCCOnSet=function(city)
    if city==c then HCCOnSet=nil; Players[0].data=Players[0].data..'|OTHER_DURING_SET|' end
  end
  T.Boundary(); assert(Players[0].data:find('|OTHER_DURING_SET|',1,true))
  assert(not Players[0].data:find('[HCCP2:',1,true),'completed snapshot kept pending journal')
end
function cases.reentrant_capture_and_destroy()
  local c=T.City(113,0); T.Assign(c,4)
  HCCOnSet=function(city)
    if city==c then HCCOnSet=nil; T.Transfer(c,1) end
  end
  T.Boundary(); T.Check(c,0,0,0,0)
  local d=T.City(114,0); T.Assign(d,4)
  HCCOnSet=function(city)
    if city==d then
      HCCOnSet=nil; Players[0].cities[d.id]=nil
      d.GetOwner=function() error('stale destroyed city reference') end
    end
  end
  T.Boundary()
  assert(not Players[0].data:find('[HCCP2:',1,true),'destroyed city blocked snapshot completion')
end
function cases.partial_restore_with_serialized_initialized()
  local c=T.City(115,0); c.buildings[30]=1; T.Assign(c,4); T.Boundary()
  __HCC_CONTEXT_CONTROLLER=nil; ContextPtr={SetShutdown=function() end}; LoadHCC()
  -- The engine's serialized IsFinalInitialized remains true, while city state
  -- can still be incomplete. Ordinary dirty notifications must remain inert.
  c.buildings[30]=0; local before=T.Writes()
  Events.SpecificCityInfoDirty.Fire(0,c.id)
  c.buildings[30]=1; Events.LoadScreenClose.Fire()
  T.Check(c,4,1,1,2); assert(T.Writes()==before,'partial restore cleared valid Gold')
end
function cases.large_reentrant_queue()
  local early=T.City(116,0); early.buildings[30]=1; T.Assign(early,4); T.Boundary()
  local batch={early}
  for id=200,299 do local c=T.City(id,0); T.Assign(c,4); batch[#batch+1]=c end
  local original=Players[0].Cities
  Players[0].Cities=function() local i=0; return function() i=i+1; return batch[i] end end
  HCCOnSet=function(city)
    if city==batch[#batch] then
      HCCOnSet=nil; early.buildings[30]=0; GameEvents.CitySoldBuilding.Fire(0,early.id,30)
    end
  end
  T.Boundary(); Players[0].Cities=original; T.Check(early,4,1,0,0)
end
function cases.context_handoff_during_setter()
  local c=T.City(117,0); c.buildings[30]=1; T.Assign(c,4)
  HCCOnSet=function(city)
    if city==c then
      HCCOnSet=nil; Reload()
      c.buildings[30]=0; GameEvents.CitySoldBuilding.Fire(0,c.id,30)
      c.buildings[30]=1; GameEvents.CityConstructed.Fire(0,c.id,30,false,false)
    end
  end
  T.Boundary(); T.Check(c,4,1,1,0)
  assert(#GameEvents.PlayerDoneTurn.handlers==1,'handoff duplicated callbacks')
end
function cases.completed_lifecycle_reload()
  local c=T.City(118,0); T.Assign(c,4); T.Boundary(); T.Check(c,4,1,0,0)
  c.buildings[30]=1; GameEvents.CityConstructed.Fire(0,c.id,30,false,false)
  Reload(); T.Check(c,4,1,1,0) -- construction does not gain Gold merely by loading
  T.Boundary(); T.Check(c,4,1,1,2)
  c.buildings[30]=0; GameEvents.CitySoldBuilding.Fire(0,c.id,30)
  Reload(); T.Check(c,4,1,0,0) -- removed Exchange stays absent without clearing UA
  T.Transfer(c,1); Reload(); T.Check(c,0,0,0,0)
  T.Transfer(c,0); Reload(); T.Check(c,0,0,0,0)
end
if HCC_AUDIT_PROBE then
  assert(cases[HCC_AUDIT_PROBE])()
else
  for _,name in ipairs({'partial_reload','silent_setter','reentrant_sale','city_failure_isolation','receipt_failure',
      'reentrant_rebuild','exchange_eligibility_frozen','pending_sale_rebuild','pending_capture_recapture',
      'pending_destroy_reuse','retry_owner_and_script_coexistence','reentrant_capture_and_destroy',
      'partial_restore_with_serialized_initialized','large_reentrant_queue','context_handoff_during_setter',
      'completed_lifecycle_reload'}) do cases[name]() end
  print('PASS HCC hardening: 16 frozen-recovery, setter/receipt failure, reentrancy, Exchange eligibility, ownership/destruction, partial-load, large-queue and mid-write context regressions')
end
