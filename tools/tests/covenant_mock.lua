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
  function c:TakeFocus() self.focused = true; self.focusCalls = (self.focusCalls or 0) + 1 end
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
UIManager = {queueCalls = 0, dequeueCalls = 0, blocked = false, member = false}
function UIManager:refresh()
  local hidden = self.blocked or not self.member
  if ContextPtr.hidden ~= hidden then
    ContextPtr.hidden = hidden
    ContextPtr.showHide(hidden, false)
  end
end
function UIManager:QueuePopup(context, priority)
  assert(context == ContextPtr and priority == PopupPriority.eUtmost)
  assert(not self.member, 'duplicate queue entry')
  self.queueCalls = self.queueCalls + 1
  self.member = true
  self:refresh()
end
function UIManager:DequeuePopup(context)
  assert(context == ContextPtr)
  self.dequeueCalls = self.dequeueCalls + 1
  self.member = false
  self:refresh()
end
semaphores, timerIncrements, timerDecrements = 0, 0, 0
UI = {
  incTurnTimerSemaphore = function() semaphores = semaphores + 1; timerIncrements = timerIncrements + 1; assert(semaphores == 1) end,
  decTurnTimerSemaphore = function() semaphores = semaphores - 1; timerDecrements = timerDecrements + 1; assert(semaphores == 0) end
}
Mouse = {eLClick = 1}
PopupPriority = {eUtmost = 999}
KeyEvents = {KeyDown = 1, KeyUp = 2}
Keys = {VK_ESCAPE = 27, VK_RETURN = 13, VK_SPACE = 32}
GameInfoTypes = {CIVILIZATION_COVENANT_MEMORY = 55}
turn, startTurn, activePlayer, network, hotseat = 0, 0, 0, false, false
Game = {
  GetGameTurn = function() return turn end,
  GetStartTurn = function() return startTurn end,
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
  GetValue = function(key, ...) assert(type(key) == 'string' and select('#', ...) == 0); return saved[key] end,
  SetValue = function(key, value, ...) assert(type(key) == 'string' and select('#', ...) == 0); saved[key] = value end
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
    if key:match('^CovenantMemory_v1_.*_P' .. activePlayer .. '$') then return CovenantMemory.Decode(value, CovenantVerses) end
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
