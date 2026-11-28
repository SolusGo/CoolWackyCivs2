-- Presentation data derived from the capital location and current ownership.
local B=MapModData.BoundlessCity
local compass={'EAST','NORTHEAST','NORTH','NORTHWEST','WEST','SOUTHWEST','SOUTH','SOUTHEAST'}
local wardOrder={'CENTRAL','NORTH','NORTHEAST','EAST','SOUTHEAST','SOUTH','SOUTHWEST','WEST','NORTHWEST'}

function B.AtlasWardName(ward)
 local key='ATLAS_WARD_'..ward
 return B.Text(key)
end

local function relativeDelta(value,span,wrap)
 if wrap and math.abs(value)>span/2 then return value>0 and value-span or value+span end
 return value
end

local function location(capital,plot,width,height,wrapX,wrapY)
 local x,y=plot:GetX(),plot:GetY()
 local distance=Map.PlotDistance(capital.x,capital.y,x,y)
 if distance==0 then return 'CENTRAL','CENTRAL',0 end
 local dy=relativeDelta(y-capital.y,height,wrapY)
 local dx=relativeDelta(x-capital.x,width,wrapX)+(y%2-capital.y%2)/2
 local octant=math.floor(math.atan2(dy*math.sqrt(3)/2,dx)/(math.pi/4)+.5)%8
 local direction=compass[octant+1]
 return distance<=3 and 'CENTRAL' or direction,direction,distance
end

function B.AtlasPlotName(s,plot)
 local city=plot:GetPlotCity()
 if city then return city:GetName() end
 local feature=GameInfo.Features[plot:GetFeatureType()]
 local terrain=GameInfo.Terrains[plot:GetTerrainType()]
 local resource=GameInfo.Resources[plot:GetResourceType(Players[s.pid]:GetTeam())]
 local name=feature or terrain
 local description=name and Locale.ConvertTextKey(name.Description) or B.Text('ATLAS_TILE')
 return resource and B.Text('ATLAS_RESOURCE',description,Locale.ConvertTextKey(resource.Description)) or description
end

function B.NotifyExpansion(s,plot)
 local player=Players[s.pid]
 if not player:IsHuman() then return end
 local cache=B.Cache(s);local turn=B.Now();local n=plot:GetPlotIndex()
 if cache.expansionTurn~=turn then cache.expansionTurn=turn;cache.expansionNotices={} end
 if cache.expansionNotices[n] then return end
 -- Presentation failure must never interrupt the claim or the following save.
 local ok,err=pcall(function()
  local width,height=Map.GetGridSize()
  local ward,direction,distance=location(s.capital,plot,width,height,Map.IsWrapX(),Map.IsWrapY())
  local name=B.AtlasPlotName(s,plot)
  local x,y=plot:GetX(),plot:GetY()
  player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
   B.Text('EXPANSION_NOTICE',name,x,y,distance,B.Text(direction),B.AtlasWardName(ward)),
   B.Text('EXPANSION_TITLE',x,y),x,y)
 end)
 if ok then cache.expansionNotices[n]=true
 else print('[BoundlessCity] Expansion notification failed: '..tostring(err)) end
end

function B.Atlas(s)
 local cache=B.Ownership(s)
 local revision=cache.viewRevision or 0
 local prior=cache.atlas
 if prior and prior.connected==cache.connected and prior.count==cache.count
  and prior.revision==revision and prior.assignments==s.assignments then return prior end
 local view={wards={},byName={},count=cache.count,connected=cache.connected,revision=revision,assignments=s.assignments,workers=0}
 local width,height=Map.GetGridSize();local wrapX,wrapY=Map.IsWrapX(),Map.IsWrapY()
 for n in pairs(cache.owned) do
  local plot=Map.GetPlotByIndex(n)
  if plot and plot:GetOwner()==s.pid then
   local key,_,distance=location(s.capital,plot,width,height,wrapX,wrapY)
   local ward=view.byName[key]
   if not ward then
    ward={key=key,plots={},workers=0,yields={}}
    view.byName[key]=ward
   end
   local credit=s.assignments[n] and cache.perPlot and cache.perPlot[n]
   local row={n=n,distance=distance,credit=credit}
   ward.plots[#ward.plots+1]=row
   local marker=ward.marker
   if not marker or distance<marker.distance or (distance==marker.distance and n<marker.n) then ward.marker=row end
   if credit then
    ward.workers=ward.workers+1;view.workers=view.workers+1
    for i=1,#B.Yields do ward.yields[i]=(ward.yields[i] or 0)+(credit[i] or 0) end
   end
  end
 end
 for _,key in ipairs(wardOrder) do
  local ward=view.byName[key]
  if ward then
   table.sort(ward.plots,function(a,b)
    if (a.credit~=nil)~=(b.credit~=nil) then return a.credit~=nil end
    if a.distance~=b.distance then return a.distance<b.distance end
    return a.n<b.n
   end)
   view.wards[#view.wards+1]=ward
  end
 end
 cache.atlas=view
 return view
end
