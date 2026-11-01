--!strict
local Ids = require(script.Parent.Ids)
local Scanner = require(script.Parent.Scanner)
local Replacement = require(script.Parent.Replacement)

export type State = {
  mode: string, selectedScope: boolean, query: string, choices: {string}, results: {Scanner.Result},
  checked: {[Scanner.Result]: boolean}, changes: {Replacement.Change}, warnings: {string},
  filter: string, category: string, page: number, message: string, visited: number,
  summary: Replacement.Report?,
}
export type Services = {
  roots: (boolean) -> {Instance}, spawn: (() -> ()) -> (), scanOptions: Scanner.Options,
  replacement: Replacement.Services, open: (Scanner.Result) -> (),
}
export type Controller = {
  state: State, services: Services, render: (State) -> (), generation: number, disposed: boolean,
  emit: (Controller) -> (), clear: (Controller) -> (), destroy: (Controller) -> (),
  search: (Controller, string) -> (), inventory: (Controller) -> (),
  startScan: (Controller, string?) -> (), visible: (Controller) -> {Scanner.Result},
  preview: (Controller, string) -> (), back: (Controller) -> (), apply: (Controller) -> (),
}
local Controller = {}
Controller.__index = Controller

function Controller.new(services: Services, render: (State) -> ()): Controller
  return setmetatable({
    services=services, render=render, generation=0, disposed=false,
    state={mode="idle", selectedScope=false, query="", choices={}, results={}, checked={}, changes={}, warnings={},
      filter="", category="All", page=1, message="Paste an asset ID or Output error to get started.", visited=0, summary=nil},
  }, Controller) :: any
end

function Controller.emit(self: Controller)
  if not self.disposed then self.render(self.state) end
end

function Controller.clear(self: Controller)
  self.generation += 1
  local state = self.state
  state.mode = "idle"
  state.results = {}; state.checked = {}; state.changes = {}; state.choices = {}; state.warnings = {}
  state.summary = nil; state.page = 1; state.visited = 0
  state.message = "Cleared. Paste an asset ID or run an inventory scan."
  self:emit()
end

function Controller.destroy(self: Controller)
  self.disposed = true
  self:clear()
end

function Controller.search(self: Controller, input: string)
  if self.state.mode == "scanning" or self.disposed then return end
  self:clear()
  self.state.query = input
  local ids = Ids.extract(input)
  if #ids == 0 then self.state.message = "No asset ID found. Paste a positive ID, Roblox asset URL, or asset error."
  elseif #ids > 1 then
    self.state.choices = ids
    self.state.message = "Several asset IDs found. Choose the one to locate."
  else self:startScan(ids[1]); return end
  self:emit()
end

function Controller.inventory(self: Controller)
  if self.state.mode == "scanning" or self.disposed then return end
  self:clear()
  self:startScan(nil)
end

function Controller.startScan(self: Controller, id: string?)
  local roots = self.services.roots(self.state.selectedScope)
  if #roots == 0 then
    self.state.message = "Select at least one object in Explorer before scanning the selection."
    self:emit(); return
  end
  self.generation += 1
  local generation = self.generation
  self.state.mode = "scanning"; self.state.choices = {}; self.state.summary = nil
  self.state.message = "Scanning supported asset properties" .. (if id then " and script text…" else "…")
  self.state.filter = ""; self.state.category = "All"; self.state.page = 1
  self:emit()
  self.services.spawn(function()
    local options: Scanner.Options = {
      cancelled=function() return self.disposed or self.generation ~= generation end,
      yield=self.services.scanOptions.yield,
      source=self.services.scanOptions.source,
      progress=function(visited, count)
        if self.disposed or self.generation ~= generation then return end
        self.state.visited = visited
        self.state.message = `Scanning… {visited} objects · {count} references found`
        self:emit()
      end,
    }
    local ok, report = pcall(Scanner.scan, roots, id, options)
    if self.disposed or self.generation ~= generation then return end
    self.state.mode = "results"
    if not ok then
      self.state.message = "Scan failed: " .. tostring(report)
      self:emit(); return
    end
    if report.cancelled then self:clear(); return end
    table.sort(report.results, function(a, b)
      if a.id ~= b.id then return a.id < b.id end
      if a.path ~= b.path then return a.path < b.path end
      return a.property < b.property
    end)
    self.state.results = report.results
    self.state.warnings = report.warnings
    self.state.visited = report.visited
    for _, result in report.results do self.state.checked[result] = id ~= nil and result.writable end
    self.state.message = `{#report.results} references · {report.visited} objects inspected · {#report.warnings} warnings`
    if #report.results == 0 then self.state.message ..= ". No matches in supported properties or readable script text." end
    self:emit()
  end)
end

function Controller.visible(self: Controller): {Scanner.Result}
  local visible: {Scanner.Result} = {}
  local state = self.state
  local filter = state.filter:lower()
  for _, result in state.results do
    if state.category ~= "All" and state.category ~= result.category then continue end
    local searchable = (`{result.id} {result.path} {result.class} {result.property} {result.before}`):lower()
    if filter ~= "" and not searchable:find(filter, 1, true) then continue end
    table.insert(visible, result)
  end
  return visible
end

function Controller.preview(self: Controller, input: string)
  if self.state.mode ~= "results" then return end
  if self.services.replacement.running() then
    self.state.message = "Stop the playtest before preparing replacements."; self:emit(); return
  end
  if not Ids.single(input) then
    self.state.message = "Enter exactly one valid replacement asset ID."; self:emit(); return
  end
  local picked: {Scanner.Result} = {}
  for _, result in self:visible() do
    if self.state.checked[result] then table.insert(picked, result) end
  end
  self.state.changes = Replacement.plan(picked, input)
  if #self.state.changes == 0 then
    self.state.message = "No changes to preview. Check writable references; the new ID must differ."
  else
    self.state.mode = "preview"; self.state.page = 1
    self.state.message = `Review {#self.state.changes} changes. Asset permissions and compatibility are not checked.`
  end
  self:emit()
end

function Controller.back(self: Controller)
  if self.state.mode ~= "preview" then return end
  self.state.mode = "results"; self.state.changes = {}; self.state.page = 1
  self.state.message = "Preview discarded. Select references and preview again."
  self:emit()
end

function Controller.apply(self: Controller)
  if self.disposed or self.state.mode ~= "preview" then return end
  local report = Replacement.apply(self.state.changes, self.services.replacement)
  self.state.summary = report
  self.state.warnings = report.messages
  self.state.mode = "results"; self.state.changes = {}; self.state.checked = {}
  self.state.message = `{report.applied} applied · {report.skipped} skipped · {report.failed} failed. Scan again before another replacement. Use Studio Undo to revert the batch.`
  -- Result snapshots must not survive a mutation as actionable references.
  self.state.results = {}; self.state.page = 1
  self:emit()
end
return Controller
