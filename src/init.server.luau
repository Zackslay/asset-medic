--!strict
local Controller = require(script.Controller)
local View = require(script.View)
local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")

local toolbar = plugin:CreateToolbar("Asset Medic")
local toggle = toolbar:CreateButton("AssetMedic.Toggle", "Find and safely replace asset references", "", "Asset Medic")
toggle.ClickableWhenViewportHidden = true
local widget = plugin:CreateDockWidgetPluginGuiAsync("AssetMedic.Main.v1", DockWidgetPluginGuiInfo.new(
  Enum.InitialDockState.Right, false, false, 460, 720, 360, 500
))
widget.Title = "Asset Medic"
local connections: {RBXScriptConnection} = {}
local view: View.Handle? = nil
local controller = Controller.new({
  roots=function(selected)
    if selected then return Selection:Get() end
    -- Only place-owned services: exclude CoreGui, plugin UI, and other Studio internals.
    local roots: {Instance} = {}
    for _, name in {"Workspace", "Players", "Lighting", "MaterialService", "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Teams", "TextChatService"} do
      table.insert(roots, game:GetService(name))
    end
    return roots
  end,
  spawn=function(callback) task.spawn(callback) end,
  scanOptions={
    cancelled=function() return false end,
    yield=function() task.wait() end,
    source=function(instance) return ScriptEditorService:GetEditorSource(instance :: LuaSourceContainer) end,
    progress=function() end,
  },
  replacement={
    history=ChangeHistoryService,
    commit=Enum.FinishRecordingOperation.Commit,
    cancel=Enum.FinishRecordingOperation.Cancel,
    running=function() return RunService:IsRunning() end,
    alive=function(instance) return instance:IsDescendantOf(game) end,
    write=function(instance, property, value) (instance :: any)[property] = value end,
  },
  open=function(result)
    if not result.instance:IsDescendantOf(game) then error("This object no longer exists in the place. Scan again.") end
    if result.kind == "script" then
      local source = result.instance :: LuaSourceContainer
      local opened = ScriptEditorService:OpenScriptDocumentAsync(source)
      if not opened then error("Studio could not open this script.") end
      local document = ScriptEditorService:FindScriptDocument(source)
      if document then
        local line = math.clamp(result.line or 1, 1, document:GetLineCount())
        document:RequestSetSelectionAsync(line, 1, line, 1)
      end
    else Selection:Set({result.instance}) end
  end,
}, function(state)
  if view then view.render(state, {}) end
end)

local function refresh()
  if view then view.render(controller.state, controller:visible()) end
end
controller.render = function() refresh() end
view = View.mount(widget, {
  search=function(value) controller:search(value) end,
  inventory=function() controller:inventory() end,
  scope=function()
    if controller.state.mode == "scanning" or controller.state.mode == "preview" then return end
    controller:clear()
    controller.state.selectedScope = not controller.state.selectedScope
    refresh()
  end,
  clear=function() controller:clear() end,
  filter=function(value) controller.state.filter=value; controller.state.page=1; refresh() end,
  category=function(value) controller.state.category=value; controller.state.page=1; refresh() end,
  toggle=function(result) controller.state.checked[result] = not controller.state.checked[result]; refresh() end,
  selectVisible=function()
    local visible = controller:visible()
    local allChecked = true
    for _, result in visible do if result.writable and not controller.state.checked[result] then allChecked=false; break end end
    for _, result in visible do if result.writable then controller.state.checked[result]=not allChecked end end
    refresh()
  end,
  open=function(result)
    task.spawn(function()
      local ok, reason = pcall(controller.services.open, result)
      if not ok then controller.state.message = tostring(reason); refresh() end
    end)
  end,
  preview=function(value) controller:preview(value) end,
  back=function() controller:back() end,
  apply=function() controller:apply() end,
  page=function(value) controller.state.page=math.max(1, value); refresh() end,
})

table.insert(connections, toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end))
table.insert(connections, widget:GetPropertyChangedSignal("Enabled"):Connect(function()
  toggle:SetActive(widget.Enabled)
  if not widget.Enabled then controller:clear() end
end))
table.insert(connections, plugin.Unloading:Connect(function()
  controller:destroy()
  for _, connection in connections do connection:Disconnect() end
  if view then view.destroy(); view=nil end
  widget:Destroy(); toolbar:Destroy()
end))
toggle:SetActive(widget.Enabled)
refresh()
