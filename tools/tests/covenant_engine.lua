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
    assert(M.Begin(s, turn).phase == 'reference')
    assert(complete(s).clean)
    assert(s.lessons[1].clean == clean and s.lessons[1].due == turn + interval)
    turn = turn + interval
  end
  assert(M.Mastered(s) == 1)
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
  assert(not M.Decode(encoded:gsub('^1,', '2,'), V))
end)

test("paste detection covers insertion and replacement selections", function()
  assert(M.InsertedCharacters('', 'a') == 1)
  assert(M.InsertedCharacters('abc', 'abdc') == 1)
  assert(M.InsertedCharacters('abc', 'ac') == 0)
  assert(M.InsertedCharacters('', 'full pasted verse') > 1)
  assert(M.InsertedCharacters('xxx', 'gold refined') > 1)
  assert(M.InsertedCharacters('xx', 'ab') > 1)
end)
return tests
