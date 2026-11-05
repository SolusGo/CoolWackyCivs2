-- Small contract mocks for the Civ V methods used by this mod. These do not
-- claim to reproduce the game's renderer or native popup/input dispatch.
saved = saved or {}
controls = {}
local function control()
  local c = {text = '', hidden = false, disabled = false}
  function c:SetText(text)
    self.text = tostring(text)
    if self.editCallback then self.editCallback(self.text, self, false) end
  end
  function c:GetText() return self.text end
  function c:SetHide(hide) self.hidden = hide end
  function c:SetDisabled(disabled) self.disabled = disabled end
  function c:SetOffsetX(x) self.x = x end
  function c:TakeFocus() self.focused = true end
  function c:RegisterCallback(a, b)
    if b then self.click = b else self.editCallback = a end
  end
  return c
end
Controls = setmetatable({}, {__index = function(t, k)
  local c = control(); rawset(t, k, c); return c
end})
ContextPtr = {hidden = true}
function ContextPtr:IsHidden() return self.hidden end
function ContextPtr:SetInputHandler(f) self.input = f end
function ContextPtr:SetShowHideHandler(f) self.showHide = f end
function ContextPtr:SetUpdate(f) self.update = f end
UIManager = {}
function UIManager:QueuePopup(context, priority)
  context.hidden = false
  context.showHide(false, false)
end
function UIManager:DequeuePopup(context)
  context.hidden = true
  context.showHide(true, false)
end
semaphores = 0
UI = {
  incTurnTimerSemaphore = function() semaphores = semaphores + 1 end,
  decTurnTimerSemaphore = function() semaphores = semaphores - 1 end
}
Mouse = {eLClick = 1}
PopupPriority = {eUtmost = 999}
KeyEvents = {KeyDown = 1, KeyUp = 2}
Keys = {VK_ESCAPE = 27, VK_RETURN = 13, VK_SPACE = 32}
GameInfoTypes = {CIVILIZATION_COVENANT_MEMORY = 55}
turn, activePlayer, network, hotseat = 0, 0, false, false
Game = {
  GetGameTurn = function() return turn end,
  GetActivePlayer = function() return activePlayer end,
  IsNetworkMultiPlayer = function() return network end
}
PreGame = {IsHotSeatGame = function() return hotseat end}
player = {civ = 55, human = true, alive = true, active = true, era = 0, faith = 0, culture = 0}
function player:IsHuman() return self.human end
function player:IsAlive() return self.alive end
function player:IsTurnActive() return self.active end
function player:GetCivilizationType() return self.civ end
function player:GetCurrentEra() return self.era end
function player:ChangeFaith(n) self.faith = self.faith + n end
function player:ChangeJONSCulture(n) self.culture = self.culture + n end
Players = {[0] = player}
Modding = {OpenSaveData = function() return {
  GetValue = function(self, key) return saved[key] end,
  SetValue = function(self, key, value) saved[key] = value end
} end}
Events = {}
for _, name in ipairs({'ActivePlayerTurnStart', 'LoadScreenClose', 'GameplaySetActivePlayer'}) do
  local event = {handlers = {}}
  function event.Add(f) event.handlers[#event.handlers + 1] = f end
  function event.fire() for _, f in ipairs(event.handlers) do f() end end
  Events[name] = event
end
Events.GameplayAlertMessage = function(message) lastAlert = message end
function tick(seconds)
  for i = 1, math.ceil(seconds * 4) do ContextPtr.update(0.25) end
end
function click(name)
  if not Controls[name].hidden and not Controls[name].disabled then Controls[name].click() end
end
function typeText(text)
  Controls.Answer:SetText('')
  for i = 1, #text do Controls.Answer:SetText(Controls.Answer:GetText() .. text:sub(i, i)) end
end
function currentState()
  for key, value in pairs(saved) do
    if not key:find('_RewardTurn') then return CovenantMemory.Decode(value, CovenantVerses) end
  end
end
function finishPassage()
  local s = currentState()
  local verse = CovenantVerses[s.session.queue[1]]
  if s.session.phase == 'study' then tick(60); click('Submit') end
  s = currentState()
  if s.session.phase == 'reference' then typeText(verse.reference); click('Submit') end
  while currentState().session and currentState().session.queue[1] == s.session.queue[1] do
    local now = currentState()
    typeText(verse.sections[now.session.section]); click('Submit')
  end
end
