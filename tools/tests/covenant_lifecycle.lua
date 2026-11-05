-- Each scenario runs in a fresh Lua 5.1 fixture. These are contract tests,
-- NOT evidence of native EditBox dispatch or native popup queue membership.
return {
  ["action recovery paints a newly due exam without releasing the gate"] = function()
    turn = 5; Events.LoadScreenClose.fire()
    for t = 5, 8 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
    turn = 9; Events.ActivePlayerTurnStart.fire(); tick(60); click('Submit')
    typeText(CovenantVerses[5].reference); click('Submit')
    for n = 1, #CovenantVerses[5].sections - 1 do
      typeText(CovenantVerses[5].sections[n]); click('Submit')
    end
    local original = saved
    saved = setmetatable({}, {__index = original, __newindex = function()
      error('injected final introduction save failure')
    end})
    typeText(CovenantVerses[5].sections[#CovenantVerses[5].sections]); click('Submit')
    saved = original; tick(1)
    local s = currentState()
    assert(s.session.exam and #s.session.queue == 5)
    assert(Controls.Title:GetText() == CovenantVerses[s.session.queue[1]].cue)
    assert(Controls.Instructions:GetText():find('Type the book', 1, true))
    assert(UIManager.queueCalls == 5 and UIManager.dequeueCalls == 4 and semaphores == 1)
    for n = 1, 5 do finishPassage() end
    assert(ContextPtr.hidden and semaphores == 0 and timerIncrements == timerDecrements)
    assert(player.faith == 10 and player.culture == 5)
  end,
  ["action render failures release guards and recover the current prompt"] = function()
    Events.LoadScreenClose.fire(); tick(60)
    local set = Controls.Instructions.SetText
    Controls.Instructions.SetText = function() error('injected action render failure') end
    click('Submit')
    assert(currentState().session.phase == 'reference' and semaphores == 1)
    -- Neither button may replay an action while the view is stale.
    click('Study'); click('Submit')
    assert(currentState().session.phase == 'reference')
    Controls.Instructions.SetText = set
    tick(1)
    assert(not Controls.AnswerPanel.hidden and Controls.Answer:GetText() == '')
    typeText(CovenantVerses[1].reference); click('Submit')
    assert(currentState().session.phase == 'section')
    -- Study uses the same protected action path and recovers its new phase.
    Controls.Instructions.SetText = function() error('injected study render failure') end
    click('Study')
    assert(currentState().session.phase == 'study' and currentState().session.assisted)
    Controls.Instructions.SetText = set
    tick(1); finishPassage()
    assert(UIManager.queueCalls == 1 and UIManager.dequeueCalls == 1)
    assert(semaphores == 0 and timerIncrements == timerDecrements)
  end,
  ["failed action saves retry progression without replaying the answer"] = function()
    Events.LoadScreenClose.fire(); tick(60); click('Submit')
    typeText(CovenantVerses[1].reference); click('Submit')
    typeText(CovenantVerses[1].sections[1])
    local original = saved
    saved = setmetatable({}, {__index = original, __newindex = function()
      error('injected transient save failure')
    end})
    click('Submit'); click('Submit'); click('Study')
    saved = original
    assert(currentState().session.section == 1) -- prior durable payload
    tick(1)
    assert(currentState().session.section == 2 and Controls.Answer:GetText() == '')
    click('Submit')
    assert(currentState().session.section == 2 and currentState().lessons[1].failures == 0)
    finishPassage()
    assert(ContextPtr.hidden and semaphores == 0 and UIManager.queueCalls == 1)
  end,
  ["fault after a native reward mutation never replays the grant"] = function()
    Events.LoadScreenClose.fire()
    for t = 0, 4 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
    turn = 5; Events.ActivePlayerTurnStart.fire()
    typeText(CovenantVerses[1].reference); click('Submit')
    for n = 1, #CovenantVerses[1].sections - 1 do
      typeText(CovenantVerses[1].sections[n]); click('Submit')
    end
    local change = player.ChangeFaith
    player.ChangeFaith = function(self, amount)
      change(self, amount); error('injected fault after Faith mutation')
    end
    typeText(CovenantVerses[1].sections[#CovenantVerses[1].sections]); click('Submit')
    assert(player.faith == 10 and player.culture == 0 and currentState().rewardTurn == 5)
    player.ChangeFaith = change
    tick(1); Controls.Submit.click(); Events.LoadScreenClose.fire()
    assert(ContextPtr.hidden and semaphores == 0 and player.faith == 10 and player.culture == 0)
    assert(currentState().lessons[1].passes == 2)
    turn = 6; Events.ActivePlayerTurnStart.fire(); finishPassage()
    assert(player.faith == 20 and player.culture == 5)
  end,
  ["known render and queue failures recover without duplicate entries"] = function()
    local set = Controls.Mode.SetText
    Controls.Mode.SetText = function() error('injected render failure') end
    Events.LoadScreenClose.fire()
    assert(not UIManager.member and UIManager.queueCalls == 0 and semaphores == 0)
    Controls.Mode.SetText = set
    tick(1)
    assert(UIManager.member and UIManager.queueCalls == 1 and semaphores == 1)
    player.active = false; tick(1)
    local queue = UIManager.QueuePopup
    UIManager.QueuePopup = function(self, context, priority)
      queue(self, context, priority)
      error('injected fault after native queue insertion')
    end
    player.active = true; Events.ActivePlayerTurnStart.fire()
    assert(not UIManager.member and semaphores == 0)
    UIManager.QueuePopup = queue
    tick(1)
    assert(UIManager.member and UIManager.queueCalls == 3 and semaphores == 1)
    finishPassage()
    assert(semaphores == 0 and timerIncrements == timerDecrements)
  end,
  ["stale show callbacks and missing hide notifications do not leak timers"] = function()
    Events.LoadScreenClose.fire()
    UIManager.DequeuePopup = function(self, context)
      assert(context == ContextPtr)
      self.member = false; self.dequeueCalls = self.dequeueCalls + 1
      ContextPtr.hidden = true -- deliberately omit the native hide notification
    end
    finishPassage()
    assert(semaphores == 0 and timerIncrements == timerDecrements)
    local increments = timerIncrements
    ContextPtr.showHide(true, false); ContextPtr.showHide(false, false)
    assert(semaphores == 0 and timerIncrements == increments)
  end,
  ["player keys and reward recipients remain separate"] = function()
    Events.LoadScreenClose.fire()
    Players[1] = setmetatable({era = 2, faith = 0, culture = 0}, {__index = player})
    activePlayer = 1; Events.GameplaySetActivePlayer.fire()
    for t = 0, 4 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
    turn = 5; Events.ActivePlayerTurnStart.fire(); finishPassage()
    assert(Players[1].faith == 30 and Players[1].culture == 15)
    assert(player.faith == 0 and player.culture == 0)
    activePlayer = 0; Events.GameplaySetActivePlayer.fire()
    assert(currentState().session.phase == 'study' and currentState().lessons[1].passes == 0)
  end,
  ["inactive queue waits without churn or stealing focus"] = function()
    UIManager.blocked = true
    Events.LoadScreenClose.fire()
    assert(ContextPtr.hidden and UIManager.member and UIManager.queueCalls == 1)
    tick(3); Events.LoadScreenClose.fire(); Events.ActivePlayerTurnStart.fire()
    assert(UIManager.queueCalls == 1 and UIManager.dequeueCalls == 0 and semaphores == 0)
    assert(not Controls.Answer.focused)
    UIManager.blocked = false; UIManager:refresh()
    assert(not ContextPtr.hidden and semaphores == 1)
    finishPassage()
    assert(not UIManager.member and ContextPtr.hidden and semaphores == 0)
    assert(timerIncrements == timerDecrements)
  end,
  ["preempted recall preserves text and priority"] = function()
    Events.LoadScreenClose.fire(); tick(60); click('Submit')
    typeText('Revelation')
    local calls = Controls.Answer.focusCalls
    UIManager.blocked = true; UIManager:refresh()
    tick(3)
    assert(UIManager.queueCalls == 1 and UIManager.dequeueCalls == 0)
    assert(semaphores == 0 and Controls.Answer:GetText() == 'Revelation')
    assert(Controls.Answer.focusCalls == calls)
    UIManager.blocked = false; UIManager:refresh()
    assert(semaphores == 1 and Controls.Answer:GetText() == 'Revelation')
    assert(Controls.Answer.focusCalls == calls + 1)
    finishPassage()
    assert(semaphores == 0)
  end,
  ["duplicate show hide notifications balance semaphore ownership"] = function()
    ContextPtr.showHide(true, true)
    Events.LoadScreenClose.fire()
    ContextPtr.showHide(false, false); ContextPtr.showHide(false, false)
    assert(semaphores == 1 and timerIncrements == 1)
    UIManager.blocked = true; UIManager:refresh()
    ContextPtr.showHide(true, false); ContextPtr.showHide(true, false)
    assert(semaphores == 0 and timerDecrements == 1)
    player.active = false; tick(1)
    assert(not UIManager.member and semaphores == 0)
    player.active = true; tick(1)
    assert(UIManager.member and ContextPtr.hidden and UIManager.queueCalls == 2)
    UIManager.blocked = false; UIManager:refresh(); finishPassage()
    assert(semaphores == 0 and timerIncrements == timerDecrements)
  end,
  ["timer advances only during visible study"] = function()
    UIManager.blocked = true; Events.LoadScreenClose.fire(); tick(60)
    UIManager.blocked = false; UIManager:refresh(); click('Submit')
    assert(currentState().session.phase == 'study')
    tick(60); click('Submit')
    assert(currentState().session.phase == 'reference')
  end,
  ["single edits deletion replacement and focus callbacks"] = function()
    Events.LoadScreenClose.fire(); tick(60); click('Submit')
    Controls.Answer:SetText('a'); Controls.Answer:SetText('ab')
    Controls.Answer:SetText('a'); assert(Controls.Answer:GetText() == 'a')
    Controls.Answer:SetText('b'); assert(Controls.Answer:GetText() == 'b')
    Controls.Answer:SetText('\226\128\153'); assert(Controls.Answer:GetText() == '\226\128\153')
    Controls.Answer:SetText('pasted words'); assert(Controls.Answer:GetText() == '\226\128\153')
    Controls.Answer:SetText(''); typeText('Revelation')
    local before = CovenantMemory.Encode(currentState())
    Controls.Answer.editCallback('Revelation', Controls.Answer, true)
    assert(CovenantMemory.Encode(currentState()) == before)
    assert(Controls.Answer:GetText() == 'Revelation')
    for _, key in ipairs({8, 46, 37, 39, 36, 35, 27, 13, 116, 65}) do
      assert(ContextPtr.input(KeyEvents.KeyDown, key, 0))
      assert(ContextPtr.input(KeyEvents.KeyUp, key, 0))
    end
    assert(Controls.Answer:GetText() == 'Revelation' and not ContextPtr.hidden)
    -- Keys above only test the unhandled-input return contract, not editing.
  end,
  ["repeated submit callbacks do not advance or fail the next prompt"] = function()
    Events.LoadScreenClose.fire(); tick(60); click('Submit'); click('Submit')
    assert(currentState().session.phase == 'reference' and currentState().lessons[1].failures == 0)
    typeText(CovenantVerses[1].reference); click('Submit'); click('Submit')
    assert(currentState().session.section == 1 and currentState().lessons[1].failures == 0)
    typeText(CovenantVerses[1].sections[1]); click('Submit'); click('Submit')
    assert(currentState().session.section == 2 and currentState().lessons[1].failures == 0)
    typeText('a'); Controls.Answer:SetText(''); click('Submit'); click('Submit')
    assert(currentState().session.phase == 'reference' and currentState().lessons[1].failures == 1)
  end,
  ["inactive player callbacks cannot award or alter progression"] = function()
    Events.LoadScreenClose.fire(); tick(60); click('Submit')
    typeText(CovenantVerses[1].reference)
    local before = CovenantMemory.Encode(currentState())
    player.active = false; Controls.Submit.click(); Controls.Study.click()
    assert(CovenantMemory.Encode(currentState()) == before and player.faith == 0)
    tick(1); assert(ContextPtr.hidden and semaphores == 0)
  end,
  ["active player transition releases ownership and preserves pending section"] = function()
    Events.LoadScreenClose.fire(); tick(60); click('Submit')
    typeText(CovenantVerses[1].reference); click('Submit')
    local original = player
    activePlayer = 1; Players[1] = {IsHuman = function() return false end}
    Events.GameplaySetActivePlayer.fire()
    assert(ContextPtr.hidden and semaphores == 0 and not UIManager.member)
    activePlayer = 0; Events.GameplaySetActivePlayer.fire()
    assert(not ContextPtr.hidden and currentState().session.phase == 'section')
    assert(semaphores == 1 and Players[0] == original)
  end,
  ["era scaled rewards and repeated turn events cannot duplicate grants"] = function()
    Events.LoadScreenClose.fire()
    for t = 0, 4 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
    player.era = 3; turn = 5; Events.ActivePlayerTurnStart.fire(); finishPassage()
    assert(player.faith == 40 and player.culture == 20 and currentState().rewardTurn == 5)
    Controls.Submit.click(); Events.ActivePlayerTurnStart.fire(); tick(1)
    assert(player.faith == 40 and player.culture == 20 and ContextPtr.hidden)
  end,
  ["failure and study never earn rewards"] = function()
    Events.LoadScreenClose.fire()
    for t = 0, 4 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
    turn = 5; Events.ActivePlayerTurnStart.fire()
    typeText('wrong reference'); click('Submit'); finishPassage()
    assert(player.faith == 0 and currentState().lessons[1].failures == 1)
    turn = 6; Events.ActivePlayerTurnStart.fire(); click('Study'); finishPassage()
    assert(player.faith == 0 and player.culture == 0)
  end,
  ["late first initialization uses campaign start for exam cadence"] = function()
    turn = 5; Events.LoadScreenClose.fire()
    assert(currentState().startTurn == 0)
    for t = 5, 9 do turn = t; Events.ActivePlayerTurnStart.fire(); finishPassage() end
    tick(1)
    assert(currentState().session.exam and #currentState().session.queue == 5)
    assert(not ContextPtr.hidden and semaphores == 1)
    assert(UIManager.queueCalls == 5 and UIManager.dequeueCalls == 4)
  end
}
