local R=MapModData.RED_Legend;TEST.flush();local s=R.State(0);s.full=true;s.manual=true
local party={}
for i,name in ipairs(R.Names) do
 local typ=(name=='CHARIZARD' or name=='LAPRAS') and 'UNIT_ARCHER' or 'UNIT_WARRIOR'
 local u=TEST.new(typ,i+1,3);local r=R.Record(u);r.training=100;r.summit=true;assert(R.Assign(s,u,i));r.identity=name;R.Apply(u,r);party[name]=u
end
TEST.flush()
local function begin(a,d,kind)
 GameEvents.BattleStarted(kind or 0,d.x,d.y);GameEvents.BattleJoined(a.pid,a.id,0,false);GameEvents.BattleJoined(d.pid,d.id,1,false)
end
local pikachu=party.PIKACHU;local pr=R.Peek(pikachu)
assert(pikachu:MaxMoves()==240,'Pikachu +2 Movement')
local strong=TEST.new('UNIT_RIFLEMAN',9,3,1)
begin(pikachu,strong);assert(pikachu:IsHasPromotion(R.Promo('PIKACHU_STRONGER')));strong.damage=20;GameEvents.CombatEnded();assert(strong.damage==30,'full-health bonus is cached before native damage')
assert(not pikachu:IsHasPromotion(R.Promo('PIKACHU_STRONGER')))
-- Escape is unavailable without a legal neighboring tile.
for direction=0,5 do local p=Map.PlotDirection(pikachu.x,pikachu.y,direction);if p then p.blocked=true end end
pikachu.damage=100;begin(strong,pikachu);assert(GameEvents.BattleDamageDelta(0,30)==0,'no invalid withdrawal');GameEvents.CombatEnded()
for i=0,Map.GetNumPlots()-1 do Map.GetPlotByIndex(i).blocked=false end
local charizard=party.CHARIZARD
assert(charizard:Range()==GameInfo.Units[charizard.typ].Range+1)
local range
for p in GameInfo.UnitPromotions() do if p.Type~='PROMOTION_RED_RANGE' and p.RangeChange==1 then range=p.ID;break end end
assert(range);charizard:SetHasPromotion(range,true);R.Apply(charizard,R.Peek(charizard));assert(not charizard:IsHasPromotion(R.Promo('RANGE')),'no doubled range')
charizard:SetHasPromotion(range,false);R.Apply(charizard,R.Peek(charizard));assert(charizard:IsHasPromotion(R.Promo('RANGE')))
local target=TEST.new('UNIT_WARRIOR',9,5,1);local neighbor=TEST.new('UNIT_WARRIOR',9,4,1);local friendly=TEST.new('UNIT_WARRIOR',8,5)
begin(charizard,target,1);local n=neighbor.damage;GameEvents.CombatEnded();assert(neighbor.damage==n+5 and friendly.damage==0,'splash only hits adjacent enemies')
local blastoise=party.BLASTOISE;local foe=TEST.new('UNIT_WARRIOR',8,4,1)
begin(foe,blastoise,0);n=foe.damage;GameEvents.CombatEnded();assert(foe.damage==n+10,'melee retaliation')
begin(blastoise,foe,0);GameEvents.CombatEnded();assert(R.Peek(blastoise).quickFortify and blastoise:IsHasPromotion(R.Promo('BLASTOISE_FORTIFY')),'immediate fortification bridge')
blastoise.fortified=true;R.Apply(blastoise,R.Peek(blastoise));assert(not blastoise:IsHasPromotion(R.Promo('BLASTOISE_FORTIFY')),'no double fortify defence')
local venusaur=party.VENUSAUR;friendly:SetXY(venusaur.x,venusaur.y+1);friendly.damage=40
R.PartnerAura(0);assert(friendly.damage==30,'Venusaur heals adjacent friend 10')
foe:SetXY(venusaur.x+1,venusaur.y);R.PartnerAura(1);assert(foe:IsHasPromotion(R.Promo('BLOOM_STATUS')))
foe:SetXY(10,8);R.PartnerAura(1);assert(not foe:IsHasPromotion(R.Promo('BLOOM_STATUS')),'Bloom status expires next enemy turn')
local snorlax=party.SNORLAX;snorlax.fortified=true;snorlax.damage=50;R.Passive(s,false);assert(snorlax.damage==35 and snorlax:MaxMoves()==60)
foe.x=snorlax.x+1;foe.y=snorlax.y;R.positions[foe.pid..':'..foe.id]={x=foe.x,y=foe.y};foe.moves=120;foe:SetXY(snorlax.x,snorlax.y+1);assert(foe.moves==0,'Snorlax ZOC ignores ordinary immunity')
local lapras=party.LAPRAS;friendly.embarked=true;friendly:SetXY(lapras.x,lapras.y+1);R.LaprasAuraFor(friendly);assert(friendly:IsHasPromotion(R.Promo('HORIZON')))
friendly:SetXY(0,9);assert(not friendly:IsHasPromotion(R.Promo('HORIZON')),'Lapras aura cleans on movement')
local naval=TEST.new('UNIT_TRIREME',10,4,1);Map.GetPlot(10,4).water=true
begin(lapras,naval,1);assert(GameEvents.BattleDamageDelta(0,40)==0,'no unsafe positive CP delta');naval.damage=40;GameEvents.CombatEnded();assert(naval.damage==50,'Lapras +25% outgoing damage')
-- One explicit airlift departure per source city. Native action remains disabled outside query.
TEST.turn=20;local from=TEST.cap;local dest=TEST.city(0,1,8);from:SetNumRealBuilding(R.CENTER,1);dest:SetNumRealBuilding(R.CENTER,1)
local air=TEST.new('UNIT_WARRIOR',from.x,from.y);TEST.flush();assert(not GameEvents.CityCanAirlift(0,from.id),'no unlimited native bypass')
assert(R.Airlift(s,air,dest));assert(air.x==dest.x and air.moves==0)
local second=TEST.new('UNIT_WARRIOR',from.x,from.y);TEST.flush();assert(not R.Airlift(s,second,dest),'source city allowance')
-- Becoming a Champion from this kill does not retroactively make it a team kill.
charizard:Kill(false,1);local newcomer=TEST.new('UNIT_WARRIOR',2,6);local nr=R.Record(newcomer);nr.training=60;s.manual=false
local easy=TEST.new('UNIT_WARRIOR',3,6,1);local oldCulture=Players[0].culture
begin(newcomer,easy);easy:Kill(false,0);GameEvents.CombatEnded()
assert(nr.training==70 and nr.slot and Players[0].culture==oldCulture,'pre-combat membership gates Momentum')
-- Obsolete, untrainable intermediate types must not block the available endpoint.
local canTrain=Players[0].CanTrain
Players[0].CanTrain=function(self,id)return GameInfo.Units[id].Type=='UNIT_MECHANIZED_INFANTRY' end
assert(R.AdvancedType(0,'UNIT_WARRIOR')=='UNIT_MECHANIZED_INFANTRY','free upgrade traverses obsolete intermediates')
Players[0].CanTrain=canTrain
print('PASS Red abilities: six identity effects, nonstacking Range, legal escape, splash/retaliation, fortification, auras, Snorlax ZOC and constrained airlift')
