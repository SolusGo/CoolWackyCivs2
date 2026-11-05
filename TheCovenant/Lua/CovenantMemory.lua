-- Pure Lua 5.1 learning engine; no Civ API calls. Shared by the game UI and tests.
CovenantMemory = {}
local M = CovenantMemory
local intervals = {1, 2, 4, 8, 12}
local phases = {study = 1, reference = 2, section = 3}
local phaseNames = {"study", "reference", "section"}

local function whitespace(text)
  -- Lua 5.1 %s is byte/locale based. Handle the common Unicode spaces explicitly.
  text = text:gsub("\194\160", " "):gsub("\226\128[\128-\138]", " ")
  return text:gsub("\226\128\175", " "):gsub("\227\128\128", " ")
end

function M.Normalize(text)
  text = string.lower(whitespace(tostring(text or "")))
  text = text:gsub("\226\128\152", "'"):gsub("\226\128\153", "'")
  text = text:gsub("\226\128\156", '"'):gsub("\226\128\157", '"')
  text = text:gsub("\226\128\147", "-"):gsub("\226\128\148", "-")
  text = text:gsub("'", ""):gsub("[^a-z0-9%s]", " ")
  return (text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.ReferenceMatches(answer, expected)
  local function ref(text)
    if type(text) ~= "string" then return nil end
    text = whitespace(text):lower():gsub("\226\128\147", "-"):gsub("\226\128\148", "-")
    local book, chapter, first, tail = text:match("^%s*([a-z]+)%s*(%d+)%s*:%s*(%d+)(.-)%s*$")
    if not book then return nil end
    local last
    if tail:match("^%s*$") then
      last = false
    else
      last = tail:match("^%s*%-%s*(%d+)%s*$")
      if not last then return nil end
    end
    local function number(s)
      -- Reject zero, leading zeroes, split digits and unreasonably large numbers.
      if #s > 3 or not s:match("^[1-9]%d*$") then return nil end
      return tonumber(s)
    end
    chapter, first, last = number(chapter), number(first), last and number(last) or false
    if not chapter or not first or (tail:find("%-%s*") and not last)
        or (last and last < first) then return nil end
    return {book, chapter, first, last}
  end
  local a, b = ref(answer), ref(expected)
  if not a or not b then return false end
  for i = 1, 4 do if a[i] ~= b[i] then return false end end
  return true
end

function M.FirstDifference(answer, expected)
  local a, b = {}, {}
  for word in M.Normalize(answer):gmatch("%S+") do a[#a + 1] = word end
  for word in M.Normalize(expected):gmatch("%S+") do b[#b + 1] = word end
  for i = 1, math.max(#a, #b) do
    if a[i] ~= b[i] then return i end
  end
  return nil
end

function M.WordCount(text)
  local count = 0
  for _ in M.Normalize(text):gmatch("%S+") do count = count + 1 end
  return count
end

function M.InsertedCharacters(before, after)
  -- Size of the changed insertion, including a paste over an existing selection.
  local prefix = 0
  while prefix < #before and prefix < #after
      and before:sub(prefix + 1, prefix + 1) == after:sub(prefix + 1, prefix + 1) do
    prefix = prefix + 1
  end
  local suffix = 0
  while suffix < #before - prefix and suffix < #after - prefix
      and before:sub(#before - suffix, #before - suffix) == after:sub(#after - suffix, #after - suffix) do
    suffix = suffix + 1
  end
  local inserted = after:sub(prefix + 1, #after - suffix)
  -- Count UTF-8 characters, not bytes (a smart quote is one legitimate edit).
  local _, count = inserted:gsub("[^\128-\191]", "")
  return count
end

function M.New(turn, count)
  local s = {startTurn = turn, clearedTurn = -1, lastExamTurn = -1, rewardTurn = -1, lessons = {}}
  for i = 1, count do
    s.lessons[i] = {passes = 0, clean = 0, due = turn + i - 1, failures = 0}
  end
  return s
end

function M.Mastered(s)
  local count = 0
  for _, lesson in ipairs(s.lessons) do
    if lesson.clean >= 3 then count = count + 1 end
  end
  return count
end

local function prepare(s)
  local lesson = s.lessons[s.session.queue[1]]
  s.session.assisted = lesson.passes == 0
  s.session.phase = s.session.assisted and "study" or "reference"
  s.session.section = 1
end

function M.Begin(s, turn)
  if s.session then return s.session end
  local queue, allSeen = {}, true
  for _, lesson in ipairs(s.lessons) do
    if lesson.passes == 0 then allSeen = false end
  end
  local examTurn = s.startTurn + math.floor((turn - s.startTurn + 1) / 10) * 10 - 1
  -- An interrupted/skipped boundary remains due; never discard a pending queue.
  local exam = allSeen and examTurn >= s.startTurn + 9 and s.lastExamTurn < examTurn
  if not exam and s.clearedTurn >= turn then return nil end
  if exam then
    -- Rotate the order so the exam is not always learned as the same five-item list.
    local first = math.floor((turn - s.startTurn + 1) / 10) % #s.lessons
    for n = 1, #s.lessons do queue[n] = (first + n - 1) % #s.lessons + 1 end
  else
    -- Introduce all five first, then review the most overdue item. At most one
    -- ordinary passage per turn, even when several are overdue.
    local chosen
    for i, lesson in ipairs(s.lessons) do
      if lesson.passes == 0 then chosen = i; break end
    end
    if not chosen then
      for i, lesson in ipairs(s.lessons) do
        if lesson.due <= turn and (not chosen or lesson.due < s.lessons[chosen].due) then
          chosen = i
        end
      end
    end
    if chosen then queue[1] = chosen end
  end
  if #queue == 0 then return nil end
  s.session = {turn = turn, exam = exam, queue = queue}
  prepare(s)
  return s.session
end

function M.Study(s)
  assert(s.session, "No active memory check")
  s.session.assisted = true
  s.session.phase = "study"
  s.session.section = 1
  s.lessons[s.session.queue[1]].clean = 0
end

function M.BeginRecall(s)
  assert(s.session and s.session.phase == "study", "Study is not active")
  s.session.phase = "reference"
  s.session.section = 1
end

function M.Answer(s, verses, answer, turn)
  local session = assert(s.session, "No active memory check")
  turn = math.max(turn or session.turn, session.turn)
  assert(session.phase ~= "study", "Hide the passage before attempting recall")
  local id = session.queue[1]
  local verse, lesson = verses[id], s.lessons[id]
  local correct, difference
  if session.phase == "reference" then
    correct = M.ReferenceMatches(answer, verse.reference)
  else
    difference = M.FirstDifference(answer, verse.sections[session.section])
    correct = difference == nil
  end
  if not correct then
    lesson.failures = lesson.failures + 1
    lesson.clean = 0
    session.assisted = true
    session.phase = "reference"
    session.section = 1
    return {kind = "wrong", difference = difference}
  end
  if session.phase == "reference" then
    session.phase = "section"
    return {kind = "next"}
  end
  if session.section < #verse.sections then
    session.section = session.section + 1
    return {kind = "next"}
  end
  lesson.passes = lesson.passes + 1
  local clean = not session.assisted
  lesson.clean = clean and (lesson.clean + 1) or 0
  local interval = intervals[math.min(lesson.clean + 1, #intervals)]
  lesson.due = turn + interval
  local result = {kind = "pass", id = id, clean = clean, exam = session.exam}
  table.remove(session.queue, 1)
  if #session.queue == 0 then
    s.clearedTurn = turn
    if session.exam then s.lastExamTurn = session.turn end
    s.session = nil
    result.kind = "complete"
  else
    prepare(s)
  end
  return result
end

-- Numeric serialization only. Never execute text from a save as Lua.
-- The pending queue, assistance and section are journalled after every action.
function M.Encode(s)
  local a = {2, s.startTurn, s.clearedTurn, s.lastExamTurn, s.rewardTurn or -1}
  local session = s.session
  local function put(n) a[#a + 1] = n end
  put(session and 1 or 0)
  if session then
    put(session.turn); put(session.exam and 1 or 0); put(session.assisted and 1 or 0)
    put(phases[session.phase]); put(session.section); put(#session.queue)
    for _, id in ipairs(session.queue) do put(id) end
  end
  put(#s.lessons)
  for _, l in ipairs(s.lessons) do
    put(l.passes); put(l.clean); put(l.due); put(l.failures)
  end
  return table.concat(a, ",")
end

function M.Decode(text, verses)
  if type(text) ~= "string" or #text > 4096 or not text:match("^%-?%d[%d,%-]*$") then return nil end
  local a = {}
  for token in (text .. ","):gmatch("(.-),") do
    if not token:match("^%-?%d+$") then return nil end
    local n = tonumber(token)
    if not n or math.abs(n) > 100000000 then return nil end
    a[#a + 1] = n
  end
  local p = 0
  local function take() p = p + 1; return a[p] end
  local version = take()
  if version ~= 1 and version ~= 2 then return nil end
  local s = {startTurn = take(), clearedTurn = take(), lastExamTurn = take(), lessons = {}}
  s.rewardTurn = version == 2 and take() or -1
  if not s.lastExamTurn or not s.rewardTurn or s.startTurn < 0 or s.clearedTurn < -1
      or s.lastExamTurn < -1 or s.rewardTurn < -1
      or (s.clearedTurn ~= -1 and s.clearedTurn < s.startTurn)
      or (s.lastExamTurn ~= -1 and (s.lastExamTurn < s.startTurn + 9 or s.lastExamTurn > s.clearedTurn))
      then return nil end
  local hasSession = take()
  if hasSession ~= 0 and hasSession ~= 1 then return nil end
  if hasSession == 1 then
    local session = {turn = take(), queue = {}}
    local exam, assisted, phase, section, count = take(), take(), take(), take(), take()
    if not count or count < 1 or count > #verses or not phaseNames[phase]
        or (exam ~= 0 and exam ~= 1) or (assisted ~= 0 and assisted ~= 1)
        or session.turn < s.startTurn then return nil end
    session.exam, session.assisted = exam == 1, assisted == 1
    session.phase, session.section = phaseNames[phase], section
    if (not session.exam and count ~= 1) or (session.phase == "study" and not session.assisted)
        or (session.phase ~= "section" and section ~= 1) then return nil end
    local seen = {}
    for i = 1, count do
      local id = take()
      if not id or not verses[id] or seen[id] then return nil end
      seen[id] = true; session.queue[i] = id
    end
    if section < 1 or section > #verses[session.queue[1]].sections then return nil end
    s.session = session
  end
  if take() ~= #verses then return nil end
  for i = 1, #verses do
    local passes, clean, due, failures = take(), take(), take(), take()
    if not failures or passes < 0 or clean < 0 or clean > passes
        or due < s.startTurn or failures < 0 then return nil end
    s.lessons[i] = {passes = passes, clean = clean, due = due, failures = failures}
  end
  if p ~= #a then return nil end
  if s.session then
    local lesson = s.lessons[s.session.queue[1]]
    if (lesson.passes == 0 and not s.session.assisted)
        or (s.session.assisted and lesson.clean ~= 0)
        or (s.session.exam and s.session.turn < s.startTurn + 9) then return nil end
    if (not s.session.exam and s.session.turn <= s.clearedTurn)
        or (s.session.exam and s.session.turn <= s.lastExamTurn) then return nil end
    if s.session.exam then
      for _, id in ipairs(s.session.queue) do
        if s.lessons[id].passes == 0 then return nil end
      end
    end
  end
  return s
end
