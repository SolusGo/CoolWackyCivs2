-- Sole simulation owner: included only by CK_Prayer.xml's Lua context.
MapModData.CKPrayer={states={},failed={},syncing={},busy={},abroad={}}
local K=MapModData.CKPrayer
K.CIV=GameInfoTypes.CIVILIZATION_CK_KINGDOM
K.KEEPER=GameInfoTypes.UNIT_CK_KEEPER
K.HOUSE=GameInfoTypes.BUILDING_CK_HOUSE
K.STAND=GameInfoTypes.PROMOTION_CK_STAND
K.DEFENDER=GameInfoTypes.PROMOTION_CK_DEFENDER
K.SHIELD=GameInfoTypes.PROMOTION_CK_SHIELD
K.REPENT=GameInfoTypes.POLICY_CK_REPENT
K.PROTECTION=GameInfoTypes.POLICY_CK_PROTECTION
K.buildings={'ADDRESS','SEEK','HOUSE_BONUS','GRACE_0','GRACE_1','GRACE_2'}
function K.Turn() return Game.GetGameTurn() end
function K.Duration()
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
 return math.max(1,math.floor(5*(speed and speed.TrainPercent or 100)/100+0.5))
end
function K.Human(pid)
 local p=Players[pid]
 return p and p:IsHuman() and p:GetCivilizationType()==K.CIV and not Game.IsNetworkMultiPlayer() and not Game.IsHotSeat()
end
function K.Alive(pid) return K.Human(pid) and Players[pid]:IsAlive() end
function K.Text(key,...) return Locale.ConvertTextKey('TXT_KEY_CK_'..key,...) end
function K.Hook(events,name,fn) if events[name] and events[name].Add then events[name].Add(fn) end end
function K.Notify(pid,text)
 if K.Alive(pid) then Players[pid]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,text,K.Text('TRAIT'),-1,-1) end
end
function K.Promotion(u,id,value)
 if u:IsHasPromotion(id)~=value then u:SetHasPromotion(id,value) end
end
include('CK_State')
include('CK_Interface')
include('CK_Blessings')
include('CK_Events')
