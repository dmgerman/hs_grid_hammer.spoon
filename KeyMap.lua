--- === hs_grid_hammer.KeyMap ===
---
--- O(1) key lookup hash table.
--- Replaces GridCraft's O(n×m) EventTap validation with constant-time lookup.

local M = {}
M.__index = M

--- Modifier sort order for consistent normalization
local MOD_ORDER = {
  cmd = 1,
  ctrl = 2,
  alt = 3,
  shift = 4,
  fn = 5,
}

--- Create a new KeyMap
--- @return table KeyMap instance
function M.new()
  local self = setmetatable({}, M)
  self.keys = {}
  return self
end

--- Normalize a key combination to a consistent string format.
--- Modifiers are sorted in standard order (cmd, ctrl, alt, shift, fn).
--- Key is lowercased.
---
--- @param mods table Array of modifier strings like {"cmd", "shift"}
--- @param key string The key like "e" or "F11"
--- @return string Normalized key string like "cmd+shift+e" or "e"
function M:normalize(mods, key)
  local normalizedKey = string.lower(key)

  if not mods or #mods == 0 then
    return normalizedKey
  end

  -- Sort modifiers by standard order
  local sortedMods = {}
  for _, mod in ipairs(mods) do
    local lowerMod = string.lower(mod)
    table.insert(sortedMods, lowerMod)
  end

  table.sort(sortedMods, function(a, b)
    local orderA = MOD_ORDER[a] or 99
    local orderB = MOD_ORDER[b] or 99
    return orderA < orderB
  end)

  return table.concat(sortedMods, "+") .. "+" .. normalizedKey
end

--- Add an action to the key map.
---
--- @param mods table Array of modifier strings (can be empty or nil)
--- @param key string The key
--- @param action table The action object to store
function M:add(mods, key, action)
  if not key then return end

  local normalized = self:normalize(mods or {}, key)
  self.keys[normalized] = action
end

--- Look up an action by key combination.
--- Returns nil if no action is bound to this combination.
---
--- @param mods table Array of modifier strings (can be empty or nil)
--- @param key string The key
--- @return table|nil The action object or nil
function M:lookup(mods, key)
  if not key then return nil end

  local normalized = self:normalize(mods or {}, key)
  return self.keys[normalized]
end

--- Check if a key combination is bound.
---
--- @param mods table Array of modifier strings
--- @param key string The key
--- @return boolean True if bound
function M:has(mods, key)
  return self:lookup(mods, key) ~= nil
end

--- Get all bound key combinations as a formatted string.
--- Useful for error messages showing valid keys.
---
--- @return string Comma-separated list of valid keys
function M:validKeysString()
  local keys = {}
  for normalized, _ in pairs(self.keys) do
    -- Convert back to display format (uppercase key, proper mod symbols)
    local display = normalized:gsub("cmd", "Cmd"):gsub("ctrl", "Ctrl")
                             :gsub("alt", "Alt"):gsub("shift", "Shift")
                             :gsub("fn", "Fn")
    -- Uppercase the final key part
    display = display:gsub("%+([^+]+)$", function(k) return "+" .. k:upper() end)
    display = display:gsub("^([^+]+)$", function(k) return k:upper() end)
    table.insert(keys, display)
  end
  table.sort(keys)
  return table.concat(keys, ", ")
end

--- Get count of bound keys.
---
--- @return number Number of bound key combinations
function M:count()
  local count = 0
  for _ in pairs(self.keys) do
    count = count + 1
  end
  return count
end

--- Iterate over all bound actions.
--- Calls fn(normalizedKey, action) for each binding.
---
--- @param fn function Callback function
function M:each(fn)
  for normalized, action in pairs(self.keys) do
    fn(normalized, action)
  end
end

return M
