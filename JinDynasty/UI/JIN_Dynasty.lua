include('InstanceManager')
include('JIN_Core')
local J=MapModData.JIN
local C=J.C
local manager=InstanceManager:new('JIN_Row','Root',Controls.Rows)
local tab='Overview';local open=false;local rendering=false
local function loc(key) return Locale.ConvertTextKey('TXT_KEY_JIN_'..key) end
local function coord(index) local p=J.Plot(index);return p and ('('..p:GetX()..','..p:GetY()..')') or '(lost)' end
local function count(t)local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function row(label,button,kind,a,b,enabled,why)
 local instance=manager:GetInstance();instance.Text:SetText(label)
 instance.Root:SetToolTipString(why or label)
 instance.Action:SetHide(not button)
 if button then
  instance.Action:SetText(button);instance.Action:SetDisabled(enabled==false);instance.Action:SetToolTipString(why or label)
  local id=Game.GetActivePlayer();local s=J.State(id);local serial=s and s.serial
  instance.Action:RegisterCallback(Mouse.eLClick,function()
   if kind=='LOOK' then local p=J.Plot(a);if p then UI.LookAt(p,0) end;return end
   local ok,message=J.Action(id,serial,kind,a,b)
   Controls.Message:SetText(message or (ok and 'Done.' or 'Action unavailable.'));J.UIRefresh()
  end)
 end
end
function J.UIRefresh()
 if rendering then return end
 rendering=true
 local id=Game.GetActivePlayer();local visible=J.IsJin(id)
 Controls.Open:SetHide(not visible);Controls.Panel:SetHide(not visible or not open)
 if not visible or not open then rendering=false;return end
 local s=J.State(id);manager:ResetInstances()
 if not s then row('Jin save state is unavailable. Check Lua.log; no rewards will be reset.',nil);rendering=false;return end
 J.Complete(id,s)
 local p=Players[id];local horses,capacity=J.Horses(id,s);local trib=J.Tributaries(id,s)
 local emplacements=J.Emplacements(id,s)
 Controls.Overview:SetText(string.format('HORSES %d / %d    |    Cavalry maximum HP: melee +%d / ranged +%d[NEWLINE]TRIBUTARIES %d    |    Outgoing international income +%d%%    |    Mounted Villagers %d / %d    |    Emissaries %d / %d[NEWLINE]LANDMARKS %d / 3    |    EMPLACEMENTS %d    |    KARMA %d / %d    |    BLESSING %d turns',horses,capacity,horses*C.meleeHP,horses*C.rangedHP,trib,trib>0 and C.tradePercent or 0,J.Count(id,'MOUNTED_VILLAGER'),C.villagerCap+C.tributaryVillagers*trib,J.Count(id,'EMISSARY'),C.emissaryCap,J.Tier(s),count(emplacements),s.karma,C.karmaMax,math.max(0,s.blessing-J.Now())))
 if tab=='Overview' then
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
   for unit in GameInfo.Units() do
    if (J.Flag(unit.IsMounted) or unit.CombatClass=='UNITCOMBAT_MOUNTED') and unit.Cost>0 then
     local class=GameInfo.UnitClasses[unit.Class];local override
     for r in GameInfo.Civilization_UnitClassOverrides{CivilizationType='CIVILIZATION_JIN_DYNASTY',UnitClassType=unit.Class} do override=r.UnitType end
     if (override and override==unit.Type) or (not override and class and class.DefaultUnit==unit.Type) then
      local legal,why=J.RecruitCheck(id,s,c:GetID(),unit.ID)
      row(Locale.ConvertTextKey(unit.Description)..' in '..c:GetName(),'Recruit','RECRUIT',c:GetID(),unit.ID,legal,why)
     end
    end
   end
  end
 elseif tab=='Emissaries' then
  for minor,r in pairs(s.trib) do row('Tributary: '..Players[minor]:GetName()..' '..coord(r.plot)..' — +2 capital Food, +3 Villager cap.','Locate','LOOK',r.plot) end
  local any=false
  for u in p:Units() do if u:GetUnitType()==J.Unit(id,'EMISSARY') then
   any=true;row('Emissary #'..u:GetID()..' '..coord(J.Index(u:GetPlot())),'Locate','LOOK',J.Index(u:GetPlot()))
   for minor=0,(GameDefines.MAX_CIV_PLAYERS or 64)-1 do if Players[minor] and Players[minor]:IsMinorCiv() and Players[minor]:IsAlive() then
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
  for uid,r in pairs(s.defenders) do row('Defender #'..uid..' — home '..coord(r.plot)..'; expires in '..math.max(0,r.expires-J.Now())..' turns; leash '..C.defenderLeash..' plots.',nil) end
  row('Pagoda Groves '..count(s.groves)..' / '..C.groveMax..'; maximum '..C.grovePerCity..' per city. Next attempt in '..math.max(0,s.groveReady-J.Now())..' turns.',nil)
  if count(emplacements)==0 then row('Complete Dragon Pavilion / Great Wall Bastion, or research Meng\'an Mouke Emplacement.',nil) end
 end
 Controls.Rows:CalculateSize();Controls.Rows:ReprocessAnchoring();Controls.Scroll:CalculateInternalSize()
 rendering=false
end
Controls.Open:RegisterCallback(Mouse.eLClick,function()open=not open;J.UIRefresh()end)
Controls.Close:RegisterCallback(Mouse.eLClick,function()open=false;J.UIRefresh()end)
for _,key in ipairs({'Overview','Landmarks','Recruit','Emissaries','Upgrades','Defense'}) do
 local selected=key;Controls[key..'Tab']:RegisterCallback(Mouse.eLClick,function()tab=selected;J.UIRefresh()end)
end
J.Hook(Events,'GameplaySetActivePlayer',function()open=false;J.UIRefresh()end)
J.Hook(Events,'SerialEventGameDataDirty',function()if open then J.UIRefresh()end end)
J.Hook(Events,'SerialEventCityInfoDirty',function()if open then J.UIRefresh()end end)
J.UIRefresh()
