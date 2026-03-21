--- === hs_grid_hammer.IconLoader ===
---
--- Async icon loading with LRU caching.
--- Prevents UI blocking during icon loading and reduces memory usage.

local function _require(name)
  _hs_grid_hammer_modules = _hs_grid_hammer_modules or {}
  if not _hs_grid_hammer_modules[name] then
    _hs_grid_hammer_modules[name] = dofile(hs.spoons.resourcePath(name))
  end
  return _hs_grid_hammer_modules[name]
end

local Icon = _require("Icon.lua")
local Theme = _require("Theme.lua")
local Util = _require("Util.lua")

local M = {}

--------------------------------------------------------------------------------
-- Cache configuration
--------------------------------------------------------------------------------

local MAX_CACHE_SIZE = 100
local EVICTION_COUNT = 20

-- Cache storage: cache[key] = {image = hs.image, lastUsed = timestamp}
local cache = {}
local cacheSize = 0

-- Statistics
local stats = {
  hits = 0,
  misses = 0,
  evictions = 0,
}

--------------------------------------------------------------------------------
-- Private helpers
--------------------------------------------------------------------------------

local function timestamp()
  return os.time()
end

--- Evict least recently used entries
local function evictLRU()
  local entries = {}
  for key, entry in pairs(cache) do
    table.insert(entries, {key = key, lastUsed = entry.lastUsed})
  end

  table.sort(entries, function(a, b)
    return a.lastUsed < b.lastUsed
  end)

  local evicted = 0
  for i = 1, math.min(EVICTION_COUNT, #entries) do
    cache[entries[i].key] = nil
    cacheSize = cacheSize - 1
    evicted = evicted + 1
  end

  stats.evictions = stats.evictions + evicted
end

--- Load and resize icon from path
--- @param path string Path to file/app
--- @return hs.image|nil Resized image or nil
local function loadIconFromPath(path)
  return Icon.fromPath(path)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Get image from cache
--- @param key string Cache key
--- @return hs.image|nil Cached image or nil
function M.get(key)
  local entry = cache[key]
  if entry then
    entry.lastUsed = timestamp()
    stats.hits = stats.hits + 1
    return entry.image
  end
  stats.misses = stats.misses + 1
  return nil
end

--- Store image in cache
--- @param key string Cache key
--- @param image hs.image Image to cache
function M.put(key, image)
  if cacheSize >= MAX_CACHE_SIZE then
    evictLRU()
  end

  if not cache[key] then
    cacheSize = cacheSize + 1
  end

  cache[key] = {
    image = image,
    lastUsed = timestamp(),
  }
end

--- Load icon asynchronously from file path.
--- Checks cache first, then loads in next run loop iteration.
---
--- @param path string File path to load icon from
--- @param callback function Called with (image) when ready
function M.loadAsync(path, callback)
  if not path then
    callback(nil)
    return
  end

  local cached = M.get(path)
  if cached then
    callback(cached)
    return
  end

  hs.timer.doAfter(0, function()
    local image = loadIconFromPath(path)
    if image then
      M.put(path, image)
    end
    callback(image)
  end)
end

--- Load icon for application by name.
--- Finds the app path first, then loads icon.
---
--- @param appName string Application name
--- @param callback function Called with (image) when ready
function M.loadAppIconAsync(appName, callback)
  if not appName then
    callback(nil)
    return
  end

  local cacheKey = "app:" .. appName
  local cached = M.get(cacheKey)
  if cached then
    callback(cached)
    return
  end

  hs.timer.doAfter(0, function()
    local appPath = Util.findApplicationPath(appName)
    if not appPath then
      callback(nil)
      return
    end

    local image = loadIconFromPath(appPath)
    if image then
      M.put(cacheKey, image)
    end
    callback(image)
  end)
end

--- Generate a placeholder icon with colored background and letter.
--- Delegates to Icon.placeholder() - this is a convenience wrapper.
---
--- @param text string Text to derive color and letter from
--- @param size number|nil Optional size (default from theme)
--- @return hs.image Placeholder image
function M.placeholder(text, size)
  return Icon.placeholder(text, nil, {size = size})
end

--- Clear the cache
function M.clear()
  cache = {}
  cacheSize = 0
end

--- Get cache statistics
--- @return table Statistics table
function M.getStats()
  local total = stats.hits + stats.misses
  local hitRate = total > 0 and (stats.hits / total * 100) or 0

  return {
    size = cacheSize,
    maxSize = MAX_CACHE_SIZE,
    hits = stats.hits,
    misses = stats.misses,
    hitRate = hitRate,
    evictions = stats.evictions,
  }
end

--- Print cache statistics
function M.printStats()
  local s = M.getStats()
  print(string.format([[
[IconLoader Cache Statistics]
  Size: %d / %d
  Hits: %d | Misses: %d | Hit Rate: %.1f%%
  Evictions: %d
]], s.size, s.maxSize, s.hits, s.misses, s.hitRate, s.evictions))
end

return M
