local R=MapModData.RED_Legend
-- Role 0 = ATTACKER, 1 = DEFENDER. BattleDamageDelta is called repeatedly;
-- it must be pure with respect to unit state, cooldowns and damage.
local function combatant(pid,id,city)
 local p=Players[pid];if not p then return end
 local u=not city and p:GetUnitByID(id)
 if not u then return {pid=pid,id=id,city=true,base=0} end
 local r=R.IsRed(pid) and R.Record(u)
 return {pid=pid,id=id,unitType=u:GetUnitType(),base=R.Base(u),damage=u:GetDamage(),maxHP=u:GetMaxHitPoints(),serial=r and r.serial,identity=r and r.identity,team=r and r.slot~=nil,rank=r and R.Rank(r),
  strongest=0,cost=math.max(0,p:GetUnitProductionNeeded(u:GetUnitType())),x=u:GetX(),y=u:GetY(),ww={}}
end
function R.BattleStart(kind,x,y)
 R.battle={kind=kind,x=x,y=y,actors={},dead={},delta={}}
end
function R.BattleJoin(pid,id,role,city)
 local b=R.battle;if not b or role>1 then return end
 b.actors[role]=combatant(pid,id,city)
 if role==0 and b.actors[role] and b.actors[role].serial then
  local u=Players[pid]:GetUnitByID(id);local r=R.Peek(u)
  if r and r.quickFortify then r.quickFortify=nil;R.Set(u,'BLASTOISE_FORTIFY',false) end
 end
 local a,d=b.actors[0],b.actors[1]
 if not a or not d then return end
 for _,c in pairs(b.actors) do
  local other=c==a and d or a;local claimant=other.serial and R.State(other.pid).units[other.serial]
  if claimant and claimant.slot and not c.city and not c.strongestCached then
   for v in Players[c.pid]:Units() do if v:IsCombatUnit() and R.Alive(v) then c.strongest=math.max(c.strongest,R.Base(v)) end end
   c.strongestCached=true
  end
 end
 for _,c in pairs(b.actors) do
  local other=c==a and d or a
  if c.serial then local u=Players[c.pid]:GetUnitByID(c.id)
   R.Set(u,'PIKACHU_STRONGER',c.identity=='PIKACHU' and other.base>c.base)
   if c.identity=='SNORLAX' then c.anchor={x=u:GetX(),y=u:GetY()} end
   c.ww[other.pid]=Players[c.pid]:GetWarWeariness(other.pid)
  end
 end
end
function R.DamageDelta(role,base)
 local b=R.battle;if not b or b.kind>2 or role>1 then return 0 end
 local a,d=b.actors[0],b.actors[1];if not a or not d then return 0 end
 -- Lapras damage multiplier, and Blastoise's exact incoming ranged reduction.
 local source=b.actors[role];local target=b.actors[1-role];local amount=base
 b.delta[role]=base
 local victim=not target.city and Players[target.pid]:GetUnitByID(target.id)
 if target.identity=='BLASTOISE' and b.kind~=0 then amount=math.floor(amount*0.75+0.5) end
 -- Pre-combat lethal withdrawal. The legal destination is cached once; no map mutation
 -- or cooldown write occurs in this repeatedly evaluated value callback.
 if b.kind==0 and d.identity=='PIKACHU' and role==0 and amount>=d.maxHP-d.damage then
  local s=R.State(d.pid);local r=s.units[d.serial];local u=Players[d.pid]:GetUnitByID(d.id);local attacker=Players[a.pid]:GetUnitByID(a.id)
  if r and Game.GetGameTurn()>=(r.withdrawReady or 0) and u and attacker then
   local plot=R.EscapePlot(u,attacker)
   if plot then b.escape={serial=d.serial,pid=d.pid,x=plot:GetX(),y=plot:GetY()};amount=0 end
  end
 end
 if b.escape then amount=0 end -- a withdrawal exchanges no blows
 return amount-base
end
function R.CombatResult(ap,au,ad,af,am,dp,du,dd,df,dm,ip,iu,damage,x,y)
 local b=R.battle;if not b then return end
 -- Cache real damage for audit/retreat; neither preview nor getter claims rewards.
 b.actual={attacker=ad,defender=dd,x=x,y=y}
end
function R.KillReward(winner,loser,attacking)
 if not winner or not loser or not winner.serial then return end
 local s=R.State(winner.pid);local u=Players[winner.pid]:GetUnitByID(winner.id)
 if not R.Alive(u) then return end
 local r=R.Record(u);R.AddTraining(u,10,true)
 if attacking and winner.rank==4 then R.Heal(u,10) end
 if r.summit then R.Heal(u,10) end
 if winner.team then
  for _,mate in ipairs(R.Team(s)) do local v=R.Unit(s,mate.serial)
   if v and mate.serial~=r.serial and R.Distance(u,v)<=3 then R.Heal(v,5) end
  end
  local enemy=Players[loser.pid];local key=loser.pid..':'..GameInfo.Units[loser.unitType].Type
  local legacy=loser.pid..':'..loser.unitType
  if enemy and not enemy:IsMinorCiv() and not enemy:IsBarbarian() and loser.base>=loser.strongest and not s.claims[key] and not s.claims[legacy] then
   s.claims[key]=true;R.Save(s)
   local cost=math.max(0,loser.cost or 0)
   Players[s.pid]:ChangeJONSCulture(math.floor(cost*0.5))
   Players[s.pid]:ChangeOverflowResearch(math.floor(cost*0.25))
   R.AddTraining(u,5,true)
  end
 end
 R.Changed(s)
