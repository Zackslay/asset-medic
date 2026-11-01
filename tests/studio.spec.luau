--!strict
-- Run only in the generated, disposable AssetMedic-TestPlace, from the Command Bar:
-- require(game.ServerStorage.AssetMedicStudioSpec)()
return function()
  local ServerStorage = game:GetService("ServerStorage")
  local source = ServerStorage:FindFirstChild("AssetMedicSource") :: Instance
  local Scanner = require(source:FindFirstChild("Scanner") :: ModuleScript)
  local Properties = require(source:FindFirstChild("Properties") :: ModuleScript)
  local Replacement = require(source:FindFirstChild("Replacement") :: ModuleScript)
  local View = require(source:FindFirstChild("View") :: ModuleScript)
  local ChangeHistoryService = game:GetService("ChangeHistoryService")
  local ScriptEditorService = game:GetService("ScriptEditorService")
  local root = Instance.new("Folder")
  root.Name = "AssetMedicDisposableFixture"
  local gui = Instance.new("ScreenGui")
  local view = nil
  local document = nil
  local output = {}
  local ok, problem = xpcall(function()
    root.Parent = ServerStorage
    local created = {}
    for _, definition in Properties do
      if not definition.writable then continue end
      local instance = Instance.new(definition.class)
      instance.Name = definition.class .. "_" .. definition.property
      local writable = pcall(function() (instance :: any)[definition.property] = "rbxassetid://123" end)
      assert(writable, `Expected writable property {definition.class}.{definition.property}`)
      instance.Parent = root
      table.insert(created, instance)
    end
    local scriptInstance = Instance.new("ModuleScript")
    scriptInstance.Source = "return 123"
    scriptInstance.Parent = root
    assert(ScriptEditorService:OpenScriptDocumentAsync(scriptInstance))
    document = ScriptEditorService:FindScriptDocument(scriptInstance)
    assert(document, "Expected open script document")
    ScriptEditorService:UpdateSourceAsync(scriptInstance, function() return "-- editor text\nreturn 123" end)
    local report = Scanner.scan({root}, "123", {
      cancelled=function() return false end, yield=function() task.wait() end,
      source=function(instance) return ScriptEditorService:GetEditorSource(instance) end,
      progress=function() end,
    })
    assert(#report.warnings == 0, table.concat(report.warnings, "\n"))
    assert(#report.results == #created + 1)
    local scriptHit = false
    for _, result in report.results do
      if result.kind == "script" then assert(result.line == 2); scriptHit = true end
    end
    assert(scriptHit)
    local plan = Replacement.plan(report.results, "456")
    assert(#plan == #created)
    local replaced = Replacement.apply(plan, {
      history=ChangeHistoryService, commit=Enum.FinishRecordingOperation.Commit, cancel=Enum.FinishRecordingOperation.Cancel,
      running=function() return game:GetService("RunService"):IsRunning() end,
      alive=function(instance) return instance:IsDescendantOf(root) end,
      write=function(instance, property, value) (instance :: any)[property] = value end,
    })
    assert(replaced.applied == #created and replaced.failed == 0, table.concat(replaced.messages, "\n"))
    ChangeHistoryService:Undo()
    for _, change in plan do assert((change.instance :: any)[change.property] == change.before) end
    ChangeHistoryService:Redo()
    for _, change in plan do assert((change.instance :: any)[change.property] == change.after) end
    assert(ScriptEditorService:GetEditorSource(scriptInstance) == "-- editor text\nreturn 123")
    table.insert(output, "Supported properties, current script text, batch replacement, undo and redo passed")
    -- Detached GUI validates UI API use without inserting UI into the place.
    local noop = function() end
    view = View.mount(gui, {
      search=noop, inventory=noop, scope=noop, clear=noop, filter=noop, category=noop,
      toggle=noop, open=noop, preview=noop, back=noop, apply=noop, page=noop, selectVisible=noop,
    })
    local state = {
      mode="results", selectedScope=false, query="123", choices={}, results=report.results,
      checked={}, changes={}, warnings={}, filter="", category="All", page=1, message="Fixture", visited=#created,
    }
    view.render(state, report.results)
    state.mode="preview"; state.changes=plan; view.render(state, {})
    table.insert(output, "UI results and preview rendering passed")
    -- Measurements are actual local Studio timings, not device-independent guarantees.
    local large = Instance.new("Folder")
    large.Parent = root
    for index = 1, 5000 do
      local sound = Instance.new("Sound"); sound.SoundId="rbxassetid://123"; sound.Parent=large
      if index % 200 == 0 then task.wait() end
    end
    local yields = 0
    local start = os.clock()
    local bigReport = Scanner.scan({large}, "123", {
      cancelled=function() return false end,
      yield=function() yields += 1; task.wait() end,
      source=function() return "" end, progress=function() end,
    })
    assert(#bigReport.results == 5000 and yields >= 25)
    table.insert(output, `5000 sounds: {os.clock() - start}s, {yields} yield points`)
  end, debug.traceback)
  if view then view.destroy() end
  if document then pcall(function() document:CloseAsync() end) end
  gui:Destroy(); root:Destroy()
  assert(ok, problem)
  print(table.concat(output, "\n"))
  return output
end
