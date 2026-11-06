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
local checking, submitting = false, false
local actionRecovery = false
local changingText, previousText = false, ""
local answerEdited = false

-- Curriculum identity prevents old progress from being reused after wording changes.
local signature = 7
for _, verse in ipairs(verses) do
  local identity = verse.reference .. "|" .. verse.text
  for i = 1, #identity do signature = (signature * 31 + identity:byte(i)) % 2147483647 end
end
local function key(id) return "CovenantMemory_v1_" .. signature .. "_P" .. id end

local function save()
  if state then storage.SetValue(key(activeID), M.Encode(state)) end
end

local function eligible()
  if Game.IsNetworkMultiPlayer() or PreGame.IsHotSeatGame() then return false end
  local id = Game.GetActivePlayer()
  local player = Players[id]
  return player and player:IsHuman() and player:IsAlive()
      and player:GetCivilizationType() == civID and player:IsTurnActive()
end

local function focus(clear)
  if clear then
    changingText = true
    Controls.Answer:SetText("")
    previousText = ""
    answerEdited = false
    changingText = false
  end
  if not ContextPtr:IsHidden() and state and state.session and state.session.phase ~= "study" then
    Controls.Answer:TakeFocus()
  end
end

local function startStudyTimer()
  studyRemaining = 10
end

local function wrongAnswerFeedback(result)
  if not result.maskedSection then
    return "Reference incorrect. Expected " .. result.expectedReference .. ".[NEWLINE]Restart from the reference."
  end
  return "Section " .. result.section .. ": ____ marks mistakes. Restart from the reference.[NEWLINE]"
    .. result.maskedSection
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
  if queued then
    -- Clear ownership before native callbacks (which may be synchronous).
    queued = false
    UIManager:DequeuePopup(ContextPtr)
  end
  if timerHeld then timerHeld = false; UI.decTurnTimerSemaphore() end
end

