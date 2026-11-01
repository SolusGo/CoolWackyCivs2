-- Native player/plot/unit ScriptData is serialized by CP151 with the save.
-- Preserve all foreign data. MapModData holds listeners, never authoritative state.
TRI = TRI or {}
function TRI.Get(object, key)
  return (object:GetScriptData() or ''):match('%[TRI1_'..key..'=([^%]]*)%]')
end
function TRI.Put(object, key, value)
  local old = object:GetScriptData() or ''
  local new = old:gsub('%[TRI1_'..key..'=[^%]]*%]', '')
  if value ~= nil then new = new..'[TRI1_'..key..'='..tostring(value)..']' end
  if old ~= new then object:SetScriptData(new) end
end
function TRI.IsImperium(player)
  return player and player:IsAlive() and player:IsHuman()
      and player:GetCivilizationType() == GameInfoTypes.CIVILIZATION_TRIUMPHAL_IMPERIUM
end
function TRI.IsMajor(player)
  -- An eliminated victim still qualifies; do not require IsAlive here.
  return player and not player:IsMinorCiv() and not player:IsBarbarian()
end
function TRI.IsMilitary(unit)
  -- CP IsCombatUnit tests only base melee strength; aircraft may be ranged-only.
  local row = unit and GameInfo.Units[unit:GetUnitType()]
  return unit and (unit:IsCombatUnit() or (row and ((row.RangedCombat or 0) > 0
      or (row.NukeDamageLevel or -1) >= 0)))
end
function TRI.AreEnemies(a, b)
  return a and b and a:GetTeam() ~= b:GetTeam() and Teams[a:GetTeam()]:IsAtWar(b:GetTeam())
end
function TRI.Momentum(player)
  return math.max(0, math.min(6, tonumber(TRI.Get(player, 'M')) or 0))
end
function TRI.CityIdentity(city)
  return city:GetOriginalOwner()..':'..city:GetGameTurnFounded()
end
function TRI.Notice(player, key, value)
  player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC,
    Locale.ConvertTextKey('TXT_KEY_TRI_NOTICE_'..key, value),
    Locale.ConvertTextKey('TXT_KEY_TRI_NOTICE_TITLE'), -1, -1)
end
