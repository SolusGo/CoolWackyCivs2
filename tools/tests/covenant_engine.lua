local M, V = CovenantMemory, CovenantVerses
local tests = 0
local function test(name, fn)
  fn()
  tests = tests + 1
  print("PASS " .. name)
end
local function complete(s, wrong)
  if s.session.phase == "study" then M.BeginRecall(s) end
  local id = s.session.queue[1]
  assert(M.Answer(s, V, V[id].reference).kind == "next")
  local result
  for _, section in ipairs(V[id].sections) do result = M.Answer(s, V, section) end
  return result
end

test("all five exact supplied texts, including corrected John", function()
  assert(#V == 5)
  assert(V[5].text == "I have told you now before it happens, so that when it does happen you will believe.")
  assert(V[4].text ~= V[5].text)
  assert(V[1].text == "You say, 'I am rich; I have acquired wealth and do not need a thing.' But you do not realize that you are wretched, pitiful, poor, blind and naked. I counsel you to buy from me gold refined in the fire, so you can become rich; and white clothes to wear, so you can cover your shameful nakedness; and salve to put on your eyes, so you can see.")
  assert(V[2].text == "The Holy Spirit was showing by this that the way into the Most Holy Place had not yet been disclosed as long as the first tabernacle was still functioning.")
  assert(V[3].text == '"I will send my messenger, who will prepare the way before me. Then suddenly the Lord you are seeking will come to his temple; the messenger of the covenant, whom you desire, will come," says the LORD Almighty.')
  assert(V[4].text == 'They serve at a sanctuary that is a copy and shadow of what is in heaven. This is why Moses was warned when he was about to build the tabernacle: "See to it that you make everything according to the pattern shown you on the mountain."')
  for _, verse in ipairs(V) do
    assert(verse.text == table.concat(verse.sections, " "))
    for _, section in ipairs(verse.sections) do assert(#section < 512) end
  end
end)

test("punctuation and case ignored; word changes rejected", function()
  assert(M.Normalize('  I COUNSEL you;   gold. ') == 'i counsel you gold')
  assert(M.Normalize('\226\128\156I am rich\226\128\157') == 'i am rich')
  assert(M.FirstDifference("you rich", "you are rich") == 2)
  assert(M.FirstDifference("you are rich now", "you are rich") == 4)
  assert(M.FirstDifference("you rich are", "you are rich") == 2)
  assert(M.FirstDifference("goldrefined", "gold refined") == 1)
  assert(M.ReferenceMatches('Revelation 3:17\226\128\14718', V[1].reference))
  assert(not M.ReferenceMatches('Revelation 3:17', V[1].reference))
  assert(not M.ReferenceMatches('Hebrews 8:5', V[2].reference))
end)

test("five turns introduce all passages; same turn cannot farm", function()
  local s = M.New(0, #V)
  for turn = 0, 4 do
    assert(M.Begin(s, turn).queue[1] == turn + 1)
    local result = complete(s)
    assert(not result.clean and result.kind == 'complete')
    assert(M.Begin(s, turn) == nil)
  end
  assert(M.Begin(s, 5).queue[1] == 1)
end)

test("wrong words restart entire passage and remove clean reward", function()
  local s = M.New(0, #V)
  M.Begin(s, 0); M.BeginRecall(s)
  M.Answer(s, V, V[1].reference)
  M.Answer(s, V, V[1].sections[1])
  local r = M.Answer(s, V, 'missing most words')
  assert(r.kind == 'wrong' and r.difference == 1)
  assert(s.session.phase == 'reference' and s.session.section == 1)
  assert(s.lessons[1].passes == 0 and s.lessons[1].failures == 1)
  assert(not complete(s).clean)
end)

test("assistance and mistakes reset mastery; intervals stay bounded", function()
  local s = M.New(0, #V)
  for turn = 0, 4 do M.Begin(s, turn); complete(s) end
  -- Isolate one already-learned passage for scheduling assertions.
  for i = 2, #V do s.lessons[i].due = 99999 end
  local turn = 5
  for clean, interval in ipairs({2, 4, 8, 12, 12}) do
    s.clearedTurn = -1
    -- Avoid exam turns in this isolated interval test.
    if (turn + 1) % 10 == 0 then turn = turn + 1 end
    if turn >= 9 then s.lastExamTurn = turn end -- isolate intervals from overdue exams
    assert(M.Begin(s, turn).phase == 'reference')
    assert(complete(s).clean)
    assert(s.lessons[1].clean == clean and s.lessons[1].due == turn + interval)
    turn = turn + interval
  end
  assert(M.Mastered(s) == 1)
  s.lastExamTurn = turn
  M.Begin(s, turn)
  M.Study(s)
  assert(M.Mastered(s) == 0)
  assert(not complete(s).clean and s.lessons[1].due == turn + 1)
end)

test("tenth-turn exam requires all five, rotates order, persists midway", function()
  local s = M.New(0, #V)
  for turn = 0, 4 do M.Begin(s, turn); complete(s) end
  assert(M.Begin(s, 9).exam and #s.session.queue == 5)
  local first = s.session.queue[1]
  assert(complete(s).kind == 'pass' and #s.session.queue == 4)
  s = assert(M.Decode(M.Encode(s), V))
  assert(s.session.exam and #s.session.queue == 4)
  for i = 1, 4 do complete(s) end
  assert(not s.session and s.lastExamTurn == 9 and not M.Begin(s, 9))
  assert(M.Begin(s, 19).exam and s.session.queue[1] ~= first)
end)

test("save reload preserves section, errors, assistance and pending queue", function()
  local s = M.New(37, #V)
  M.Begin(s, 37); M.BeginRecall(s)
  M.Answer(s, V, V[1].reference)
  M.Answer(s, V, V[1].sections[1])
  local encoded = M.Encode(s)
  local restored = assert(M.Decode(encoded, V))
  assert(M.Encode(restored) == encoded)
  assert(restored.session.section == 2 and restored.session.assisted)
  assert(M.Begin(restored, 37).queue[1] == 1)
  M.Answer(restored, V, 'wrong')
  restored = assert(M.Decode(M.Encode(restored), V))
  assert(restored.lessons[1].failures == 1 and restored.session.phase == 'reference')
end)

test("malformed saves fail closed rather than executing arbitrary text", function()
  for _, text in ipairs({'', 'os.execute("anything")', '1,', '1,,2', '1,0,-1,-1,2', '999,1,2', '1,0,-1,-1,0,5,0,0,1,0'}) do
    assert(M.Decode(text, V) == nil)
  end
  local s = M.New(0, #V)
  M.Begin(s, 0)
  local encoded = M.Encode(s)
  assert(not M.Decode(encoded .. ',123', V))
  assert(not M.Decode(encoded:gsub('^2,', '999,'), V))
end)

test("paste detection covers insertion and replacement selections", function()
  assert(M.InsertedCharacters('', 'a') == 1)
  assert(M.InsertedCharacters('abc', 'abdc') == 1)
  assert(M.InsertedCharacters('abc', 'ac') == 0)
  assert(M.InsertedCharacters('', 'full pasted verse') > 1)
  assert(M.InsertedCharacters('xxx', 'gold refined') > 1)
  assert(M.InsertedCharacters('xx', 'ab') > 1)
end)

test("reference components never collapse digits or lose range boundaries", function()
  for _, v in ipairs(V) do
    assert(M.ReferenceMatches(v.reference, v.reference))
    assert(M.ReferenceMatches(v.reference:upper():gsub(' ', ''):gsub(':', ' : '):gsub('-', ' - '), v.reference))
  end
  for _, bad in ipairs({
    'Revelation 31:7-18', 'Revelation 3:1-718', 'Revelation 3:1718',
    'Revelation 3:17', 'Revelation 3:17-19', 'Revelation 3:18-17',
    'Revelation 3:17-18-19', 'Revelation 3:17,18', 'Revelation 3:17 to 18',
    'Revelation 3 17 18', 'Revelation 3::17-18', 'Revelation 3:17-',
    'Revelation 03:17-18', 'Revelation 3:017-18', 'Revelation 3:17-018',
    'Revelation 0:17-18', 'Revelation 3:0-18', 'Revelation 3:17-0',
    'Revelations 3:17-18', 'Rev 3:17-18', 'Reve lation 3:17-18',
    'Revelation 3:1 7-18', 'Revelation 3:17-1 8', 'Revelation 3:17-18 extra',
    'Revelation 3:17-18.', 'Revelation +3:17-18', 'Revelation 3.0:17-18',
    'Revelation 3:17/18', 'Revelation 3:17:18', 'Revelation 3:17\226\128\139-18'
  }) do assert(not M.ReferenceMatches(bad, V[1].reference), bad) end
  for _, bad in ipairs({'John 1:429', 'John 14:2-9', 'John 14:29-29', 'John 14:29-'}) do
    assert(not M.ReferenceMatches(bad, V[5].reference), bad)
  end
  assert(not M.ReferenceMatches('', ''))
  assert(not M.ReferenceMatches(nil, V[1].reference))
  for _, space in ipairs({'\194\160', '\226\128\137', '\226\128\175', '\227\128\128', '\t'}) do
    for _, dash in ipairs({'-', '\226\128\147', '\226\128\148'}) do
      assert(M.ReferenceMatches(space .. 'REVELATION' .. space .. '3' .. space .. ':' .. space .. '17' .. space .. dash .. space .. '18' .. space, V[1].reference))
    end
    assert(M.FirstDifference('you' .. space .. 'are rich', 'you are rich') == nil)
  end
end)

test("Unicode single-character insertion and selection replacements", function()
  assert(M.InsertedCharacters('word', 'word\226\128\153') == 1)
  assert(M.InsertedCharacters('xxx', '\226\128\156') == 1)
  assert(M.InsertedCharacters('xxx', 'a\226\128\153') == 2)
  assert(M.InsertedCharacters('abc', 'axc') == 1)
  assert(M.InsertedCharacters('abc', 'abc') == 0)
  assert(M.InsertedCharacters('abc', '') == 0)
end)

test("interrupted ordinary review settles on completion turn", function()
  local s = M.New(0, #V)
  for t = 0, 4 do M.Begin(s, t); complete(s) end
  M.Begin(s, 5)
  M.Answer(s, V, V[1].reference, 6)
  local r
  for _, section in ipairs(V[1].sections) do r = M.Answer(s, V, section, 6) end
  assert(r.clean and s.clearedTurn == 6 and s.lessons[1].due == 8)
  assert(not M.Begin(s, 6))
end)

test("skipped examination boundary catches up and preserves pending order", function()
  local s = M.New(0, #V)
  for t = 0, 4 do M.Begin(s, t); complete(s) end
  local session = M.Begin(s, 11)
  assert(session.exam and #session.queue == 5 and session.queue[1] == 2)
  local encoded = M.Encode(s)
  s = assert(M.Decode(encoded, V))
  assert(M.Begin(s, 20).turn == 11)
  for n = 1, 5 do
    local id = s.session.queue[1]
    M.Answer(s, V, V[id].reference, 20)
    for _, section in ipairs(V[id].sections) do M.Answer(s, V, section, 20) end
  end
  assert(s.clearedTurn == 20 and s.lastExamTurn == 11)
  assert(M.Begin(s, 20).exam and #s.session.queue == 5)
  for n = 1, 5 do complete(s) end
  assert(not M.Begin(s, 20))
end)

test("legacy v1 progress migrates without changing pending state", function()
  local legacy = '1,37,-1,-1,1,37,0,1,3,2,1,1,5,0,0,37,1,0,0,38,0,0,0,39,0,0,0,40,0,0,0,41,0'
  local s = assert(M.Decode(legacy, V))
  assert(s.session.phase == 'section' and s.session.section == 2 and s.session.assisted)
  assert(s.lessons[1].failures == 1 and s.rewardTurn == -1)
  local encoded = M.Encode(s)
  assert(encoded:sub(1,2) == '2,' and M.Encode(assert(M.Decode(encoded, V))) == encoded)
end)

test("corrupt numeric payloads fail without throwing", function()
  local s = M.New(0, #V); M.Begin(s, 0)
  local encoded = M.Encode(s)
  for cut = 0, #encoded - 1 do
    local ok = pcall(M.Decode, encoded:sub(1, cut), V)
    assert(ok, cut)
  end
  for _, corrupt in ipairs({
    encoded:gsub('^2,0,%-1,%-1,%-1', '2,0,-2,-1,-1'),
    encoded:gsub('^2,0,%-1,%-1,%-1', '2,0,-1,9,-1'),
    '1,0,-1,-1,1,0,0,0,1,1,1,1,5,0,0,0,0,0,0,1,0,0,0,2,0,0,0,3,0,0,0,4,0',
    '1,0,-1,-1,1,0,0,1,2,2,1,1,5,0,0,0,0,0,0,1,0,0,0,2,0,0,0,3,0,0,0,4,0',
    string.rep('1,', 3000), '2,0,-1,-1,-1,0,5,999999999999999999999999999,0,0,0'
  }) do
    local ok, decoded = pcall(M.Decode, corrupt, V)
    assert(ok and not decoded, corrupt)
  end
end)
test("failure details locate words, letters, omissions and word order", function()
  local d = M.DifferenceDetails('you are wreched', 'you are wretched')
  assert(d.word == 3 and d.kind == 'word' and d.actual == 'wreched' and d.expected == 'wretched')
  assert(d.letter == 4 and d.expectedLetter == 't' and d.actualLetter == 'c')
  d = M.DifferenceDetails('you rich', 'you are rich')
  assert(d.kind == 'missing' and d.word == 2 and d.expected == 'are' and d.part == 'you are rich')
  d = M.DifferenceDetails('you are very rich', 'you are rich')
  assert(d.kind == 'extra' and d.word == 3 and d.actual == 'very')
  d = M.DifferenceDetails('you rich are', 'you are rich')
  assert(d.kind == 'order' and d.word == 2 and d.expectedNext == 'rich' and d.actualNext == 'are')
  d = M.DifferenceDetails('you are', 'you are rich')
  assert(d.kind == 'missing' and d.word == 3 and not d.actual)
  d = M.DifferenceDetails('you are rich now', 'you are rich')
  assert(d.kind == 'extra' and d.word == 4 and not d.expected)
  d = M.DifferenceDetails('ric', 'rich')
  assert(d.letter == 4 and d.actualLetter == '' and d.expectedLetter == 'h')
  d = M.DifferenceDetails('richh', 'rich')
  assert(d.letter == 5 and d.actualLetter == 'h' and d.expectedLetter == '')
  assert(not M.DifferenceDetails('YOU are, rich!', 'you are rich'))
  assert(M.FirstDifference('you rich', 'you are rich') == 2)
end)

test("detailed errors retain the failed section and preserve assisted restart saves", function()
  local s = M.New(0, #V); M.Begin(s, 0); M.BeginRecall(s)
  local r = M.Answer(s, V, 'wrong reference')
  assert(r.expectedReference == V[1].reference and not r.detail)
  M.Answer(s, V, V[1].reference); M.Answer(s, V, V[1].sections[1])
  r = M.Answer(s, V, 'wrong')
  assert(r.kind == 'wrong' and r.section == 2 and r.detail.expected == 'but')
  assert(r.difference == 1 and s.session.phase == 'reference' and s.session.section == 1)
  assert(s.session.assisted and s.lessons[1].failures == 2)
  assert(not complete(s).clean)
  assert(M.Encode(assert(M.Decode(M.Encode(s), V))) == M.Encode(s))
end)
test("masked sections retain correct context around every kind of mistake", function()
  assert(M.MaskedSection('You are ricg.', 'You are rich.') == 'You are ____.')
  assert(M.MaskedSection('You rich.', 'You are rich.') == 'You ____ rich.')
  assert(M.MaskedSection('You are very rich.', 'You are rich.') == 'You are ____ rich.')
  assert(M.MaskedSection('You rich are.', 'You are rich.') == 'You ____ ____.')
  assert(M.MaskedSection('One too three five sax.', 'One two three four five six.') == 'One ____ three ____ five ____.')
  assert(M.MaskedSection('the gate', 'The the gate.') == 'The ____ gate.')
  assert(M.MaskedSection('', 'You are rich.') == '____ ____ ____.')
  assert(M.MaskedSection('now you are rich', 'You are rich.') == '____ You are rich.')
  assert(M.MaskedSection('you are rich now', 'You are rich.') == 'You are rich. ____')
  assert(M.MaskedSection('you are rich', 'You are rich.') == 'You are rich.')
  assert(M.MaskedSection("dont forget", "Don't forget.") == "Don't forget.")
  assert(M.MaskedSection('bad forget', "Don't forget.") == '____ forget.')
  local original = V[1].sections[1]
  assert(M.MaskedSection('You say I am ricg I have acquired wealth and do not need a thing', original)
    == [=[You say, 'I am ____; I have acquired wealth and do not need a thing.']=])
  assert(not M.MaskedSection('[COLOR_RED] wrong', original):find('[COLOR_RED]', 1, true))
end)
return tests
