--!strict
local Controller = require(script.Parent.Controller)
local Scanner = require(script.Parent.Scanner)

local View = {}
local PAGE_SIZE = 30
local categories = {"All", "Audio", "Animation", "Mesh", "Image", "Effect", "Script"}
export type Actions = {
  search: (string) -> (), inventory: () -> (), scope: () -> (), clear: () -> (),
  filter: (string) -> (), category: (string) -> (), toggle: (Scanner.Result) -> (),
  open: (Scanner.Result) -> (), preview: (string) -> (), back: () -> (), apply: () -> (),
  page: (number) -> (), selectVisible: () -> (),
}
export type Handle = {render: (Controller.State, {Scanner.Result}) -> (), destroy: () -> ()}

function View.mount(widget: DockWidgetPluginGui, actions: Actions): Handle
  local studio = settings().Studio
  local connections: {RBXScriptConnection} = {}
  local rowsConnections: {RBXScriptConnection} = {}
  local themed: {[Instance]: {[string]: Enum.StudioStyleGuideColor}} = {}
  local function color(instance: Instance, property: string, key: Enum.StudioStyleGuideColor)
    local entries = themed[instance] or {}
    entries[property] = key; themed[instance] = entries;
    (instance :: any)[property] = studio.Theme:GetColor(key)
  end
  local function connect(signal: RBXScriptSignal, callback: (...any) -> (), transient: boolean?)
    table.insert(if transient then rowsConnections else connections, signal:Connect(callback))
  end
  local function frame(parent: Instance, name: string): Frame
    local item = Instance.new("Frame")
    item.Name = name; item.BorderSizePixel = 0; item.BackgroundTransparency = 1; item.Parent = parent
    return item
  end
  local function label(parent: Instance, text: string, size: number?): TextLabel
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1; item.BorderSizePixel = 0
    item.Font = Enum.Font.SourceSans; item.TextSize = size or 15
    item.TextXAlignment = Enum.TextXAlignment.Left; item.TextYAlignment = Enum.TextYAlignment.Top
    item.TextWrapped = true; item.Text = text
    color(item, "TextColor3", Enum.StudioStyleGuideColor.MainText)
    item.Parent = parent
    return item
  end
  local function button(parent: Instance, text: string, callback: () -> (), transient: boolean?): TextButton
    local item = Instance.new("TextButton")
    item.Name = text; item.Text = text; item.Font = Enum.Font.SourceSansSemibold; item.TextSize = 15
    item.BorderSizePixel = 1; item.AutoButtonColor = true
    color(item, "BackgroundColor3", Enum.StudioStyleGuideColor.Button)
    color(item, "TextColor3", Enum.StudioStyleGuideColor.ButtonText)
    color(item, "BorderColor3", Enum.StudioStyleGuideColor.Border)
    item.Parent = parent
    connect(item.Activated, callback, transient)
    return item
  end
  local function input(parent: Instance, placeholder: string): TextBox
    local item = Instance.new("TextBox")
    item.Text = ""; item.PlaceholderText = placeholder; item.ClearTextOnFocus = false
    item.TextSize = 15; item.Font = Enum.Font.SourceSans
    item.TextXAlignment = Enum.TextXAlignment.Left; item.TextWrapped = true
    color(item, "BackgroundColor3", Enum.StudioStyleGuideColor.InputFieldBackground)
    color(item, "TextColor3", Enum.StudioStyleGuideColor.MainText)
    color(item, "PlaceholderColor3", Enum.StudioStyleGuideColor.DimmedText)
    color(item, "BorderColor3", Enum.StudioStyleGuideColor.Border)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8); padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 5); padding.PaddingBottom = UDim.new(0, 5); padding.Parent = item
    item.Parent = parent
    return item
  end
  local root = frame(widget, "AssetMedic")
  root.BackgroundTransparency = 0; root.Size = UDim2.fromScale(1, 1)
  color(root, "BackgroundColor3", Enum.StudioStyleGuideColor.MainBackground)
  local title = label(root, "ASSET MEDIC", 24)
  title.Font = Enum.Font.SourceSansBold; title.Position = UDim2.fromOffset(12, 10); title.Size = UDim2.new(1, -110, 0, 28)
  local version = label(root, "v0.1.0 · LOCAL", 12)
  version.Position = UDim2.new(1, -105, 0, 18); version.Size = UDim2.fromOffset(96, 20)
  local tagline = label(root, "Find the reference. Review the fix. Keep control.", 14)
  tagline.Position = UDim2.fromOffset(12, 40); tagline.Size = UDim2.new(1, -24, 0, 20)
  color(tagline, "TextColor3", Enum.StudioStyleGuideColor.DimmedText)
  local query = input(root, "Paste an asset ID, Roblox URL, or Output error…")
  query.Name = "AssetQuery"; query.MultiLine = true
  query.Position = UDim2.fromOffset(12, 66); query.Size = UDim2.new(1, -24, 0, 58)
  local controls = frame(root, "Actions")
  controls.Position = UDim2.fromOffset(12, 132); controls.Size = UDim2.new(1, -24, 0, 30)
  local find = button(controls, "Find references", function() actions.search(query.Text) end)
  find.Size = UDim2.new(0.34, -4, 1, 0)
  local inventory = button(controls, "Inventory", actions.inventory)
  inventory.Position = UDim2.fromScale(0.34, 0); inventory.Size = UDim2.new(0.25, -4, 1, 0)
  local scope = button(controls, "Whole place", actions.scope)
  scope.Position = UDim2.fromScale(0.59, 0); scope.Size = UDim2.new(0.25, -4, 1, 0)
  local clear = button(controls, "Clear", actions.clear)
  clear.Position = UDim2.fromScale(0.84, 0); clear.Size = UDim2.fromScale(0.16, 1)
  local status = label(root, "", 14)
  status.Name = "Status"; status.Position = UDim2.fromOffset(12, 170); status.Size = UDim2.new(1, -24, 0, 58)
  local choices = frame(root, "AssetChoices")
  choices.Position = UDim2.fromOffset(12, 232); choices.Size = UDim2.new(1, -24, 0, 32)
  local filters = frame(root, "Filters")
  filters.Position = UDim2.fromOffset(12, 232); filters.Size = UDim2.new(1, -24, 0, 30)
  local filter = input(filters, "Filter by ID, path, or property")
  filter.Size = UDim2.new(0.72, -6, 1, 0)
  local categoryIndex = 1
  local category = button(filters, "All >", function()
    categoryIndex = categoryIndex % #categories + 1
    actions.category(categories[categoryIndex])
  end)
  category.Position = UDim2.fromScale(0.72, 0); category.Size = UDim2.fromScale(0.28, 1)
  local replacement = frame(root, "Replacement")
  replacement.Position = UDim2.fromOffset(12, 270); replacement.Size = UDim2.new(1, -24, 0, 64)
  local newId = input(replacement, "Replacement asset ID")
  newId.Name = "ReplacementId"; newId.Size = UDim2.new(0.65, -6, 0, 30)
  local preview = button(replacement, "Preview", function() actions.preview(newId.Text) end)
  preview.Position = UDim2.fromScale(0.65, 0); preview.Size = UDim2.new(0.35, 0, 0, 30)
  local selectVisible = button(replacement, "Toggle all filtered", actions.selectVisible)
  selectVisible.Position = UDim2.fromOffset(0, 36); selectVisible.Size = UDim2.fromOffset(140, 24); selectVisible.TextSize = 13
  local note = label(replacement, "Scripts and mesh geometry are read-only.", 12)
  note.Position = UDim2.fromOffset(148, 36); note.Size = UDim2.new(1, -148, 0, 28)
  local confirm = frame(root, "Confirmation")
  confirm.Position = UDim2.fromOffset(12, 232); confirm.Size = UDim2.new(1, -24, 0, 34)
  local back = button(confirm, "Back", actions.back)
  back.Size = UDim2.new(0.3, -6, 1, 0)
  local apply = button(confirm, "Apply reviewed changes", actions.apply)
  apply.Position = UDim2.fromScale(0.3, 0); apply.Size = UDim2.fromScale(0.7, 1)
  local results = Instance.new("ScrollingFrame")
  results.Name = "References"; results.BorderSizePixel = 0; results.BackgroundTransparency = 1
  results.AutomaticCanvasSize = Enum.AutomaticSize.Y; results.CanvasSize = UDim2.new()
  results.ScrollBarThickness = 6; results.Parent = root
  local layout = Instance.new("UIListLayout")
  layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = results
  local pager = frame(root, "Pagination")
  pager.Position = UDim2.new(0, 12, 1, -36); pager.Size = UDim2.new(1, -24, 0, 28)
  local currentPage = 1
  local previous = button(pager, "Prev", function() actions.page(currentPage - 1) end)
  previous.Size = UDim2.fromOffset(40, 28)
  local nextPage = button(pager, "Next", function() actions.page(currentPage + 1) end)
  nextPage.Position = UDim2.new(1, -40, 0, 0); nextPage.Size = UDim2.fromOffset(40, 28)
  local pageLabel = label(pager, "", 14)
  pageLabel.TextXAlignment = Enum.TextXAlignment.Center
  pageLabel.Position = UDim2.fromOffset(44, 3); pageLabel.Size = UDim2.new(1, -88, 1, 0)
  local rendering = false
  connect(filter:GetPropertyChangedSignal("Text"), function()
    if not rendering then actions.filter(filter.Text) end
  end)
  connect(studio.ThemeChanged, function()
    for instance, properties in themed do
      for property, key in properties do (instance :: any)[property] = studio.Theme:GetColor(key) end
    end
  end)

  local function clearRows()
    for _, connection in rowsConnections do connection:Disconnect() end
    table.clear(rowsConnections)
    for _, container in {results, choices} do
      for _, child in container:GetChildren() do
        if child:IsA("GuiObject") then
          themed[child] = nil
          for _, descendant in child:GetDescendants() do themed[descendant] = nil end
          child:Destroy()
        end
      end
    end
  end

  local lastPage: number? = nil
  local lastMode: string? = nil
  local lastFilter: string? = nil
  local lastCategory: string? = nil
  local lastFirst: Scanner.Result? = nil
  local function render(state: Controller.State, visible: {Scanner.Result})
    rendering = true
    local scanning = state.mode == "scanning"
    local reviewing = state.mode == "preview"
    status.Text = state.message
    scope.Text = if state.selectedScope then "Selection" else "Whole place"
    clear.Text = if scanning then "Cancel" else "Clear"
    for _, control in {find, inventory, scope} do control.Interactable = not scanning and not reviewing end
    query.TextEditable = not scanning and not reviewing
    filters.Visible = not reviewing and #state.choices == 0
    replacement.Visible = state.mode == "results" and #state.results > 0
    confirm.Visible = reviewing
    choices.Visible = #state.choices > 0
    category.Text = state.category .. " >"
    categoryIndex = table.find(categories, state.category) or 1
    if filter.Text ~= state.filter then filter.Text = state.filter end
    local top = if reviewing then 278 elseif replacement.Visible then 342 else 270
    results.Position = UDim2.fromOffset(12, top)
    results.Size = UDim2.new(1, -24, 1, -top - 44)
    clearRows()
    if #state.choices > 0 then
      -- Choices share the paginated list, so long pasted logs never overflow the panel.
      local hint = label(choices, "Choose an asset ID below:", 15)
      hint.Size = UDim2.fromScale(1, 1)
    end
    local count = if reviewing then #state.changes elseif #state.choices > 0 then #state.choices else #visible + #state.warnings
    local pages = math.max(1, math.ceil(count / PAGE_SIZE))
    currentPage = math.clamp(state.page, 1, pages)
    if currentPage ~= lastPage or state.mode ~= lastMode or state.filter ~= lastFilter
      or state.category ~= lastCategory or visible[1] ~= lastFirst then
      results.CanvasPosition = Vector2.zero
    end
    lastPage = currentPage; lastMode = state.mode; lastFilter = state.filter
    lastCategory = state.category; lastFirst = visible[1]
    pageLabel.Text = `Page {currentPage} / {pages} · {count} items`
    previous.Interactable = currentPage > 1; nextPage.Interactable = currentPage < pages
    for index = (currentPage - 1) * PAGE_SIZE + 1, math.min(currentPage * PAGE_SIZE, count) do
      local card = frame(results, "Item")
      card.LayoutOrder = index; card.Size = UDim2.new(1, -8, 0, 104)
      card.BackgroundTransparency = 0
      color(card, "BackgroundColor3", Enum.StudioStyleGuideColor.InputFieldBackground)
      if reviewing then
        local change = state.changes[index]
        -- Every reviewed value is visible, including long paths and URLs at minimum width.
        card.Size = UDim2.new(1, -8, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 8); padding.PaddingRight = UDim.new(0, 8)
        padding.PaddingTop = UDim.new(0, 8); padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = card
        local stack = Instance.new("UIListLayout")
        stack.Padding = UDim.new(0, 8); stack.SortOrder = Enum.SortOrder.LayoutOrder; stack.Parent = card
        local heading = label(card, change.path .. " · " .. change.property, 14)
        local old = label(card, "FROM  " .. change.before, 13)
        local proposed = label(card, "TO       " .. change.after, 13)
        for order, text in {heading, old, proposed} do
          text.LayoutOrder = order
          text.Size = UDim2.new(1, 0, 0, 0)
          text.AutomaticSize = Enum.AutomaticSize.Y
        end
      elseif #state.choices > 0 then
        card.Size = UDim2.new(1, -8, 0, 40)
        local id = state.choices[index]
        local choose = button(card, "Find " .. id, function() actions.search(id) end, true)
        choose.Size = UDim2.fromScale(1, 1)
      elseif index > #visible then
        local warning = label(card, "NOTICE · " .. state.warnings[index - #visible], 14)
        warning.Position = UDim2.fromOffset(8, 8); warning.Size = UDim2.new(1, -16, 1, -16)
      else
        local result = visible[index]
        local checked = state.checked[result] == true
        local toggle = button(card, if checked then "X" else "", function() actions.toggle(result) end, true)
        toggle.Position = UDim2.fromOffset(8, 8); toggle.Size = UDim2.fromOffset(26, 26)
        toggle.Visible = result.writable
        local heading = label(card, result.id .. " · " .. result.category, 16)
        heading.Font = Enum.Font.SourceSansSemibold
        heading.Position = UDim2.fromOffset(42, 7); heading.Size = UDim2.new(1, -124, 0, 24)
        local open = button(card, if result.kind == "script" then "Code" else "Select", function() actions.open(result) end, true)
        open.Position = UDim2.new(1, -74, 0, 8); open.Size = UDim2.fromOffset(66, 26)
        local pathLabel = label(card, result.path, 14)
        pathLabel.Position = UDim2.fromOffset(8, 38); pathLabel.Size = UDim2.new(1, -16, 0, 32)
        pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
        local description = if result.kind == "script" then `Line {result.line} · textual match · read-only`
          elseif result.writable then result.class .. "." .. result.property else result.property .. " · read-only geometry"
        local info = label(card, description .. "\n" .. result.before, 12)
        info.Position = UDim2.fromOffset(8, 72); info.Size = UDim2.new(1, -16, 0, 30)
        info.TextTruncate = Enum.TextTruncate.AtEnd
        color(info, "TextColor3", Enum.StudioStyleGuideColor.DimmedText)
      end
    end
    if count == 0 and not scanning then
      local empty = label(results, if state.summary then "Replacement finished. Review the summary above." else "No references to show. Find an ID or browse the asset inventory.", 15)
      empty.Size = UDim2.new(1, -12, 0, 70)
    end
    rendering = false
  end
  return {
    render=render,
    destroy=function()
      for _, connection in connections do connection:Disconnect() end
      clearRows(); table.clear(themed); root:Destroy()
    end,
  }
end
return View
