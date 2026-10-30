include('InstanceManager')
include('JIN_Core')
local J=MapModData.JIN
local C=J.C
local manager=InstanceManager:new('JIN_Row','Root',Controls.Rows)
local tab='Overview';local open=false;local rendering=false;local ending=false
local renderSerial,lastStamp;local roster,minors,resourceTypes
local function loc(key) return Locale.ConvertTextKey('TXT_KEY_JIN_'..key) end
local function coord(index) local p=J.Plot(index);return p and ('('..p:GetX()..','..p:GetY()..')') or '(lost)' end
local function count(t)local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function row(label,button,kind,a,b,enabled,why)
 local instance=manager:GetInstance();instance.Text:SetText(label)
 instance.Root:SetToolTipString(why or label)
 instance.Action:SetHide(not button)
 if button then
  instance.Action:SetText(button);instance.Action:SetDisabled(enabled==false);instance.Action:SetToolTipString(why or label)
  local id=Game.GetActivePlayer();local serial=renderSerial
  instance.Action:RegisterCallback(Mouse.eLClick,function()
   if not J.active or Game.GetActivePlayer()~=id or not J.IsJin(id) or not Players[id]:IsTurnActive() then return end
   if kind=='LOOK' then local p=J.Plot(a);if p then UI.LookAt(p,0) end;return end
   local ok,message=J.Action(id,serial,kind,a,b)
   Controls.Message:SetText(message or (ok and 'Done.' or 'Action unavailable.'));J.UIRefresh()
  end)
 end
