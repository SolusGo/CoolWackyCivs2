-- Pure job selection over cached native plot yields. Native reservations remain
-- authoritative; surplus and forced defaults are overlapping, never additive.
local B=MapModData.BoundlessCity
B.Config.RemoteFoodTarget=0
B.Config.RemoteSwitchMargin=1
B.Config.RemoteFoodPasses=5
function B.InvalidatePlan(s,touched)
 local c=B.Cache(s)
 c.candidateHint=true
 if not touched then c.candidateAll=true
 else c.candidateDirty=c.candidateDirty or {};for n in pairs(touched) do c.candidateDirty[n]=true end end
end
local function same(a,b)
 if not a or not b or a.eligible~=b.eligible then return false end
 for i=1,#B.Yields do if a.yields[i]~=b.yields[i] then return false end end
 return true
end
function B.PlannerUpdate(s,city)
 local territory=B.Cache(s).territoryDirty
 local c=B.Ownership(s);local locals=B.LocalPlots(city)
 local full=territory or c.candidateAll or not c.candidates or c.candidateTurn~=B.Now() or (c.force and not c.candidateHint)
 c.candidates=c.candidates or {};local changed=false;local touched={}
 local function update(n)
  local p=Map.GetPlotByIndex(n);local old=c.candidates[n];local row
  if p and p:GetOwner()==s.pid and not p:IsCity() and not locals[n] then
   row={n=n,plot=p,yields=B.PlotYields(p),eligible=B.Eligible(s,p) and true or false}
  end
  if (old or row) and not same(old,row) then changed=true end
  c.candidates[n]=row;touched[n]=true
 end
 if full then
  local old={};for n in pairs(c.candidates) do old[n]=true end
  for n in pairs(c.owned) do update(n);old[n]=nil end
  for n in pairs(old) do update(n) end
  c.candidateTurn=B.Now();B.RefreshEligibility(s,nil,locals)
 else
  for n in pairs(c.candidateDirty or {}) do update(n) end
  if next(touched) then B.RefreshEligibility(s,touched,locals) end
 end
 c.candidateAll=nil;c.candidateDirty={};c.candidateHint=nil
 if changed then c.candidateRevision=(c.candidateRevision or 0)+1;c.topKey=nil;c.viewRevision=(c.viewRevision or 0)+1 end
 return locals
end
local function better(a,b)
 if a.locked~=b.locked then return a.locked end
 if a.rank~=b.rank then return a.rank>b.rank end
 if a.incumbent~=b.incumbent then return a.incumbent end
 return a.n<b.n
end
-- Worst item at the root: only K candidates are retained/sorted, not all land.
local function offer(heap,r,limit)
 if limit<=0 then return end
 local n=#heap
 if n<limit then
  n=n+1;heap[n]=r
  while n>1 do local p=math.floor(n/2);if not better(heap[p],heap[n]) then break end
   heap[p],heap[n]=heap[n],heap[p];n=p
  end
 elseif better(r,heap[1]) then
  heap[1]=r;local i=1
  while i*2<=#heap do local child=i*2
   if child<#heap and better(heap[child],heap[child+1]) then child=child+1 end
   if not better(heap[i],heap[child]) then break end
   heap[i],heap[child]=heap[child],heap[i];i=child
  end
 end
end
function B.JobScore(s,values,bias)
 local score=0
 for i,y in ipairs(B.Yields) do score=score+(values[i] or 0)*((B.Weights[s.priority] or B.Weights.BALANCED)[i]+(y.id==B.ID('YIELD_FOOD') and (bias or 0) or 0)) end
 return score
end
function B.FoodTarget(s)
 return s.foodTarget==nil and B.Config.RemoteFoodTarget or s.foodTarget
end
function B.FoodRate(city)
 return city:FoodDifferenceTimes100()/100
end
function B.FoodDominance(s,city)
 local c=B.Cache(s);local span=1
 for _,r in pairs(c.candidates or {}) do span=math.max(span,math.abs(B.JobScore(s,r.yields,0))) end
 for _,r in pairs(B.LocalPlots(city)) do span=math.max(span,math.abs(B.Score(s,r.plot))) end
 return (span+1)*math.max(1,city:GetPopulation())*4
