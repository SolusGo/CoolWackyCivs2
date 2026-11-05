include("CovenantVerses")
include("CovenantMemory")

local M, verses = CovenantMemory, CovenantVerses
local civID = GameInfoTypes.CIVILIZATION_COVENANT_MEMORY
local storage = Modding.OpenSaveData()
local states = {}
local activeID, state
local queued, timerHeld = false, false
local studyRemaining, elapsed = 0, 0
local feedback = ""
local lastRewardTurn = -1
local checking = false
local changingText, previousText = false, ""

-- Curriculum identity prevents old progress from being reused after wording changes.
local signature = 7
for _, verse in ipairs(verses) do
  local identity = verse.reference .. "|" .. verse.text
  for i = 1, #identity do signature = (signature * 31 + identity:byte(i)) % 2147483647 end
end
local function key(id) return "CovenantMemory_v1_" .. signature .. "_P" .. id end

local function save()
  if state then storage:SetValue(key(activeID), M.Encode(state)) end
end

local function eligible()
  if Game.IsNetworkMultiPlayer() or PreGame.IsHotSeatGame() then return false end
  local id = Game.GetActivePlayer()
  local player = Players[id]
  return player and player:IsHuman() and player:IsAlive()
      and player:GetCivilizationType() == civID and player:IsTurnActive()
end

local function focus()
  changingText = true
  Controls.Answer:SetText("")
  previousText = ""
  changingText = false
  Controls.Answer:TakeFocus()
end

local function startStudyTimer()
  local verse = verses[state.session.queue[1]]
  local words = 0
  for _ in verse.text:gmatch("%S+") do words = words + 1 end
  studyRemaining = math.max(12, math.ceil(words * 0.35))
end

