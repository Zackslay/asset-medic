--!strict
local Ids = {}
local function normalize(value: string?): string?
  if not value or not value:match("^%d+$") then return nil end
  local result = value:gsub("^0+", "")
  return if result == "" then nil else result
end

function Ids.propertyId(value: string): string?
  local trimmed = value:match("^%s*(.-)%s*$") or ""
  local bare = normalize(trimmed)
  if bare then return bare end
  local content = trimmed:match("^rbxassetid://(%d+)$")
  if content then return normalize(content) end
  local host, path = trimmed:match("^https?://([^/]+)(/.*)$")
  if not host or not path then return nil end
  host = host:lower()
  if host ~= "roblox.com" and host ~= "www.roblox.com" and host ~= "create.roblox.com" and host ~= "assetdelivery.roblox.com" then return nil end
  local store = path:match("^/store/asset/(%d+)") or path:match("^/library/(%d+)") or path:match("^/catalog/(%d+)")
  if store then
    local suffix = path:sub((path:find(store, 1, true) or 0) + #store)
    if suffix ~= "" and not suffix:match("^[/#?]") then return nil end
    return normalize(store)
  end
  if not path:match("^/asset/?%?") and not path:match("^/v1/asset/?%?") then return nil end
  local id = path:match("[?&]id=(%d+)")
  if not id then return nil end
  local _, ending = path:find("[?&]id=" .. id)
  local suffix = path:sub((ending or 0) + 1)
  if suffix ~= "" and not suffix:match("^[&#]") then return nil end
  return normalize(id)
end

function Ids.extract(value: string): {string}
  local bare = normalize(value:match("^%s*(%d+)%s*$"))
  if bare then return {bare} end
  local found: {{position: number, id: string}} = {}
  for _, pattern in {
    "()%f[%w_][aA]sset%s*[iI][dD]%s*[:=]?%s*[\"']?(%d+)()",
    "()%f[%w_][aA]sset%s+[%\"']?(%d+)()",
  } do
    for position, token, ending in value:gmatch(pattern) do
      local id = normalize(token)
      if id and not value:sub(ending, ending):match("[%w_]") then
        table.insert(found, {position=position, id=id})
      end
    end
  end
  for position, token in value:gmatch("()(rbxassetid://%d+)") do
    local id = Ids.propertyId(token)
    local following = value:sub(position + #token, position + #token)
    if id and not following:match("[%w_]") then table.insert(found, {position=position, id=id}) end
  end
  for position, token in value:gmatch("()(https?://[^%s\"'<>%)%]]+)") do
    token = token:gsub("[.,;:]+$", "")
    local id = Ids.propertyId(token)
    if id then table.insert(found, {position=position, id=id}) end
  end
  table.sort(found, function(a, b) return a.position < b.position end)
  local seen: {[string]: boolean} = {}
  local ids: {string} = {}
  for _, hit in found do
    if not seen[hit.id] then seen[hit.id] = true; table.insert(ids, hit.id) end
  end
  return ids
end

function Ids.single(value: string): string?
  local ids = Ids.extract(value)
  return if #ids == 1 then ids[1] else nil
end

function Ids.scriptMatches(source: string, id: string, checkpoint: (() -> boolean)?): {{line: number, text: string}}
  local matches: {{line: number, text: string}} = {}
  local lineNumber = 0
  for line in (source .. "\n"):gmatch("(.-)\n") do
    lineNumber += 1
    if checkpoint and lineNumber % 200 == 0 and not checkpoint() then return {} end
    local found = false
    for token in line:gmatch("%f[%w_%.][%w_%.]+") do
      if normalize(token) == id then found = true; break end
    end
    if found then table.insert(matches, {line=lineNumber, text=line:sub(1, 240)}) end
  end
  return matches
end
return Ids
