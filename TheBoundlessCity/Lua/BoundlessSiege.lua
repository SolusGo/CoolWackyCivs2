-- Restricted native-legal demolition. Normal city capture remains disabled.
local B=MapModData.BoundlessCity
function B.NativeRazable(city)
 if city:IsOriginalCapital() or city:IsHolyCityAnyReligion() then return false end
 local owner=Players[city:GetOwner()];local original=Players[city:GetOriginalOwner()]
 return owner and not owner:IsMinorCiv() and not (original and original:IsMinorCiv()) and owner:CanRaze(city,false)
end
local function meleeUnits(s)
 local result={}
 for unit in Players[s.pid]:Units() do
  if unit:IsCombatUnit() and not unit:IsRanged() and not unit:IsEmbarked() and unit:MovesLeft()>0 then result[#result+1]=unit end
 end
 table.sort(result,function(a,b) return a:GetID()<b:GetID() end);return result
end
function B.SiegeCheck(s,n,melees)
 if s.incompatible or not B.City(s) or not Players[s.pid]:IsAlive() or not Players[s.pid]:IsTurnActive() then return false,nil,'SIEGE_INACTIVE' end
 local plot=type(n)=='number' and Map.GetPlotByIndex(n);local city=plot and plot:GetPlotCity()
 if not city or city:GetOwner()==s.pid then return false,nil,'SIEGE_INVALID' end
 -- Visibility precedes damage/protection details so fog does not reveal city state.
 if not plot:IsVisible(Players[s.pid]:GetTeam(),false) then return false,nil,'SIEGE_NOT_VISIBLE' end
 if city:IsOriginalCapital() or city:IsHolyCityAnyReligion() or city:IsRazing() then return false,nil,'SIEGE_PROTECTED' end
 local owner=Players[city:GetOwner()];local original=Players[city:GetOriginalOwner()]
 if not owner or owner:IsMinorCiv() or (original and original:IsMinorCiv()) then return false,nil,'SIEGE_PROTECTED' end
 if not Teams[Players[s.pid]:GetTeam()]:IsAtWar(owner:GetTeam()) then return false,nil,'SIEGE_NOT_AT_WAR' end
 if city:GetDamage()<city:GetMaxHitPoints()-1 then return false,nil,'SIEGE_DAMAGE' end
 -- CanRaze checks ownership, game options, original capitals, holy cities,
 -- unique luxuries and native Lua vetoes. Never pretend it accepts foreign cities.
 -- This check succeeds only for settlements their CURRENT owner can legally raze.
 if not B.NativeRazable(city) then
  return false,nil,city:GetOriginalOwner()==city:GetOwner() and 'SIEGE_ENGINE_LIMIT' or 'SIEGE_NATIVE_RULE'
 end
 for _,unit in ipairs(melees or meleeUnits(s)) do
  if Map.PlotDistance(unit:GetX(),unit:GetY(),plot:GetX(),plot:GetY())==1 then
   return true,{x=plot:GetX(),y=plot:GetY(),owner=city:GetOwner(),founded=city:GetGameTurnFounded(),city=city:GetID(),unit=unit:GetID()},'SIEGE_READY'
  end
 end
 return false,nil,'SIEGE_MELEE'
end
function B.QueueSiege(s,n,dispatched)
 if s.sieges[n] then return false,'SIEGE_QUEUED' end
 local ok,r,reason=B.MilitaryCheck(s,n);if not ok then return false,reason end
 s.sieges[n]=r;B.Save(s);if not dispatched then B.Schedule(s.pid) end;return true
end
function B.ProcessSieges(s)
 if s.incompatible then return end
 for _,n in ipairs(B.Keys(s.sieges)) do local record=s.sieges[n]
  local ok,current=B.MilitaryCheck(s,n,nil,record.action or 'DEMOLISH')
  s.sieges[n]=nil;B.Save(s)
  if ok and current.owner==record.owner and current.founded==record.founded and (not record.city or current.city==record.city)
   and (not record.original or current.original==record.original)
   and (not record.birth or (current.unit==record.unit and current.birth==record.birth)) then
   if current.action~='DEMOLISH' then B.ResolveMilitary(s,current)
   else
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
    if tile:GetOwner()==current.owner and not tile:IsCity() then tile:SetOwner(-1,-1,true) end
   end
   s.history[#s.history+1]={kind='DEMOLITION',x=current.x,y=current.y,turn=B.Now()}
   B.Save(s);B.Notify(s,'DEMOLISHED')
   end
  end
 end
end
function B.SiegeRows(s,onlyReady)
 local result={};local melees=meleeUnits(s);local team=Players[s.pid]:GetTeam()
 for pid=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do local p=Players[pid]
  if p and p:IsAlive() and pid~=s.pid and not p:IsBarbarian() then
   for city in p:Cities() do local plot=Map.GetPlot(city:GetX(),city:GetY());local n=plot:GetPlotIndex()
    if city:IsRevealed(team,false) then
     local ready,record,reason=B.MilitaryCheck(s,n,melees)
     if not onlyReady or ready then
      if s.sieges[n] then ready=false;reason='SIEGE_QUEUED' end
      result[#result+1]={n=n,x=city:GetX(),y=city:GetY(),ready=ready,reason=reason,action=record and record.action,
       protection=plot:IsVisible(team,false) and city:IsOriginalCapital() and 'SIEGE_CAPITAL' or nil,
       name=plot:IsVisible(team,false) and city:GetName() or B.Text('SIEGE_KNOWN_CITY')}
     end
    end
   end
  end
 end
 table.sort(result,function(a,b) return a.n<b.n end);return result
end
function B.QueueReadyMilitary(s,dispatched)
 if s.incompatible or Players[s.pid]:IsHuman() or not Players[s.pid]:IsAlive() then return end
 for _,r in ipairs(B.SiegeRows(s,true)) do if r.ready then B.QueueSiege(s,r.n,dispatched) end end
end
include('BoundlessMilitary')