end
function B.PlanJobs(s,city,bias,previous)
 local c=B.Cache(s);local a,locals=B.Census(s,city);local old=previous or s.assignments
 local labour={};for i,y in ipairs(B.Yields) do labour[i]=B.LabourerYield(city,y.id) end
 local idle=B.JobScore(s,labour,bias)
 local limit=a.maximumRemote
 local key=table.concat({s.mode,s.priority,bias or 0,limit,c.candidateRevision or 0,
  idle,table.concat(B.Keys(old),','),table.concat(B.Keys(s.selected),','),table.concat(B.Keys(s.locks),','),table.concat(B.Keys(s.excluded),',')},';')
 local candidates=c.topKey==key and c.topCandidates
 if not candidates then
  candidates={}
  for n,row in pairs(c.candidates or {}) do
   if row.eligible and not s.excluded[n] and (s.mode~='MANUAL' or s.selected[n]) then
    local score=B.JobScore(s,row.yields,bias)
    local locked=s.mode=='HYBRID' and s.locks[n]==true or false
    if s.mode=='MANUAL' or locked or score>idle then
     offer(candidates,{n=n,plot=row.plot,score=score,locked=locked,incumbent=old[n]~=nil,
      rank=score+(s.mode~='MANUAL' and old[n] and B.Config.RemoteSwitchMargin or 0)},limit)
    end
   end
  end
  table.sort(candidates,better);c.topKey=key;c.topCandidates=candidates
 end
 local worked={};local costsJobs={};local known=0
 for _,r in pairs(locals) do
  if city:IsWorkingPlot(r.plot) and (s.mode=='AUTO' or not city:IsForcedWorkingPlot(r.plot)) then
   local job={index=r.index,plot=r.plot,score=B.JobScore(s,B.PlotYields(r.plot),bias)}
   worked[#worked+1]=job;costsJobs[#costsJobs+1]=job
  end
 end
 -- Keep the opportunity cost of already withdrawn jobs. Otherwise a previously
 -- displaced Farm would become a fictitious free idle citizen on the next pass.
 for n in pairs(c.reservationJobs or {}) do local r=locals[n]
  if r and not city:IsWorkingPlot(r.plot) then
   costsJobs[#costsJobs+1]={index=r.index,score=B.JobScore(s,B.PlotYields(r.plot),bias)};known=known+1
  end
 end
 for i=known+1,(s.withdrawn or 0) do costsJobs[#costsJobs+1]={index=-i,score=idle} end
 table.sort(worked,function(x,y) if x.score~=y.score then return x.score<y.score end;return x.index<y.index end)
 table.sort(costsJobs,function(x,y) if x.score~=y.score then return x.score<y.score end;return x.index<y.index end)
 local costs={[0]=0}
 for i,r in ipairs(costsJobs) do costs[i]=costs[i-1]+r.score-idle end
 local locked=0;for _,r in ipairs(candidates) do if r.locked then locked=locked+1 end end
 local total,retained=0,0;local best=locked>0 and -math.huge or 0;local count=0
 for n,r in ipairs(candidates) do
  total=total+r.score-idle;if old[r.n] then retained=retained+1 end
  -- At the surplus boundary, ALL missing forced reservations must be supplied.
  local withdraw=n>a.surplus and n or 0
  local gain=costs[withdraw] and total-costs[withdraw]
  if gain and (s.mode=='MANUAL' or n>=locked) then
   local value=gain+retained*B.Config.RemoteSwitchMargin
   if s.mode=='MANUAL' or (n==locked and locked>0) or (gain>0 and value>best+.000001) then best=value;count=n end
  end
 end
 local assignments={}
 for i=1,count do local p=candidates[i].plot;assignments[candidates[i].n]={x=p:GetX(),y=p:GetY()} end
 return {assignments=assignments,rows=candidates,count=count,worked=worked,census=a,bias=bias or 0}
end
