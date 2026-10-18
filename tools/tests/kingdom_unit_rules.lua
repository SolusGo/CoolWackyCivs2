local k=MapModData.CKPrayer;local p=Players[0];local keeper=p.units[1]
-- Model the verified CP eligibility and healing branches for ordinary Keepers.
-- Military units cannot end a move in another player's city, even with open
-- borders. A healRate-only model would invent an unreachable healing defect.
local function eligible(u,plot,moved)
 return not moved and not (plot:GetPlotCity() and plot.owner~=u.owner)
end
local function healingBonus(u,plot,moved)
 if not eligible(u,plot,moved) then return 0 end
 local friendly,neutral=0,0
 for id,on in pairs(u.promotions) do if on then
  local row=GameInfo.UnitPromotions[id]
  friendly=friendly+(row.FriendlyHealChange or 0);neutral=neutral+(row.NeutralHealChange or 0)
 end end
 if plot:GetPlotCity() then return plot.owner==u.owner and friendly or neutral end
 return plot:IsFriendlyTerritory(u.owner) and friendly or neutral
end
assert(healingBonus(keeper,p.cap.plot,false)==5 and healingBonus(keeper,p.cap.plot,true)==0)
local host=Players[2].cap.plot;host.friendly=0;TEST.move(keeper,host)
assert(keeper:IsHasPromotion(k.DEFENDER))
assert(not eligible(keeper,host,false) and healingBonus(keeper,host,false)==0,'military foreign-city destination is illegal')
assert(healingBonus(keeper,host,true)==0,'illegal city must not bypass normal healing eligibility')
host.friendly=nil;Events.SerialEventScoreDirty()
assert(healingBonus(keeper,host,false)==0,'no additional healing in a nonfriendly foreign city')
local field=TEST.plot(8,8,2);field.friendly=0;TEST.move(keeper,field)
assert(healingBonus(keeper,field,false)==5,'friendly noncity must not double the healing bonus')
field.friendly=nil;Events.SerialEventScoreDirty();assert(healingBonus(keeper,field,false)==0)
TEST.move(keeper,p.cap.plot)
local upgraded=TEST.unit(0,GameInfoTypes.UNIT_RIFLEMAN,true);upgraded.promotions[k.STAND]=true
GameEvents.UnitConverted(0,0,keeper.id,upgraded.id,true)
assert(upgraded:IsHasPromotion(k.STAND) and healingBonus(upgraded,p.cap.plot,false)==5)
for i=1,6 do if i>1 then TEST.advance() end;TEST.pray() end
local defense,attack,embarked=0,0,0
for id,on in pairs(upgraded.promotions) do if on then local row=GameInfo.UnitPromotions[id]
 defense=defense+(row.DefenseMod or 0);attack=attack+(row.AttackMod or 0);embarked=embarked+(row.EmbarkDefenseModifier or 0)
end end
assert(defense==30 and embarked==30 and attack==0 and healingBonus(upgraded,p.cap.plot,false)==5)
TEST.advance();assert(not upgraded:IsHasPromotion(k.SHIELD) and upgraded:IsHasPromotion(k.DEFENDER))
local foreign=TEST.unit(1,GameInfoTypes.UNIT_RIFLEMAN,true)
for _,id in ipairs({k.STAND,k.DEFENDER,k.SHIELD}) do foreign.promotions[id]=true end
GameEvents.UnitConverted(0,1,upgraded.id,foreign.id,false)
for _,id in ipairs({k.STAND,k.DEFENDER,k.SHIELD}) do assert(not foreign:IsHasPromotion(id),'AI transfer retained Kingdom effects') end
print('PASS Kingdom native healing/movement eligibility models, upgrade retention, combined defense and AI cleanup')
