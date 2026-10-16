local R=MapModData.RED_Legend;TEST.flush();local s=R.State(0)
s.full=true;s.manual=true;Players[0].era=GameInfoTypes.ERA_MODERN
local party={}
for i,typ in ipairs({'UNIT_WARRIOR','UNIT_ARCHER','UNIT_SPEARMAN','UNIT_HORSEMAN'}) do
 local u=TEST.new(typ,2+i,3);local r=R.Record(u);r.training=100;assert(R.Assign(s,u,i));party[#party+1]=u
end
TEST.flush();assert(#R.Team(s)==4 and R.SilverEligible(s))
local ace=TEST.new('UNIT_RED_POKEMON_ACE',3,3);TEST.flush();assert(R.Attach(s,party[1]))
assert(R.BeginSilver(s));local due=s.silver.due
-- Lose the original capital while away. Return uses a surviving friendly city.
local refuge=TEST.city(0,2,8);Players[0].cities={refuge};TEST.cap.pid=1;TEST.cap:Plot().owner=1
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).blocked=true end
TEST.turn=due;s=TEST.reload();R.ResumeSilver(s)
assert(s.silver.phase=='RETURNING','blocked plots retain recoverable snapshots')
for _,r in ipairs(R.Team(s)) do assert(r.withdrawn) end
local notifications=Players[0].notifications
-- Free a single tile: only one partner returns, then survives another reload.
Map.GetPlot(2,8).blocked=false;R.ResumeSilver(s)
local returned=0;for _,r in ipairs(R.Team(s)) do if R.Unit(s,r.serial) then returned=returned+1 end end
assert(returned==1 and s.silver.phase=='RETURNING')
s=TEST.reload();R.ResumeSilver(s)
local twice=0;for _,r in ipairs(R.Team(s)) do if R.Unit(s,r.serial) then twice=twice+1 end end;assert(twice==1,'partial return cannot duplicate')
for _,xy in ipairs({{2,7},{3,7},{3,8}}) do Map.GetPlot(xy[1],xy[2]).blocked=false end
R.ResumeSilver(s);assert(s.silver.phase=='RETURNED' and #R.Team(s)==4 and Players[0].notifications==notifications+1)
local used=0;for name in pairs(s.identities) do used=used+1 end;assert(used==4,'four partners never conjure two replacement units')
for _,r in ipairs(R.Team(s)) do assert(r.summit and r.ribbons==0 and R.Unit(s,r.serial)) end
-- Host death rescues exactly one Ace without resurrecting a military partner.
local host
for _,r in ipairs(R.Team(s)) do if r.ace then host=R.Unit(s,r.serial) end end
assert(host);host:Kill(false,1);TEST.flush();local aces=0
for u in Players[0]:Units() do if u.typ==R.ACE then aces=aces+1 end end
assert(aces==1 and #R.Team(s)==3)
-- Center starting Training, capped passive gain, once-per-turn extra healing.
local city=refuge;city:SetNumRealBuilding(R.CENTER,1)
local trainee=TEST.new('UNIT_WARRIOR',2,8);TEST.flush();GameEvents.CityTrained(0,city.id,trainee.id,false,false)
local tr=R.Peek(trainee);assert(tr.training==15);GameEvents.CityTrained(0,city.id,trainee.id,false,false);assert(tr.training==15)
tr.training=65;assert(R.Assign(s,trainee,1) or tr.slot)
tr.training=64;R.Passive(s,false);assert(tr.training==65,'Center cannot train Legendary')
tr.training=35;trainee.damage=80;tr.lastDamage=80
trainee:SetDamage(70);assert(trainee.damage==50,'native heal +5 Proven +15 Center')
trainee:SetDamage(40);assert(trainee.damage==35,'Center only once per turn; Proven each heal')
-- Real combat flags prevent post-attack item use even with extra attacks remaining.
local centerAce=TEST.new('UNIT_RED_POKEMON_ACE',2,8);TEST.flush();assert(R.Attach(s,trainee))
tr.attackTurn=TEST.turn;assert(not R.CanItem(s,trainee))
-- AI can schedule essential infrastructure and the project without a panel.
Players[0].human=false;Players[0].cities={city};city.project=nil;city.building=nil
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).blocked=false end
s.silver={phase='READY',snapshots={}};s.manual=false;s.full=true
for i=1,4 do
 if not s.slots[i] then local u=TEST.new('UNIT_ARCHER',4+i,2);local r=R.Record(u);r.training=100;R.Assign(s,u,i) end
end
assert(R.SilverEligible(s));R.AITurn(s);assert(city.project==R.PROJECT,'AI explicitly queues Mt. Silver')
assert(R.BeginSilver(s));Players[0].eliminated=true;TEST.turn=TEST.turn+8;R.ResumeSilver(s);assert(s.silver.phase=='ELIMINATED')
local live=0;for u in Players[0]:Units() do if u:IsCombatUnit() then live=live+1 end end
R.ResumeSilver(s);local after=0;for u in Players[0]:Units() do if u:IsCombatUnit() then after=after+1 end end;assert(live==after,'eliminated Red never revived')
print('PASS Red edge cases: four-member journey, capital loss, blocked/partial return, reload, trainer rescue, Center cap/healing and AI project/elimination')
