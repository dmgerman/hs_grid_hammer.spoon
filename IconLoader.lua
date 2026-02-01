--- === hs_grid_hammer.IconLoader ===
---
--- Async icon loading with LRU caching.
--- Prevents UI blocking during icon loading and reduces memory usage.

local M = {}

-- Cache configuration
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

--- Get current timestamp
local function timestamp()
  return os.time()
end

--- Evict least recently used entries
local function evictLRU()
  -- Build array of {key, lastUsed}
  local entries = {}
  for key, entry in pairs(cache) do
    table.insert(entries, {key = key, lastUsed = entry.lastUsed})
  end

  -- Sort by lastUsed (oldest first)
  table.sort(entries, function(a, b)
    return a.lastUsed < b.lastUsed
  end)

  -- Evict oldest entries
  local evicted = 0
  for i = 1, math.min(EVICTION_COUNT, #entries) do
    cache[entries[i].key] = nil
    cacheSize = cacheSize - 1
    evicted = evicted + 1
  end

  stats.evictions = stats.evictions + evicted
end

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

--- Load icon asynchronously
--- Checks cache first, then loads in next run loop iteration.
---
--- @param path string File path to load icon from (app or file)
--- @param callback function Called with (image) when ready
function M.loadAsync(path, callback)
  if not path then
    callback(nil)
    return
  end

  -- Check cache
  local cached = M.get(path)
  if cached then
    callback(cached)
    return
  end

  -- Load asynchronously
  hs.timer.doAfter(0, function()
    local image = hs.image.iconForFile(path)
    if image then
      -- Resize to standard icon size
      image = image:setSize({w = 64, h = 64})
      M.put(path, image)
    end
    callback(image)
  end)
end

--- Load icon for application by name
--- Finds the app path first, then loads icon.
---
--- @param appName string Application name
--- @param callback function Called with (image) when ready
function M.loadAppIconAsync(appName, callback)
  if not appName then
    callback(nil)
    return
  end

  -- Check cache by app name
  local cacheKey = "app:" .. appName
  local cached = M.get(cacheKey)
  if cached then
    callback(cached)
    return
  end

  -- Find app path and load
  hs.timer.doAfter(0, function()
    local app = hs.application.find(appName)
    local appPath = nil

    if app then
      appPath = app:path()
    else
      -- Try to find by bundle ID or path
      local bundleID = hs.application.infoForBundlePath("/Applications/" .. appName .. ".app")
      if bundleID then
        appPath = "/Applications/" .. appName .. ".app"
      else
        -- Search common locations
        local searchPaths = {
          "/Applications/" .. appName .. ".app",
          "/System/Applications/" .. appName .. ".app",
          "/Applications/Utilities/" .. appName .. ".app",
          os.getenv("HOME") .. "/Applications/" .. appName .. ".app",
        }
        for _, path in ipairs(searchPaths) do
          if hs.fs.attributes(path) then
            appPath = path
            break
          end
        end
      end
    end

    if appPath then
      local image = hs.image.iconForFile(appPath)
      if image then
        image = image:setSize({w = 64, h = 64})
        M.put(cacheKey, image)
        callback(image)
        return
      end
    end

    callback(nil)
  end)
end

--- Generate a placeholder icon with colored background and letter
---
--- @param text string Text to derive color and letter from
--- @param size number Optional size (default 64)
--- @return hs.image Placeholder image
function M.placeholder(text, size)
  size = size or 64
  local letter = string.upper(string.sub(text or "?", 1, 1))

  -- Generate color from text hash
  local hash = 0
  for i = 1, #(text or "") do
    hash = (hash * 31 + string.byte(text, i)) % 360
  end

  -- Convert hue to RGB
  local h = hash / 360
  local s = 0.5
  local l = 0.4

  local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end

  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q

  local r = hue2rgb(p, q, h + 1/3)
  local g = hue2rgb(p, q, h)
  local b = hue2rgb(p, q, h - 1/3)

  -- Create canvas and render to image
  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})

  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = {red = r, green = g, blue = b, alpha = 1.0},
    roundedRectRadii = {xRadius = 8, yRadius = 8},
  })

  canvas:insertElement({
    type = "text",
    frame = {x = 0, y = size * 0.2, w = size, h = size * 0.7},
    text = letter,
    textAlignment = "center",
    textColor = {white = 1.0},
    textFont = "Helvetica Bold",
    textSize = size * 0.5,
  })

  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
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
