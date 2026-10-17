local k=MapModData.CKPrayer;local p=Players[0];local s=k.states[0];s.grace=7;k.Save(s);TEST.pray()
local old=p.cap;local new=p.cities[2];p.cap=new;GameEvents.CapitalChanged(0,new.id,old.id)
assert(old:bonus('YIELD_FAITH')==0 and old:bonus('YIELD_CULTURE')==0)
assert(new:bonus('YIELD_FAITH')==9 and new:bonus('YIELD_CULTURE')==7 and new:bonus('YIELD_FOOD')==1)
-- Ownership transfer with deliberately retained dummies exercises immediate cleanup.
table.remove(p.cities,2);Players[2].cities[#Players[2].cities+1]=new;new.plot.owner=2;p.cap=old
GameEvents.CityCaptureComplete(0,true,new.plot.x,new.plot.y,2)
assert(new:bonus('YIELD_CULTURE')==0 and new:bonus('YIELD_FAITH')==0)
assert(old:bonus('YIELD_CULTURE')==7 and old:bonus('YIELD_FAITH')==9)
table.remove(Players[2].cities,#Players[2].cities);p.cities[#p.cities+1]=new;new.plot.owner=0
GameEvents.CityCaptureComplete(2,false,new.plot.x,new.plot.y,0)
assert(new:bonus('YIELD_CULTURE')==0,'recaptured noncapital must not duplicate Grace')
local u=p.units[1];assert(u:IsHasPromotion(k.STAND) and u:IsHasPromotion(k.DEFENDER))
TEST.move(u,TEST.plot(8,8,-1));assert(u:IsHasPromotion(k.STAND) and not u:IsHasPromotion(k.DEFENDER))
u.plot.owner=0;GameEvents.TileOwnershipChanged(8,8,0,-1);assert(u:IsHasPromotion(k.DEFENDER))
u.plot.owner=2;GameEvents.TileOwnershipChanged(8,8,2,0);assert(not u:IsHasPromotion(k.DEFENDER))
u.plot.friendly=0;Events.WarStateChanged();assert(u:IsHasPromotion(k.DEFENDER))
u.plot.friendly=nil;Events.SerialEventScoreDirty();assert(not u:IsHasPromotion(k.DEFENDER),'open borders expired')
u.plot.friendly=0;Events.LeavingLeaderViewMode();assert(u:IsHasPromotion(k.DEFENDER),'open borders granted')
u.plot.friendly=nil;GameEvents.MinorFriendsChanged();assert(not u:IsHasPromotion(k.DEFENDER),'minor access changed')
u.plot.friendly=0;GameEvents.MinorAlliesChanged();assert(u:IsHasPromotion(k.DEFENDER))
-- Retain native LostWithUpgrade=0 identity, recreate conditional defense.
local upgraded=TEST.unit(0,GameInfoTypes.UNIT_RIFLEMAN,true);upgraded.promotions[k.STAND]=true
GameEvents.UnitConverted(0,0,u.id,upgraded.id,true);assert(upgraded:IsHasPromotion(k.STAND) and upgraded:IsHasPromotion(k.DEFENDER))
local foreign=TEST.unit(2,GameInfoTypes.UNIT_RIFLEMAN,true);foreign.promotions[k.STAND]=true;foreign.promotions[k.DEFENDER]=true;foreign.promotions[k.SHIELD]=true
GameEvents.UnitConverted(0,2,upgraded.id,foreign.id,false)
assert(not foreign:IsHasPromotion(k.STAND) and not foreign:IsHasPromotion(k.DEFENDER) and not foreign:IsHasPromotion(k.SHIELD))
for i=2,6 do TEST.advance();TEST.pray() end
assert(upgraded:IsHasPromotion(k.SHIELD) and upgraded:IsHasPromotion(k.DEFENDER))
local defender=GameInfo.UnitPromotions[k.DEFENDER];local shield=GameInfo.UnitPromotions[k.SHIELD]
assert(defender.DefenseMod+shield.DefenseMod==30 and defender.AttackMod==0 and shield.AttackMod==0)
assert(defender.EmbarkDefenseModifier+shield.EmbarkDefenseModifier==30,'native embarked defense has its own path')
TEST.move(upgraded,TEST.plot(9,9,-1));assert(not upgraded:IsHasPromotion(k.DEFENDER) and not upgraded:IsHasPromotion(k.SHIELD))
TEST.move(upgraded,old.plot);TEST.advance();assert(upgraded:IsHasPromotion(k.DEFENDER) and not upgraded:IsHasPromotion(k.SHIELD))
-- AI-forced identity and foreign humans cannot activate, acquire progress, or retain bonuses.
assert(not k.Pray(1,1,0) and not k.Pray(2,1,0) and not Players[1].units[1]:IsHasPromotion(k.STAND))
p.human=false;GameEvents.PlayerDoTurn(0);k.Sync(0,true);assert(not u:IsHasPromotion(k.STAND) and old:bonus('YIELD_FAITH')==0)
p.human=true;p.alive=false;p.cap=nil;k.Sync(0,true);assert(not k.CanPray(0))
p.alive=true;p.cap=old;TEST.network=true;assert(not k.CanPray(0));TEST.network=false;TEST.hotseat=true;assert(not k.CanPray(0))
print('PASS Kingdom capital loss/transfer/recapture, unit territory/upgrade/gift, separate defense, AI and elimination')
