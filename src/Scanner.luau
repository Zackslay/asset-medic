--!strict
local Ids = require(script.Parent.Ids)
local Properties = require(script.Parent.Properties)

export type Result = {
  kind: string, instance: Instance, path: string, class: string, category: string,
  id: string, property: string, before: string, writable: boolean, line: number?,
}
export type Report = {results: {Result}, warnings: {string}, visited: number, cancelled: boolean}
export type Options = {
  cancelled: () -> boolean, yield: () -> (), source: (Instance) -> string,
  progress: (number, number) -> (),
}
local Scanner = {}

function Scanner.scan(roots: {Instance}, id: string?, options: Options): Report
  local report: Report = {results={}, warnings={}, visited=0, cancelled=false}
  local seen: {[Instance]: boolean} = {}
  local stack = table.clone(roots)
  local function checkpoint()
    options.progress(report.visited, #report.results)
    options.yield()
  end
  while #stack > 0 do
    if options.cancelled() then report.cancelled = true; table.clear(report.results); return report end
    local instance = table.remove(stack) :: Instance
    if seen[instance] then continue end
    seen[instance] = true
    report.visited += 1
    local ok, children = pcall(function() return instance:GetChildren() end)
    if ok then
      -- Reverse traversal preserves child order, without GetDescendants allocating the whole place.
      for index = #children, 1, -1 do table.insert(stack, children[index]) end
    else
      table.insert(report.warnings, `Could not inspect children of {instance.Name}`)
    end
    local path = instance:GetFullName()
    for _, definition in Properties do
      if instance:IsA(definition.class) then
        local readable, value = pcall(function() return (instance :: any)[definition.property] end)
        if not readable then
          table.insert(report.warnings, `{path}.{definition.property}: unreadable`)
        elseif type(value) == "string" then
          local assetId = Ids.propertyId(value)
          if assetId and (not id or assetId == id) then
            table.insert(report.results, {
              kind="property", instance=instance, path=path, class=instance.ClassName,
              category=definition.category, id=assetId, property=definition.property,
              before=value, writable=definition.writable,
            })
          end
        end
      end
    end
    if id and instance:IsA("LuaSourceContainer") then
      local readable, source = pcall(options.source, instance)
      if not readable then
        table.insert(report.warnings, `{path}: script could not be inspected ({tostring(source)})`)
      else
        for _, hit in Ids.scriptMatches(source, id, function()
          checkpoint()
          return not options.cancelled()
        end) do
          if options.cancelled() then break end
          table.insert(report.results, {
            kind="script", instance=instance, path=path, class=instance.ClassName,
            category="Script", id=id, property="Source", before=hit.text, writable=false, line=hit.line,
          })
        end
      end
    end
    if report.visited % 200 == 0 then checkpoint() end
  end
  if options.cancelled() then report.cancelled = true; table.clear(report.results) end
  return report
end
return Scanner
