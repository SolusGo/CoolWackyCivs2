-- Native ScriptData rolls back WITH the selected save; no sidecar database authority.
local R=MapModData.RED_Legend
function R.Encode(v)
 local t=type(v)
 if t=='nil' then return 'z' elseif t=='boolean' then return v and 't' or 'f'
 elseif t=='number' then return 'n'..v..';' elseif t=='string' then return 's'..#v..':'..v end
 assert(t=='table','Unsupported Red state')
 local keys={};for k in pairs(v) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) if type(a)==type(b) then return a<b end return type(a)<type(b) end)
 local out={'m',#keys,':'};for _,k in ipairs(keys) do out[#out+1]=R.Encode(k);out[#out+1]=R.Encode(v[k]) end
 return table.concat(out)
end
function R.Decode(raw)
 local pos=1
 local function read(depth)
  assert(depth<32 and pos<=#raw,'Invalid Red state')
  local t=raw:sub(pos,pos);pos=pos+1
  if t=='z' then return nil elseif t=='t' then return true elseif t=='f' then return false end
  assert(t=='n' or t=='s' or t=='m')
  local last=assert(raw:find(t=='n' and ';' or ':',pos,true));local n=assert(tonumber(raw:sub(pos,last-1)));pos=last+1
  assert(n==n and math.abs(n)<1e14)
  if t=='n' then return n end
  assert(n>=0 and n==math.floor(n) and n<=#raw)
  if t=='s' then assert(pos+n<=#raw+1);local s=raw:sub(pos,pos+n-1);pos=pos+n;return s end
  local out={};for _=1,n do local k=read(depth+1);assert(type(k)=='string' or type(k)=='number');out[k]=read(depth+1) end
  return out
 end
 local s=read(0);assert(pos==#raw+1 and type(s)=='table');return s
end
function R.Envelope(data,tag,raw)
 local first,last=data:find('|'..tag..':%d+:')
 if first then local n=tonumber(data:sub(first,last):match(':(%d+):'));data=data:sub(1,first-1)..data:sub(last+n+2) end
 return data..'|'..tag..':'..#raw..':'..raw..'|'
end
function R.Save(s)
 if s.invalid then return end
 Players[s.pid]:SetScriptData(R.Envelope(Players[s.pid]:GetScriptData() or '','REDSTATE1',R.Encode(s)))
end
function R.State(pid)
 if R.States[pid] then return R.States[pid] end
 local data=Players[pid]:GetScriptData() or '';local a,b=data:find('|REDSTATE1:%d+:');local s
 if a then
  local n=tonumber(data:sub(a,b):match(':(%d+):'));local ok,v=pcall(R.Decode,data:sub(b+1,b+n))
  if ok and v.version==1 and v.pid==pid and type(v.units)=='table' and type(v.slots)=='table'
   and type(v.claims)=='table' and type(v.capitals)=='table' and type(v.silver)=='table'
   and data:sub(b+n+1,b+n+1)=='|' then s=v
  else error('[Red] Refusing to overwrite incompatible/corrupt save for player '..pid) end
 elseif data:find('|REDSTATE',1,true) then error('[Red] Invalid save envelope for '..pid)
 else s={version=1,pid=pid,nextSerial=1,units={},slots={},claims={},capitals={},hall=0,full=false,lastTurn=-1,lastDone=-1,airlifts={},silver={phase='READY',snapshots={}},identities={}} end
 R.States[pid]=s;return s
end
function R.Tag(u,serial)
 local data=(u:GetScriptData() or ''):gsub('|REDSID:%d+:%d+|','')
 u:SetScriptData(data..'|REDSID:'..u:GetOwner()..':'..serial..'|')
end
function R.Serial(u)
 if not u then return end
 local owner,serial=(u:GetScriptData() or ''):match('|REDSID:(%d+):(%d+)|')
 if tonumber(owner)==u:GetOwner() then return tonumber(serial) end
end
function R.Record(u)
 if not u or not R.Alive(u) or not R.IsRed(u:GetOwner()) or not R.Eligible(u) then return end
 local s=R.State(u:GetOwner());local n=R.Serial(u);local r=n and s.units[n]
 if r and r.id and r.id~=u:GetID() then
  local original=Players[s.pid]:GetUnitByID(r.id)
  if original and R.Serial(original)==n and not original:IsDead() then n=nil;r=nil end
 end
 if r and r.dead then
  -- A resurrected/copied native unit may not impersonate a destroyed veteran.
  n=nil;r=nil
 end
 if not r then
  n=s.nextSerial;s.nextSerial=n+1;r={serial=n,training=0,ribbons=0,lineage={},born=Game.GetGameTurn(),itemReady=0,withdrawReady=0,lastDamage=u:GetDamage()}
  s.units[n]=r;R.Tag(u,n)
 end
 r.id=u:GetID();r.unitType=GameInfo.Units[u:GetUnitType()].Type
 R.Index[s.pid]=R.Index[s.pid] or {};R.Index[s.pid][n]=u:GetID()
 return r,s
end
function R.Unit(s,serial)
 local r=s.units[serial];if not r or r.dead or r.withdrawn then return end
 local u=Players[s.pid]:GetUnitByID(r.id or -1)
 if u and R.Serial(u)==serial and not u:IsDead() and not u:IsDelayedDeath() then return u end
end
function R.Peek(u)
 local s=u and R.States[u:GetOwner()];local serial=u and R.Serial(u)
 return s and serial and s.units[serial]
end
function R.Snapshot(u)
 local promotions,expiry={},{}
 for p in GameInfo.UnitPromotions() do if u:IsHasPromotion(p.ID) then
  promotions[#promotions+1]=p.Type
  local duration=u:GetPromotionDuration(p.ID)
  if duration and duration>0 then expiry[p.Type]=u:GetTurnPromotionGained(p.ID)+duration end
 end end
 return {unitType=GameInfo.Units[u:GetUnitType()].Type,name=u:GetNameNoDesc(),xp=u:GetExperienceTimes100(),level=u:GetLevel(),damage=u:GetDamage(),maxHP=u:GetMaxHitPoints(),promotions=promotions,
  promotionExpiry=expiry,leader=u:GetLeaderUnitType(),religion=u:GetReligion(),promotionReady=u:IsPromotionReady(),
  script=u:GetScriptData(),original=u:GetOriginalOwner(),moves=u:MovesLeft(),madeAttack=R.Attacked(u),activity=u:GetActivityType(),facing=u:GetFacingDirection(),baseHP=u:GetMaxHitPointsBase(),
  x=u:GetX(),y=u:GetY(),unitAI=u:GetUnitAIType(),embarked=u:IsEmbarked()}
end
function R.Restore(u,snap)
 local expiry={}
 u:SetExperienceTimes100(snap.xp or 0);u:SetLevel(snap.level or 1)
 if snap.baseHP then u:SetMaxHitPointsBase(snap.baseHP) end
 for _,typ in ipairs(snap.promotions or {}) do
  local id=GameInfoTypes[typ];local expires=snap.promotionExpiry and snap.promotionExpiry[typ]
  if id and (not expires or expires>Game.GetGameTurn()) and typ~='PROMOTION_RED_BLOOM_STATUS' and typ~='PROMOTION_RED_HORIZON' and typ~='PROMOTION_RED_PIKACHU_STRONGER' then
   u:SetHasPromotion(id,true);if expires then expiry[typ]=expires end
  end
 end
 if snap.name and snap.name~='' then u:SetName(snap.name) end
 u:SetOriginalOwner(snap.original or u:GetOwner());u:SetScriptData(snap.script or '')
 if snap.leader and snap.leader>=0 then u:SetLeaderUnitType(snap.leader) end
 if snap.religion and snap.religion>=0 then u:SetReligion(snap.religion) end
 if snap.promotionReady~=nil then u:SetPromotionReady(snap.promotionReady) end
 u:SetDamage(math.min(snap.damage or 0,u:GetMaxHitPoints()-1));u:SetMoves(0)
 return expiry
end