end
function R.FinishCombat()
 local b=R.battle;if not b then return end
 R.battle=nil -- scripted damage below never recursively enters the original reward path
 local a,d=b.actors[0],b.actors[1];if not a or not d then return end
 local function unit(c) return not c.city and Players[c.pid]:GetUnitByID(c.id) end
 local au,du=unit(a),unit(d)
 -- Positive damage deltas in v151 clamp against source HP. Apply Lapras's bonus
 -- once after native damage, using the cached outgoing base, including defence.
 for role,c in pairs(b.actors) do local target=unit(b.actors[1-role]);local u=unit(c)
  if c.identity=='LAPRAS' and R.Alive(u) and R.Alive(target) and not b.escape and (target:GetDomainType()==DomainTypes.DOMAIN_SEA or target:IsEmbarked()) then
   target:ChangeDamage(math.floor((b.delta[role] or 0)*0.25+0.5),c.pid)
  end
 end
 if b.escape and R.Alive(du) then
  local plot=Map.GetPlot(b.escape.x,b.escape.y)
  if plot and du:CanMoveOrAttackInto(plot,0,1) and not plot:IsVisibleEnemyUnit(d.pid) then
   R.internal=R.internal+1;du:SetXY(plot:GetX(),plot:GetY(),0,1,0);du:FinishMoves();R.internal=R.internal-1
   local s=R.State(d.pid);s.units[d.serial].withdrawReady=Game.GetGameTurn()+R.Turns(5);R.Changed(s)
  end
 end
 -- Pikachu's flat full-health bonus is post-combat to avoid CP's positive-delta
 -- clamp against the SOURCE HP (CvGameCoreStructs.cpp); legitimate bonus kills count once.
 if R.Alive(au) and a.identity=='PIKACHU' and d.damage==0 and R.Alive(du) and not b.escape then du:ChangeDamage(10,a.pid) end
 if R.Alive(au) and not d.city and (b.dead[d.pid..':'..d.id] or not R.Alive(du)) then R.KillReward(a,d,true) end
 if R.Alive(du) and not a.city and (b.dead[a.pid..':'..a.id] or not R.Alive(au)) then R.KillReward(d,a,false) end
 for role,c in pairs(b.actors) do local other=b.actors[1-role];local u=unit(c)
  if c.serial and R.Alive(u) then
   if other.base>=c.base*1.15 and other.base>0 and not b.escape then R.AddTraining(u,5,true) end
   local s=R.State(c.pid);local r=s.units[c.serial]
   R.Set(u,'PIKACHU_STRONGER',false)
   if r.summit and c.ww[other.pid] then
    local now=Players[c.pid]:GetWarWeariness(other.pid)
    -- Roll back only the increment caused by THIS battle, never pre-existing weariness.
    if now>c.ww[other.pid] then Players[c.pid]:ChangeWarWeariness(other.pid,c.ww[other.pid]-now) end
   end
   if role==0 and c.identity=='CHARIZARD' and not b.escape then R.Splash(u,b.x,b.y) end
   if role==0 and c.identity=='BLASTOISE' and u:CanFortify(u:GetPlot()) then
    u:SetActivityType(ActivityTypes.ACTIVITY_SLEEP)
    -- CP exposes no SetFortified Lua method. Bridge the normal +20 defence until
    -- native stationary fortification begins; movement/new attacks remove it.
    r.quickFortify=true;R.Set(u,'BLASTOISE_FORTIFY',u:GetFortifyTurns()==0)
   end
   if role==1 and c.identity=='BLASTOISE' and b.kind==0 and R.Alive(au) and not b.escape then au:ChangeDamage(10,c.pid) end
   -- Best-effort positional anchoring after native heavy charge. Never displace allies.
   if c.identity=='SNORLAX' and c.anchor and (u:GetX()~=c.anchor.x or u:GetY()~=c.anchor.y) then
    local plot=Map.GetPlot(c.anchor.x,c.anchor.y)
    if plot and u:CanMoveOrAttackInto(plot,0,1) and not plot:IsVisibleEnemyUnit(c.pid) then R.internal=R.internal+1;u:SetXY(c.anchor.x,c.anchor.y,0,1,0);R.internal=R.internal-1 end
   end
   R.Apply(u,r);r.lastDamage=u:GetDamage();R.Changed(s)
  end
 end
end