end
local function inventory()
 if roster then return end
 roster={};minors={};resourceTypes={}
 local overrides={}
 for r in GameInfo.Civilization_UnitClassOverrides{CivilizationType='CIVILIZATION_JIN_DYNASTY'} do overrides[r.UnitClassType]=r.UnitType end
 for u in GameInfo.Units() do
  local class=GameInfo.UnitClasses[u.Class]
  if (J.Flag(u.IsMounted) or u.CombatClass=='UNITCOMBAT_MOUNTED') and u.Cost>0 and ((overrides[u.Class] and overrides[u.Class]==u.Type) or (not overrides[u.Class] and class and class.DefaultUnit==u.Type)) then
   roster[#roster+1]=u
   for r in GameInfo.Unit_ResourceQuantityRequirements{UnitType=u.Type} do resourceTypes[r.ResourceType]=true end
  end
 end
 for id=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if Players[id] and Players[id]:IsMinorCiv() then minors[#minors+1]=id end end
end
local function stamp(id,s)
 local p=Players[id];local values={tab,s.serial,J.uiRevision or 0,p:GetGold(),p:GetCurrentEra(),J.Now(),tostring(p:IsTurnActive())}
 if tab=='Recruit' then
  for resource in pairs(resourceTypes) do values[#values+1]=p:GetNumResourceAvailable(J.T[resource],true) end
  for _,u in ipairs(roster) do values[#values+1]=J.Tech(id,u.PrereqTech) and '1' or '0' end
  for c in p:Cities() do values[#values+1]=c:Plot():GetNumUnits();values[#values+1]=tostring(c:IsResistance());values[#values+1]=tostring(c:IsRazing()) end
 end
 return table.concat(values,':')
end
local function render(force)
 local id=Game.GetActivePlayer();local visible=J.IsJin(id)
 visible=visible and Players[id]:IsTurnActive() and not ending
 J.panelOpen=visible and open;J.uiTab=tab
 Controls.Open:SetHide(not visible);Controls.Panel:SetHide(not visible or not open)
 if not visible or not open then lastStamp=nil;return end
 if J.busy[id] then return end
 local s=J.State(id)
 if not s then manager:ResetInstances();row('Jin save state is unavailable. Check Lua.log; no rewards will be reset.',nil);return end
 inventory();local current=stamp(id,s)
 if force==false and current==lastStamp then return end
 lastStamp=current;renderSerial=s.serial;manager:ResetInstances()
 local p=Players[id];local horses,capacity=J.Horses(id,s);local trib=J.Tributaries(id,s)
 local emplacements=J.Emplacements(id,s)
 Controls.Overview:SetText(string.format('HORSES %d / %d    |    Cavalry maximum HP: melee +%d / ranged +%d[NEWLINE]TRIBUTARIES %d    |    Outgoing international income +%d%%    |    Mounted Villagers %d / %d    |    Emissaries %d / %d[NEWLINE]LANDMARKS %d / 3    |    EMPLACEMENTS %d    |    KARMA %d / %d    |    BLESSING %d turns',horses,capacity,horses*C.meleeHP,horses*C.rangedHP,trib,trib>0 and C.tradePercent or 0,J.Count(id,'MOUNTED_VILLAGER'),C.villagerCap+C.tributaryVillagers*trib,J.Count(id,'EMISSARY'),C.emissaryCap,J.Tier(s),count(emplacements),s.karma,C.karmaMax,math.max(0,s.blessing-J.Now())))
 if tab=='Overview' then
  row('Reindeer Traders: surplus Food supplements training while growth pauses; no unit Gold-purchase surcharge; native land-route speed 2. Tributary trade income is a separate bonus.',nil)
  for _,key in ipairs({1,2,3,'pasture'}) do local g=s.grass[key]
   if g then
    local active=J.GrassActive(id,key,g);local remaining=J.Scale(C.horseIntervals[math.max(1,J.Tier(s))])-g.elapsed
    row((key=='pasture' and 'Great Pasture ' or ('Grassland '..key..' '))..coord(g.plot)..' — '..g.horses..' / '..C.horseCapacity..' Horses; '..(active and (g.horses==C.horseCapacity and 'full' or (remaining..' owner-turns to next Horse')) or 'inactive: pillaged, destroyed or lost'),'Locate','LOOK',g.plot)
   end
  end
  for tier=1,3 do if s.pending[tier] then
   local sites=J.Candidates(id,s,tier)
   if #sites==0 then row('Tier '..tier..': no legal empty owned site within '..C.siteRadius..' plots. Acquire land or clear an improvement, then reopen.',nil) end
   for _,index in ipairs(sites) do row('Tier '..tier..' candidate '..coord(index)..'. Choose exactly one; others disappear.','Establish','SITE',tier,index,true) end
  end end
  if J.Tier(s)==0 then row('Complete a chosen Landmark to unlock your first Grassland. Use the Landmarks tab.',nil) end
  if J.Has(id,s,'FLOWER_PAGODA') then
   row('Flower Garden '..coord(s.garden)..' — relocation ready in '..math.max(0,s.gardenReady-J.Now())..' turns. Choose an empty owned plot below.',nil)
   local shown={};for c in p:Cities() do
    for _,plot in ipairs(J.Near(c:Plot(),C.siteRadius)) do if not shown[J.Index(plot)] and J.SiteLegal(id,plot) then
     shown[J.Index(plot)]=true;row('Flower Garden near '..c:GetName()..' '..coord(J.Index(plot)),'Place Garden','GARDEN',J.Index(plot),nil,J.Now()>=s.gardenReady,'Radius 2: +25% Worker speed, +15% non-siege land military strength. Relocation cooldown '..J.Scale(C.gardenCooldown)..' turns.')
    end end
   end
  end
 elseif tab=='Landmarks' then
  for _,l in ipairs(C.landmarks) do
   local chosen=s.choices[l.tier];local finished=s.landmarks[l.key];local can=not chosen and p:GetCurrentEra()>=l.era and J.Tier(s)>=l.tier-1
   local status=finished and (J.Has(id,s,l.key) and 'completed' or 'completed; building lost') or (chosen==l.key and 'chosen — construct in capital' or (chosen and 'alternative locked out' or 'available at era '..l.era))
   row('Tier '..l.tier..': '..l.name..' — '..l.cost..' base Production; '..status,'Choose','LANDMARK',l.key,nil,can,loc(l.key..'_HELP'))
  end
 elseif tab=='Recruit' then
  for c in p:Cities() do
   row(c:GetName()..' — '..(J.RecruitSource(id,s,c) and 'Horse supply in influence' or 'Requires stocked Grassland within 2 plots and a War Stable (or Great Pasture).'),nil)
   for _,unit in ipairs(roster) do
      local legal,why=J.RecruitCheck(id,s,c:GetID(),unit.ID)
      row(Locale.ConvertTextKey(unit.Description)..' in '..c:GetName(),'Recruit','RECRUIT',c:GetID(),unit.ID,legal,why)
   end
  end
 elseif tab=='Emissaries' then
  for minor,r in pairs(s.trib) do row('Tributary: '..Players[minor]:GetName()..' '..coord(r.plot)..' — +2 capital Food, +3 Villager cap.','Locate','LOOK',r.plot) end
  local any=false
  for u in p:Units() do if u:GetUnitType()==J.Unit(id,'EMISSARY') then
   any=true;row('Emissary #'..u:GetID()..' '..coord(J.Index(u:GetPlot())),'Locate','LOOK',J.Index(u:GetPlot()))
   for _,minor in ipairs(minors) do if Players[minor]:IsAlive() then
    local ok,why=J.TributeCheck(id,s,u:GetID(),minor)
    row('Establish Tributary: '..Players[minor]:GetName(),'Tributary','TRIBUTARY',u:GetID(),minor,ok,why)
   end end
   local shown={}
   for _,plot in ipairs(J.Near(u:GetPlot(),C.bribeRange)) do
    local enemy=false;for i=0,plot:GetNumUnits()-1 do if J.BribeTarget(id,plot:GetUnit(i)) then enemy=true end end
    if enemy and not shown[J.Index(plot)] then
     shown[J.Index(plot)]=true;local ok,why=J.BribeCheck(id,s,u:GetID(),J.Index(plot))
     row('Bribe enemy group centered '..coord(J.Index(plot)),'Bribe','BRIBE',u:GetID(),J.Index(plot),ok,why)
    end
   end
  end end
  if not any then row('Train an Emissary after completing the second Landmark. Dragon Pavilion grants one free Emissary when capacity and deployment allow.',nil) end
 elseif tab=='Upgrades' then
  for _,up in ipairs(C.upgrades) do
   local legal=not s.upgrades[up.key] and J.Tech(id,up.tech) and p:GetGold()>=J.Scale(up.cost)
   row(up.name..' — '..J.Scale(up.cost)..' Gold; '..(s.upgrades[up.key] and 'researched' or up.help),'Research','UPGRADE',up.key,nil,legal,s.upgrades[up.key] and 'Already researched.' or ('Requires '..Locale.ConvertTextKey(GameInfo.Technologies[up.tech].Description)..'. '..up.help))
  end
 elseif tab=='Defense' then
  for key,r in pairs(emplacements) do
   local state=s.defense[key] or {};local active=0;for _,d in pairs(s.defenders) do if d.parent==key then active=active+1 end end
   row((r.fort and 'Fort ' or 'City ')..coord(r.plot)..' — defenders '..active..' / '..r.capacity..'; ready in '..math.max(0,(state.ready or 0)-J.Now())..' turns.','Locate','LOOK',r.plot)
  end
  for uid,r in pairs(s.defenders) do row('Autonomous defender #'..uid..' — '..(r.mode or 'GUARD')..'; home '..coord(r.plot)..'; expires '..math.max(0,r.expires-J.Now())..' turns; leash '..C.defenderLeash..'.',nil) end
  row('Pagoda Groves '..count(s.groves)..' / '..C.groveMax..'; maximum '..C.grovePerCity..' per city. Next attempt in '..math.max(0,s.groveReady-J.Now())..' turns.',nil)
  if count(emplacements)==0 then row('Complete Dragon Pavilion / Great Wall Bastion, or research Meng\'an Mouke Emplacement.',nil) end
 end
 Controls.Rows:CalculateSize();Controls.Rows:ReprocessAnchoring();Controls.Scroll:CalculateInternalSize()
end
function J.UIRefresh(force)
 if rendering then return end
 rendering=true;local ok,err=pcall(render,force);rendering=false
 if not ok then lastStamp=nil;print('JIN UI refresh: '..tostring(err));pcall(function()Controls.Message:SetText('Jin panel could not refresh; reopen to retry. See Lua.log.')end) end
end
Controls.Open:RegisterCallback(Mouse.eLClick,function()open=not open;J.UIRefresh()end)
Controls.Close:RegisterCallback(Mouse.eLClick,function()open=false;J.UIRefresh()end)
for _,key in ipairs({'Overview','Landmarks','Recruit','Emissaries','Upgrades','Defense'}) do
 local selected=key;Controls[key..'Tab']:RegisterCallback(Mouse.eLClick,function()tab=selected;J.UIRefresh()end)
end
-- Visibility must refresh even while the panel is closed. Gameplay refreshes
-- deliberately skip closed panels and cannot restore a hidden launcher alone.
local function queueVisibility()
 J.Defer('ui',function()J.UIRefresh(false)end)
end
local function resetVisibility()
 ending=false;open=false;J.UIRefresh(false);queueVisibility()
end
J.Hook(Events,'ActivePlayerTurnEnd',function()ending=true;open=false;J.UIRefresh(false)end)
J.Hook(Events,'ActivePlayerTurnStart',resetVisibility)
J.Hook(Events,'GameplaySetActivePlayer',resetVisibility)
J.Hook(Events,'LoadScreenClose',resetVisibility)
J.Hook(Events,'SerialEventGameDataDirty',queueVisibility)
J.Hook(Events,'SerialEventCityInfoDirty',function()if open then J.Refresh(true)end end)
J.Hook(GameEvents,'TeamTechResearched',function(team)if J.IsJin(Game.GetActivePlayer()) and Players[Game.GetActivePlayer()]:GetTeam()==team then J.Refresh(true)end end)
J.UIRefresh()
