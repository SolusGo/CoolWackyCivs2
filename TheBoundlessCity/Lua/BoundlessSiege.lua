-- Restricted native-legal demolition. Normal city capture remains disabled.
local B=MapModData.BoundlessCity
function B.NativeRazable(city)
 if city:IsOriginalCapital() or city:IsHolyCityAnyReligion() then return false end
 local owner=Players[city:GetOwner()];local original=Players[city:GetOriginalOwner()]
 return owner and not owner:IsMinorCiv() and not (original and original:IsMinorCiv()) and owner:CanRaze(city,false)
end
function B.SiegeCheck(s,n)
 if s.incompatible or not B.City(s) or not Players[s.pid]:IsAlive() or not Players[s.pid]:IsTurnActive() then return false end
 local plot=type(n)=='number' and Map.GetPlotByIndex(n);local city=plot and plot:GetPlotCity()
 if not city or city:GetOwner()==s.pid or city:IsOriginalCapital() or city:IsHolyCityAnyReligion() or city:IsRazing() then return false end
 local owner=Players[city:GetOwner()];local original=Players[city:GetOriginalOwner()]
 if not owner or owner:IsMinorCiv() or (original and original:IsMinorCiv()) then return false end
 if not plot:IsVisible(Players[s.pid]:GetTeam(),false) then return false end
 if not Teams[Players[s.pid]:GetTeam()]:IsAtWar(owner:GetTeam()) then return false end
 if city:GetDamage()<city:GetMaxHitPoints()-1 then return false end
 -- CanRaze checks ownership, game options, original capitals, holy cities,
 -- unique luxuries and native Lua vetoes. Never pretend it accepts foreign cities.
 -- This check succeeds only for settlements their CURRENT owner can legally raze.
 if not B.NativeRazable(city) then return false end
 local eligible={}
 for unit in Players[s.pid]:Units() do
  if unit:IsCombatUnit() and not unit:IsRanged() and not unit:IsEmbarked() and unit:MovesLeft()>0
   and Map.PlotDistance(unit:GetX(),unit:GetY(),plot:GetX(),plot:GetY())==1 then eligible[#eligible+1]=unit end
 end
 table.sort(eligible,function(a,b) return a:GetID()<b:GetID() end)
 if not eligible[1] then return false end
 return true,{x=plot:GetX(),y=plot:GetY(),owner=city:GetOwner(),founded=city:GetGameTurnFounded(),unit=eligible[1]:GetID()}
end
function B.QueueSiege(s,n)
 if s.sieges[n] then return false end
 local ok,r=B.SiegeCheck(s,n);if not ok then return false end
 s.sieges[n]=r;B.Save(s);B.Schedule(s.pid);return true
end
function B.ProcessSieges(s)
 if s.incompatible then return end
 for _,n in ipairs(B.Keys(s.sieges)) do local record=s.sieges[n]
  local ok,current=B.SiegeCheck(s,n)
  s.sieges[n]=nil;B.Save(s)
  if ok and current.owner==record.owner and current.founded==record.founded then
   local plot=Map.GetPlotByIndex(n);local city=plot:GetPlotCity()
   local unit=Players[s.pid]:GetUnitByID(current.unit)
   -- Rare demolition may inspect the map once; opening the UI never does.
   local released={};local cityID=city:GetID()
   for index=0,Map.GetNumPlots()-1 do local tile=Map.GetPlotByIndex(index)
    if tile:GetOwner()==current.owner and tile:GetCityPurchaseID()==cityID then released[#released+1]=index end
   end
   unit:FinishMoves()
   -- Outside all combat/capture stacks; native owner executes its verified legal
   -- disband operation. Never dereference city/unit after destruction.
   Players[current.owner]:Disband(city)
   for _,index in ipairs(released) do local tile=Map.GetPlotByIndex(index)
    if tile:GetOwner()==current.owner then tile:SetOwner(-1,-1,true) end
   end
   s.history[#s.history+1]={kind='DEMOLITION',x=current.x,y=current.y,turn=B.Now()}
   B.Save(s);B.Notify(s,'DEMOLISHED')
  end
 end
end
function B.SiegeRows(s)
 local result={}
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
  if p and p:IsAlive() and pid~=s.pid and not p:IsBarbarian() then
   for city in p:Cities() do local n=Map.GetPlot(city:GetX(),city:GetY()):GetPlotIndex()
    if B.SiegeCheck(s,n) then result[#result+1]={n=n,x=city:GetX(),y=city:GetY(),name=city:GetName()} end
   end
  end
 end
 table.sort(result,function(a,b) return a.n<b.n end);return result
end