local function render()
  local session = state and state.session
  if not session then return end
  local verse = verses[session.queue[1]]
  local study = session.phase == "study"
  Controls.Mode:SetText(session.exam and "TEN-TURN EXAM - ALL FIVE PASSAGES" or "WRITTEN ON THE HEART - MANDATORY RECALL")
  Controls.Progress:SetText("Turn " .. (Game.GetGameTurn() + 1) .. "  |  " .. #session.queue .. " passage(s) remaining  |  " .. M.Mastered(state) .. "/5 mastered")
  Controls.Title:SetText(study and (verse.reference .. " (" .. verse.translation .. ")") or verse.cue)
  Controls.Passage:SetHide(not study)
  Controls.AnswerPanel:SetHide(study)
  Controls.Study:SetHide(study)
  Controls.Submit:SetOffsetX(study and 0 or -212)
  if study then
    Controls.Instructions:SetText("Read aloud. Link each thought to the next. The text disappears before you can answer.")
    local lines = {}
    for i, section in ipairs(verse.sections) do lines[i] = i .. ". " .. section end
    Controls.Passage:SetText(table.concat(lines, "[NEWLINE]"))
    Controls.Submit:SetDisabled(studyRemaining > 0)
    Controls.SubmitLabel:SetText(studyRemaining > 0 and ("READ AND REHEARSE - " .. math.ceil(studyRemaining) .. "s") or "HIDE TEXT AND START RECALL")
    Controls.Feedback:SetText("")
  else
    Controls.Submit:SetDisabled(false)
    Controls.SubmitLabel:SetText("CHECK RECALL")
    if session.phase == "reference" then
      Controls.Instructions:SetText("Type the book, chapter and verse(s) for this passage. Example format: Book 1:2-3")
    else
      Controls.Instructions:SetText(verse.reference .. "  |  Section " .. session.section .. " of " .. #verse.sections .. "  |  " .. M.WordCount(verse.sections[session.section]) .. " words[NEWLINE]Type this section from memory. The word count tells you where to stop.")
    end
    Controls.Feedback:SetText(feedback)
  end
  Controls.Footer:SetText(session.assisted
    and "Learning attempt: completing this check unlocks the game. An unaided later review earns Faith and Culture."
    or "Unaided review: exact words required. Case and punctuation are ignored. A mistake restarts this passage.")
end

local function close()
  if queued then UIManager:DequeuePopup(ContextPtr); queued = false end
end

local function check()
  if checking then return end
  checking = true
  if not eligible() then close(); checking = false; return end
  local id = Game.GetActivePlayer()
  if activeID ~= id then
    activeID = id
    state = states[id]
    if not state then
      state = M.Decode(storage:GetValue(key(id)), verses) or M.New(Game.GetGameTurn(), #verses)
      states[id] = state
    end
    lastRewardTurn = tonumber(storage:GetValue(key(id) .. "_RewardTurn")) or -1
  end
  local alreadyPending = state.session ~= nil
  local session = M.Begin(state, Game.GetGameTurn())
  if not session then close(); checking = false; return end
  if not alreadyPending or (not queued and session.phase == "study") then
    if session.phase == "study" then startStudyTimer() end
    feedback = ""
  end
  if not alreadyPending then save() end
  if not queued then
    queued = true
    render()
    UIManager:QueuePopup(ContextPtr, PopupPriority.eUtmost)
  end
  checking = false
end

local function reward(result)
  -- One reward per game turn, including five-passage exam turns.
  if not result.clean or lastRewardTurn == Game.GetGameTurn() then return end
  local player = Players[activeID]
  local era = player:GetCurrentEra() + 1
  player:ChangeFaith(10 * era)
  player:ChangeJONSCulture(5 * era)
  lastRewardTurn = Game.GetGameTurn()
  storage:SetValue(key(activeID) .. "_RewardTurn", lastRewardTurn)
end

local function submit()
  if not state or not state.session or ContextPtr:IsHidden() then return end
  if state.session.phase == "study" then
    if studyRemaining > 0 then return end
    M.BeginRecall(state)
    feedback = "Text hidden. Start with the reference, then recall every section in order."
  else
    local result = M.Answer(state, verses, Controls.Answer:GetText())
    if result.kind == "wrong" then
      feedback = result.difference
        and ("The wording first differed at word " .. result.difference .. ". Start again with the reference. Use Study again if needed.")
        or "That reference is not correct. Try again, or study the passage and start over."
    elseif result.kind == "next" then
      feedback = "Correct. Keep going from memory."
    else
      reward(result)
      feedback = "Passage recalled. Continue with the next passage."
      if result.kind == "complete" then
        save()
        close()
        Events.GameplayAlertMessage("The Covenant: recall complete. " .. M.Mastered(state) .. "/5 passages mastered. Your turn is unlocked.")
        return
      end
      if state.session.phase == "study" then startStudyTimer() end
    end
  end
  save()
  render()
  if state.session.phase ~= "study" then focus() end
end

Controls.Submit:RegisterCallback(Mouse.eLClick, submit)
Controls.Answer:RegisterCallback(function(text)
  if changingText then return end
  if M.InsertedCharacters(previousText, text) > 1 then
    changingText = true
    Controls.Answer:SetText(previousText)
    changingText = false
    feedback = "Type one character at a time from memory. Pasted text is not accepted."
    Controls.Feedback:SetText(feedback)
    return
  end
  previousText = text
end)
Controls.Study:RegisterCallback(Mouse.eLClick, function()
  if not state or not state.session then return end
  M.Study(state)
  startStudyTimer()
  feedback = ""
  save()
  render()
end)

-- A modal popup consumes all game keys. The EditBox receives text first; no
-- Enter-to-submit callback is used, avoiding double submissions on one keypress.
-- The change callback rejects multi-character insertion, including clipboard paste.
ContextPtr:SetInputHandler(function(uiMsg, wParam, lParam)
  return true
end)

ContextPtr:SetShowHideHandler(function(isHide, isInit)
  if isInit then return end
  if not isHide and not timerHeld then
    UI.incTurnTimerSemaphore()
    timerHeld = true
    if state and state.session and state.session.phase ~= "study" then focus() end
  elseif isHide and timerHeld then
    UI.decTurnTimerSemaphore()
    timerHeld = false
  end
end)

ContextPtr:SetUpdate(function(delta)
  if queued and state and state.session and state.session.phase == "study" and not ContextPtr:IsHidden() then
    local old = math.ceil(studyRemaining)
    studyRemaining = math.max(0, studyRemaining - delta)
    if old ~= math.ceil(studyRemaining) then render() end
  end
  elapsed = elapsed + delta
  if elapsed >= 0.25 then
    elapsed = 0
    -- Re-check after reloads and if another UI forcibly hides our pending gate.
    if queued and ContextPtr:IsHidden() then
      queued = false
      UIManager:DequeuePopup(ContextPtr)
    end
    check()
  end
end)

Events.ActivePlayerTurnStart.Add(check)
Events.LoadScreenClose.Add(check)
Events.GameplaySetActivePlayer.Add(function() close(); activeID = nil; check() end)
print("The Covenant memory gate loaded (single-player, Covenant civilization only).")
