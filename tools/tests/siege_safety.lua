local B=MapModData.BoundlessCity;local s=B.State(0)
local target=MakeCity(1,16,5,3,2);target.original=2;target.previous=2;target.damage=199;Players[1].cities[#Players[1].cities+1]=target
local unit=MakeUnit(20,600);function unit:GetX() return 15 end;function unit:GetY() return 5 end
unit.moves=60;function unit:MovesLeft() return self.moves end
local n=Map.GetPlot(16,5).n
assert(B.SiegeCheck(s,n));assert(B.QueueSiege(s,n));assert(not B.QueueSiege(s,n),'duplicate demolition request')
insideCapture=true;assert(Map.GetPlot(16,5):IsCity());insideCapture=false;Pump()
assert(not Map.GetPlot(16,5):IsCity() and Map.GetPlot(16,5).owner==-1 and Players[0]:GetNumCities()==1)
assert(Map.GetPlot(17,5).owner==-1 and Map.GetPlot(18,5).owner==-1,'demolition frees only this settlement territory')
assert(unit.moves==0 and cultureAward==0,'no repeatable conquest rewards or free action')
unit.moves=60
for _,kind in ipairs({'original','holy','minor','protected','own-founded','not-defeated','no-razing'}) do
 local c=MakeCity(1,16,5,3,2);c.original=2;c.previous=2;c.damage=199
 if kind=='original' then c.originalCapital=true elseif kind=='holy' then c.holy=true
 elseif kind=='minor' then Players[1].minor=true elseif kind=='protected' then c.protected=true
 elseif kind=='own-founded' then c.original=1 elseif kind=='not-defeated' then c.damage=198
 elseif kind=='no-razing' then Players[1].noRazing=true end
 assert(not B.QueueSiege(s,n),kind..' must remain protected')
 assert(Map.GetPlot(16,5):GetPlotCity()==c);Players[1].minor=false;Players[1].noRazing=false
end
local c=MakeCity(1,16,5,3,2);c.original=2;c.damage=199;assert(B.QueueSiege(s,n))
c.founded=1;Pump();assert(Map.GetPlot(16,5):GetPlotCity()==c,'a replacement city must not inherit an old demolition request')
print('PASS native-legal siege demolition; capitals, holy cities, city-states, rule vetoes and replacement safety')
