--!strict
local Ids = require(script.Parent.Ids)
local Scanner = require(script.Parent.Scanner)
export type Change = {instance: Instance, path: string, property: string, before: string, after: string}
export type Report = {applied: number, skipped: number, failed: number, messages: {string}}
export type Services = {
  history: any, commit: any, cancel: any, running: () -> boolean, alive: (Instance) -> boolean,
  write: (Instance, string, string) -> (),
}
local Replacement = {}

function Replacement.plan(results: {Scanner.Result}, input: string): {Change}
  local id = Ids.single(input)
  if not id then error("Enter exactly one valid replacement asset ID.") end
  local changes: {Change} = {}
  local seen: {[Instance]: {[string]: boolean}} = {}
  for _, result in results do
    if result.kind ~= "property" or not result.writable or result.id == id then continue end
    local properties = seen[result.instance] or {}
    seen[result.instance] = properties
    if properties[result.property] then continue end
    properties[result.property] = true
    table.insert(changes, {
      instance=result.instance, path=result.path, property=result.property,
      before=result.before, after="rbxassetid://" .. id,
    })
  end
  return changes
end

function Replacement.apply(changes: {Change}, services: Services): Report
  local report: Report = {applied=0, skipped=0, failed=0, messages={}}
  if services.running() then table.insert(report.messages, "Stop the playtest before replacing assets."); return report end
  if #changes == 0 then table.insert(report.messages, "No writable changes selected."); return report end
  local started, recording = pcall(function() return services.history:TryBeginRecording("AssetMedic.Replace", "Asset Medic: replace assets") end)
  if not started or not recording then
    table.insert(report.messages, "Studio could not start an undo recording. No changes made.")
    return report
  end
  -- No yields between validation, writes, and finishing the recording.
  local worked, problem = xpcall(function()
    for _, change in changes do
      local readable, current = pcall(function()
        if not services.alive(change.instance) then return nil end
        return (change.instance :: any)[change.property]
      end)
      if not readable or current ~= change.before then
        report.skipped += 1
        table.insert(report.messages, `{change.path}.{change.property}: removed, inaccessible, or changed since preview`)
        continue
      end
      local ok, reason = pcall(services.write, change.instance, change.property, change.after)
      if ok then report.applied += 1 else
        report.failed += 1
        table.insert(report.messages, `{change.path}.{change.property}: {tostring(reason)}`)
      end
    end
  end, function(reason) return tostring(reason) end)
  local finished, finishProblem = pcall(function()
    services.history:FinishRecording(recording, if report.applied > 0 then services.commit else services.cancel)
  end)
  if not worked then report.failed += 1; table.insert(report.messages, tostring(problem)) end
  if not finished then
    report.failed += 1
    table.insert(report.messages, `Undo recording could not finish: {tostring(finishProblem)}. Use Studio Undo to inspect changes.`)
  end
  return report
end
return Replacement
