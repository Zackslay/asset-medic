--!strict
-- Run in a disposable Studio place, with AssetMedicSource in ServerStorage.
return function()
  local View = require(game.ServerStorage.AssetMedicSource.View)
  local gui = Instance.new("ScreenGui")
  gui.Name = "AssetMedicUITest"
  gui.Parent = game:GetService("CoreGui")
  local host = Instance.new("Frame")
  host.Size = UDim2.fromOffset(360, 500)
  host.Parent = gui
  local noop = function() end
  local view = View.mount(host :: any, {
    search=noop, inventory=noop, scope=noop, clear=noop, filter=noop,
    category=noop, toggle=noop, selectVisible=noop, open=noop,
    preview=noop, back=noop, apply=noop, page=noop,
  })
  local failures = {}
  local function check(name, callback)
    local ok, reason = pcall(callback)
    if not ok then table.insert(failures, name .. ": " .. tostring(reason)) end
  end
  local function settle() task.wait(); task.wait() end
  local state = {
    mode="preview", selectedScope=false, query="", choices={}, results={}, checked={},
    changes={{path="Workspace." .. string.rep("LongFolderName.", 30) .. "Decal", property="Texture",
      before="https://www.roblox.com/asset/?id=123&label=" .. string.rep("long-value-", 25),
      after="rbxassetid://456"}},
    warnings={}, filter="", category="All", page=1, message="Review one change", visited=0,
  }
  local root = host.AssetMedic
  local results = root.References
  check("long preview values remain readable at minimum size", function()
    view.render(state, {})
    settle()
    local card = results:FindFirstChild("Item")
    assert(card, "Missing preview card")
    for _,child in card:GetChildren() do
      if child:IsA("TextLabel") then
        assert(child.TextFits, "Clipped preview text: " .. child.Text:sub(1, 45))
        assert(child.AbsolutePosition.Y + child.AbsoluteSize.Y <= card.AbsolutePosition.Y + card.AbsoluteSize.Y + 1,
          "Preview text extends beyond its card")
      end
    end
  end)
  local visible = {}
  for index = 1, 61 do
    table.insert(visible, {id=tostring(index), category="Image", path="Workspace.Decal" .. index,
      property="Texture", class="Decal", before="rbxassetid://123", writable=true, kind="property"})
  end
  state.mode="results"; state.results=visible
  check("changing pages starts at top", function()
    view.render(state, visible); settle()
    results.CanvasPosition = Vector2.new(0, 180); settle()
    assert(results.CanvasPosition.Y > 0, "Scroll setup failed")
    state.page=2
    view.render(state, visible); settle()
    assert(results.CanvasPosition.Y == 0, "New page retained old scroll position")
  end)
  check("same-page selection preserves scroll", function()
    results.CanvasPosition = Vector2.new(0, 120); settle()
    state.checked[visible[31]]=true
    view.render(state, visible); settle()
    assert(results.CanvasPosition.Y == 120, "Selection unexpectedly reset scroll")
  end)
  view.destroy(); gui:Destroy()
  assert(#failures == 0, table.concat(failures, "\n"))
  return "UI passed: long preview at 360x500, page reset, selection scroll preservation"
end
