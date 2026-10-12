local B=MapModData.BoundlessCity;local s=B.State(0)
local target=MakeCity(1,16,5,3,2);target.original=2;target.previous=2;target.damage=199;Players[1].cities[#Players[1].cities+1]=target
local unit=MakeUnit(20,600);function unit:GetX() return 15 end;function unit:GetY() return 5 end
unit.moves=60;function unit:MovesLeft() return self.moves end
local n=Map.GetPlot(16,5).n
local capitalPlot=Map.GetPlot(60,5);capitalPlot.owningCity=target.id
assert(B.SiegeCheck(s,n));assert(B.QueueSiege(s,n));assert(not B.QueueSiege(s,n),'duplicate demolition request')
insideCapture=true;assert(Map.GetPlot(16,5):IsCity());insideCapture=false;Pump()
assert(not Map.GetPlot(16,5):IsCity() and Map.GetPlot(16,5).owner==-1 and Players[0]:GetNumCities()==1)
assert(Map.GetPlot(17,5).owner==-1 and Map.GetPlot(18,5).owner==-1,'demolition frees only this settlement territory')
assert(capitalPlot.owner==1 and capitalPlot:GetPlotCity()==foreign,'another city center must never be released through a stale purchase ID')
assert(unit.moves==0 and cultureAward==0,'no repeatable conquest rewards or free action')
local history=#s.history;B.States={};B.Caches={};B.Initialize(0);s=B.State(0)
assert(#s.history==history and next(s.sieges)==nil and not Map.GetPlot(16,5):IsCity(),'demolition reload must not resurrect a queued reward')
unit.moves=60
for _,kind in ipairs({'original','holy','minor','protected','own-founded','not-defeated','no-razing'}) do
 local c=MakeCity(1,16,5,3,2);c.original=2;c.previous=2;c.damage=199
 if kind=='original' then c.originalCapital=true elseif kind=='holy' then c.holy=true
 elseif kind=='minor' then Players[1].minor=true elseif kind=='protected' then c.protected=true
 elseif kind=='own-founded' then c.original=1 elseif kind=='not-defeated' then c.damage=198
 elseif kind=='no-razing' then Players[1].noRazing=true end
 local ok,_,reason=B.SiegeCheck(s,n);assert(not ok,kind..' must remain protected from demolition')
 if kind=='own-founded' then assert(reason=='SIEGE_ENGINE_LIMIT')
 elseif kind=='not-defeated' then assert(reason=='SIEGE_DAMAGE')
 elseif kind=='protected' or kind=='no-razing' then assert(reason=='SIEGE_NATIVE_RULE')
 else assert(reason=='SIEGE_PROTECTED') end
 assert(Map.GetPlot(16,5):GetPlotCity()==c);Players[1].minor=false;Players[1].noRazing=false
end
local c=MakeCity(1,16,5,3,2);c.original=2;c.damage=199;assert(B.QueueSiege(s,n))
c.founded=1;Pump();assert(Map.GetPlot(16,5):GetPlotCity()==c,'a replacement city must not inherit an old demolition request')
unit.moves=0;local ok,_,reason=B.SiegeCheck(s,n);assert(not ok and reason=='SIEGE_MELEE')
unit.moves=60;local nativeWar=Teams[0].IsAtWar;Teams[0].IsAtWar=function() return false end
ok,_,reason=B.SiegeCheck(s,n);assert(not ok and reason=='SIEGE_NOT_AT_WAR');Teams[0].IsAtWar=nativeWar
Map.GetPlot(16,5).visible=false;ok,_,reason=B.SiegeCheck(s,n);assert(not ok and reason=='SIEGE_NOT_VISIBLE')
Map.GetPlot(16,5).visible=true;c.original=1;Players[1].cities[#Players[1].cities+1]=c
local queued=0;local oldQueue=B.QueueSiege;B.QueueSiege=function(...) queued=queued+1;return oldQueue(...) end
for _=1,4 do for _,r in ipairs(B.SiegeRows(s,true)) do if r.ready then B.QueueSiege(s,r.n) end end end
assert(queued==1 and s.sieges[n].action=='SUBJUGATE','AI queues one safe subjugation instead of rejected demolition');B.QueueSiege=oldQueue
Pump();assert(c.owner==1 and Map.GetPlot(16,5):GetPlotCity()==c);unit.moves=60
local oldCity=MakeCity(1,16,5,3,2);oldCity.original=2;oldCity.damage=199;assert(B.QueueSiege(s,n))
local replacement=MakeCity(1,16,5,3,2);replacement.original=2;replacement.damage=199
Pump();assert(Map.GetPlot(16,5):GetPlotCity()==replacement and unit.moves==60,'same-turn replacement ID must reject an old queued action')
print('PASS native-legal siege demolition; capitals, holy cities, city-states, rule vetoes and replacement safety')