local function checkState()
  if not eligible() then close(); return end
  local id = Game.GetActivePlayer()
  if activeID ~= id then
    activeID = id
    state = states[id]
    if not state then
      state = M.Decode(storage.GetValue(key(id)), verses)
      local turn = Game.GetGameTurn()
      -- SaveData belongs to the current Civ5Save, not the per-user database.
      -- Preserve v24's curriculum/player key and migrate its v1 payload in place.
      if state and (state.startTurn > turn or state.clearedTurn > turn
          or state.lastExamTurn > turn or state.rewardTurn > turn
          or (state.session and state.session.turn > turn)) then state = nil end
      state = state or M.New(Game.GetStartTurn(), #verses)
      local legacyReward = tonumber(storage.GetValue(key(id) .. "_RewardTurn"))
      if legacyReward and legacyReward == math.floor(legacyReward) and legacyReward >= 0
          and legacyReward <= turn then state.rewardTurn = math.max(state.rewardTurn, legacyReward) end
      states[id] = state
    end
    save()
  end
  if actionRecovery then
    -- An action may have advanced before a save/control/yield call failed.
    -- Persist that state and repair its view, never replay the answer or reward.
    save()
    if state.session then render(); focus(true) end
    actionRecovery = false
  end
  local alreadyPending = state.session ~= nil
  local session = M.Begin(state, Game.GetGameTurn())
  if not session then close(); return end
  if not alreadyPending or (not queued and session.phase == "study") then
    if session.phase == "study" then startStudyTimer() end
    feedback = ""
    focus(true)
  end
  if not alreadyPending then save() end
  if not queued or not alreadyPending then
    -- Refresh newly due sessions even if action recovery retained our queue.
    -- Rendering must succeed before a new native queue request owns the context.
    render()
  end
  if not queued then
    queued = true
    local ok, err = pcall(function() UIManager:QueuePopup(ContextPtr, PopupPriority.eUtmost) end)
    if not ok then
      -- A failed request has unknown side effects. Roll back THIS request only;
      -- this is distinct from guessing that a hidden, successful queue is lost.
      close()
      error(err)
    end
  end
end

local function check()
  if checking then return end
  checking = true
  local ok, err = pcall(checkState)
  checking = false
  if not ok then
    if not state or not states[activeID] then activeID = nil end
    print("The Covenant gate check will retry: " .. tostring(err))
  end
end

local function reward(result)
  -- One reward per game turn, including five-passage exam turns.
  if not result.clean or state.rewardTurn >= Game.GetGameTurn() then save(); return end
  if not eligible() or activeID ~= Game.GetActivePlayer() then save(); return end
  local player = Players[activeID]
  local era = player:GetCurrentEra() + 1
  -- Journal completion and reward entitlement together BEFORE changing yields.
  -- Also retain the legacy marker for older v24 UI code reading this save.
  state.rewardTurn = Game.GetGameTurn()
  save()
  storage.SetValue(key(activeID) .. "_RewardTurn", state.rewardTurn)
  player:ChangeFaith(10 * era)
  player:ChangeJONSCulture(5 * era)
end

local function submitAnswer()
  if not eligible() or activeID ~= Game.GetActivePlayer() or not queued
      or not state or not state.session or ContextPtr:IsHidden() then return end
  if state.session.phase == "study" then
    if studyRemaining > 0 then return end
    M.BeginRecall(state)
    feedback = "Text hidden. Start with the reference, then recall every section in order."
  else
    local answer = Controls.Answer:GetText()
    -- A repeated click/callback after advancing has no newly entered answer.
    if not answerEdited then return end
    local result = M.Answer(state, verses, answer, Game.GetGameTurn())
    if result.kind == "wrong" then
      feedback = wrongAnswerFeedback(result)
    elseif result.kind == "next" then
      feedback = "Correct. Keep going from memory."
    else
      reward(result)
      feedback = "Passage recalled. Continue with the next passage."
      if result.kind == "complete" then
        save()
        -- A carried ordinary check (or older exam) may finish on a newly due
        -- exam turn. Resolve that obligation before releasing the existing gate.
        check()
        if state.session then render(); focus(true); return end
        Events.GameplayAlertMessage("The Covenant: recall complete. " .. M.Mastered(state) .. "/5 passages mastered. Your turn is unlocked.")
        return
      end
      if state.session.phase == "study" then startStudyTimer() end
    end
  end
  save()
  render()
  focus(true)
end

local function runAction(action)
  if submitting or actionRecovery then return end
  submitting = true
  local ok, err = pcall(action)
  submitting = false
  if not ok then
    actionRecovery = true
    print("The Covenant action view will recover: " .. tostring(err))
  end
end
local function submit()
  runAction(submitAnswer)
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
  if previousText ~= text then answerEdited = true end
  previousText = text
end)
local function study()
  if not eligible() or activeID ~= Game.GetActivePlayer() or not queued
      or ContextPtr:IsHidden() or not state or not state.session then return end
  M.Study(state)
  startStudyTimer()
  feedback = ""
  save()
  render()
  focus(true)
end
Controls.Study:RegisterCallback(Mouse.eLClick, function()
  runAction(study)
end)

-- Match the shipped SetCityName/SetUnitName modal EditBox pattern: consume
-- unhandled game input. Native child-control dispatch is NOT simulated by tests.
-- Do not clear/refocus on ordinary keys: that breaks selection and navigation.
-- Enter/lost-focus EditBox callbacks never submit; only the button does.
ContextPtr:SetInputHandler(function(uiMsg, wParam, lParam)
  return true
end)

ContextPtr:SetShowHideHandler(function(isHide, isInit)
  if isInit then return end
  if not isHide and (not queued or not state or not state.session or not eligible()
      or activeID ~= Game.GetActivePlayer()) then return end
  if not isHide and not timerHeld then
    timerHeld = true
    UI.incTurnTimerSemaphore()
    if state and state.session and state.session.phase ~= "study" then focus(false) end
  elseif isHide and timerHeld then
    timerHeld = false
    UI.decTurnTimerSemaphore()
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
    -- Hidden is normal while another popup owns the surface. Keep our queue
    -- ownership until WE dequeue it; no supported per-context queue query was
    -- found in shipped scripts. Never infer lost membership from visibility.
    -- This check repairs missed turn/load notifications and our own closed state.
    check()
  end
end)

Events.ActivePlayerTurnStart.Add(check)
Events.LoadScreenClose.Add(check)
Events.GameplaySetActivePlayer.Add(function() close(); activeID = nil; check() end)
print("The Covenant memory gate loaded (single-player, Covenant civilization only).")
