--!strict
-- Executed against the real Luau modules by scripts/test.mjs.
local passed = 0
local failures = {}
local function test(name, callback)
  local ok, problem = pcall(callback)
  if not ok then table.insert(failures, name .. ": " .. tostring(problem)); print("FAIL", name, tostring(problem)); return end
  passed += 1
  print("PASS", name)
end
local function equal(actual, expected)
  assert(actual == expected, `expected {tostring(expected)}, got {tostring(actual)}`)
end

test("IDs retain precision and normalize leading zeros", function()
  equal(Ids.propertyId("rbxassetid://0009007199254740993"), "9007199254740993")
end)
test("asset URLs normalize without matching arbitrary hosts", function()
  equal(Ids.propertyId("https://www.roblox.com/asset/?id=123&version=2"), "123")
  equal(Ids.propertyId("https://create.roblox.com/store/asset/123/Example"), "123")
  equal(Ids.propertyId("https://evil.example/?id=123"), nil)
  equal(Ids.propertyId("rbxasset://textures/test123.png"), nil)
end)
test("pasted errors extract only asset references and deduplicate", function()
  local ids = Ids.extract("12:04:33 failed asset rbxassetid://123; https://assetdelivery.roblox.com/v1/asset?id=456; rbxassetid://123")
  equal(#ids, 2)
  equal(ids[1], "123")
  equal(ids[2], "456")
end)
test("invalid and ambiguous replacement input is rejected", function()
  equal(#Ids.extract(""), 0)
  equal(#Ids.extract("0"), 0)
  equal(Ids.single("rbxassetid://123 rbxassetid://456"), nil)
  equal(Ids.single("123"), "123")
end)
test("plain permission errors identify the asset without capturing timestamps", function()
  local ids = Ids.extract("12:30:45 Experience doesn't have access permission to use asset id 123.")
  equal(#ids, 1)
  equal(ids[1], "123")
end)
test("sound permission errors and token boundaries", function()
  local ids = Ids.extract("12:30:45 Experience doesn't have permissions for sound asset 456.")
  equal(#ids, 1); equal(ids[1], "456")
  equal(#Ids.extract("asset id 123abc"), 0)
end)
test("long script scans stop at the first cancelled checkpoint", function()
  local checkpoints = 0
  local hits = Ids.scriptMatches(string.rep("return 123\n", 10000), "123", function()
    checkpoints += 1
    return false
  end)
  equal(checkpoints, 1)
  equal(#hits, 0)
end)
test("script matching respects token boundaries and reports lines", function()
  local hits = Ids.scriptMatches('local a = 123\nlocal b="rbxassetid://123"\nlocal c=1234\nlocal var123=0\nlocal d=1.123\nlocal e=123e4', "123")
  equal(#hits, 2)
  equal(hits[2].line, 2)
end)

-- Minimal instance adapter: scans and edits use real production code; no Roblox VM here.
local function object(class, name, fields, children)
  local value = fields or {}
  value.ClassName = class
  value.Name = name
  value.children = children or {}
  value.Parent = true
  function value:IsA(wanted)
    return self.ClassName == wanted or (wanted == "LuaSourceContainer" and self.ClassName == "ModuleScript")
  end
  function value:GetChildren() return self.children end
  function value:GetFullName() return "Fixture." .. self.Name end
  function value:IsDescendantOf(_) return self.Parent ~= nil end
  return value
end
local function scan(roots, id, cancelled, reader)
  return Scanner.scan(roots, id, {
    cancelled = cancelled or function() return false end,
    yield = function() end,
    source = reader or function(instance) return instance.Source end,
    progress = function() end,
  })
end
test("scan finds properties and script references without substring matches", function()
  local sound = object("Sound", "Duplicate", {SoundId="rbxassetid://123"})
  local other = object("Sound", "Duplicate", {SoundId="rbxassetid://1234"})
  local source = object("ModuleScript", "Source", {Source="return 123"})
  local report = scan({object("Folder", "Root", {}, {sound, other, source})}, "123")
  equal(#report.results, 2)
  equal(report.results[1].instance, sound)
  equal(report.results[2].kind, "script")
  equal(sound.SoundId, "rbxassetid://123")
end)
test("overlapping roots deduplicate and inventory excludes script numbers", function()
  local sound = object("Sound", "Sound", {SoundId="rbxassetid://123"})
  local root = object("Folder", "Root", {}, {sound, object("ModuleScript", "Script", {Source="return 999"})})
  local report = scan({root, sound}, nil)
  equal(#report.results, 1)
  equal(report.results[1].id, "123")
end)
test("unreadable scripts are reported", function()
  local report = scan({object("ModuleScript", "Private")}, "123", nil, function() error("denied") end)
  equal(#report.warnings, 1)
end)
test("cancel stops without publishing partial results", function()
  local report = scan({object("Sound", "Sound", {SoundId="123"})}, "123", function() return true end)
  equal(report.cancelled, true)
  equal(#report.results, 0)
end)
test("MeshPart mesh references are searchable but read-only", function()
  local report = scan({object("MeshPart", "Mesh", {MeshId="123", TextureID="456"})}, "123")
  equal(#report.results, 1)
  equal(report.results[1].writable, false)
end)

local function history(allow)
  local h = {begun=0, finished=0}
  function h:TryBeginRecording(_) self.begun += 1; return if allow then "recording" else nil end
  function h:FinishRecording(_, _) self.finished += 1 end
  return h
end
local function planFor(target)
  return Replacement.plan(scan({target}, "123").results, "456")
end
local function apply(plan, h, running, writer)
  return Replacement.apply(plan, {
    history=h, commit="commit", cancel="cancel", running=function() return running or false end,
    alive=function(instance) return instance.Parent ~= nil end,
    write=writer or function(instance, property, value) instance[property] = value end,
  })
end
test("replacement previews then applies a single undo recording", function()
  local sound = object("Sound", "Sound", {SoundId="rbxassetid://123"})
  local plan = planFor(sound)
  equal(sound.SoundId, "rbxassetid://123")
  equal(plan[1].after, "rbxassetid://456")
  local h = history(true)
  local report = apply(plan, h)
  equal(sound.SoundId, "rbxassetid://456")
  equal(report.applied, 1)
  equal(h.begun, 1)
  equal(h.finished, 1)
end)
test("stale or deleted targets are skipped", function()
  local sound = object("Sound", "Sound", {SoundId="123"})
  local plan = planFor(sound)
  sound.SoundId = "789"
  equal(apply(plan, history(true)).skipped, 1)
  equal(sound.SoundId, "789")
  sound.Parent = nil
  equal(apply(plan, history(true)).skipped, 1)
end)
test("recording refusal and play mode cause zero writes", function()
  local sound = object("Sound", "Sound", {SoundId="123"})
  equal(apply(planFor(sound), history(false)).applied, 0)
  equal(apply(planFor(sound), history(true), true).applied, 0)
  equal(sound.SoundId, "123")
end)
test("write failures are reported and the recording always closes", function()
  local sound = object("Sound", "Sound", {SoundId="123"})
  local h = history(true)
  local report = apply(planFor(sound), h, false, function() error("read-only") end)
  equal(report.failed, 1)
  equal(h.finished, 1)
end)
test("plans never edit scripts or read-only properties", function()
  local report = scan({object("ModuleScript", "Code", {Source="return 123"}), object("MeshPart", "Mesh", {MeshId="123"})}, "123")
  equal(#Replacement.plan(report.results, "456"), 0)
end)
local function controllerFixture()
  local jobs = {}
  local current = {SoundId="123"}
  local target = object("Sound", "Sound", current)
  local services = {
    roots=function(selected) return if selected then {} else {target} end,
    spawn=function(callback) table.insert(jobs, callback) end,
    scanOptions={cancelled=function() return false end, yield=function() end, source=function(i) return i.Source end, progress=function() end},
    replacement={history=history(true), commit="commit", cancel="cancel", running=function() return false end, alive=function() return true end, write=function(i, p, v) i[p]=v end},
    open=function() end,
  }
  local renders = 0
  local controller = Controller.new(services, function() renders += 1 end)
  return controller, jobs, target, function() return renders end
end
test("controller resolves multiple pasted IDs before scanning", function()
  local c, jobs = controllerFixture()
  c:search("rbxassetid://123 rbxassetid://456")
  equal(#c.state.choices, 2)
  equal(#jobs, 0)
  c:search("123")
  equal(c.state.mode, "scanning")
  jobs[1]()
  equal(#c.state.results, 1)
end)
test("controller requires preview before apply and invalidates it on back", function()
  local c, jobs, target = controllerFixture()
  c:search("123"); jobs[1]()
  c:apply()
  equal(target.SoundId, "123")
  c:preview("456")
  equal(c.state.mode, "preview")
  equal(#c.state.changes, 1)
  c:back()
  c:apply()
  equal(target.SoundId, "123")
  c:preview("456"); c:apply()
  equal(target.SoundId, "rbxassetid://456")
  equal(c.state.summary.applied, 1)
end)
test("cancelled and disposed scans cannot republish results", function()
  local c, jobs, _, renders = controllerFixture()
  c:search("123"); c:clear(); jobs[1]()
  equal(#c.state.results, 0)
  c:search("123")
  c:destroy()
  local count = renders()
  jobs[2]()
  equal(renders(), count)
  equal(#c.state.results, 0)
end)
test("selected scope without a selection cannot scan the whole place", function()
  local c, jobs = controllerFixture()
  c.state.selectedScope = true
  c:search("123")
  equal(#jobs, 0)
  equal(#c.state.results, 0)
end)
test("filtered-out results do not enter a replacement preview", function()
  local c, jobs = controllerFixture()
  c:search("123"); jobs[1]()
  c.state.filter = "does not exist"
  c:preview("456")
  equal(#c.state.changes, 0)
end)
print(`{passed} tests passed`)
assert(#failures == 0, table.concat(failures, "\n"))
