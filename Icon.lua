--- === hs_grid_hammer.Icon ===
---
--- Icon utilities for creating hs.image icons.
--- Replaces GridCraft's HTML-based icons with native images.

local M = {}

--- Load icon from a PNG/image file
--- @param filePath string Path to the image file
--- @return hs.image|nil The loaded image or nil
function M.fromFile(filePath)
  if not filePath then return nil end

  local image = hs.image.imageFromPath(filePath)
  if image then
    return image:setSize({w = 64, h = 64})
  end
  return nil
end

--- Get icon for a macOS application or file
--- @param path string Path to app bundle or file
--- @return hs.image|nil The icon image or nil
function M.fromPath(path)
  if not path then return nil end

  local image = hs.image.iconForFile(path)
  if image then
    return image:setSize({w = 64, h = 64})
  end
  return nil
end

--- Get icon for an application by bundle ID
--- @param bundleID string macOS bundle identifier (e.g., "com.apple.Safari")
--- @return hs.image|nil The icon image or nil
function M.fromBundleID(bundleID)
  if not bundleID then return nil end

  local image = hs.image.imageFromAppBundle(bundleID)
  if image then
    return image:setSize({w = 64, h = 64})
  end
  return nil
end

--- Create a placeholder icon with colored background and symbol/letter
--- @param text string Text to derive color and display character from
--- @param symbol string Optional symbol to display (defaults to first letter of text)
--- @param bgColor table Optional background color {red, green, blue, alpha}
--- @return hs.image The generated placeholder image
function M.placeholder(text, symbol, bgColor)
  local size = 64
  local displayChar = symbol or string.upper(string.sub(text or "?", 1, 1))

  -- Generate color from text hash if not provided
  if not bgColor then
    local hash = 0
    for i = 1, #(text or "") do
      hash = (hash * 31 + string.byte(text, i)) % 360
    end

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

    bgColor = {
      red = hue2rgb(p, q, h + 1/3),
      green = hue2rgb(p, q, h),
      blue = hue2rgb(p, q, h - 1/3),
      alpha = 1.0,
    }
  end

  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})

  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = bgColor,
    roundedRectRadii = {xRadius = 8, yRadius = 8},
  })

  canvas:insertElement({
    type = "text",
    frame = {x = 0, y = size * 0.15, w = size, h = size * 0.7},
    text = displayChar,
    textAlignment = "center",
    textColor = {white = 1.0},
    textFont = "Helvetica Bold",
    textSize = size * 0.5,
  })

  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
end

--- Create a text-based icon (like StreamDeck style)
--- @param label string Text to display on the icon
--- @param options table Optional settings: backgroundColor, textColor, fontSize
--- @return hs.image The generated image
function M.fromText(label, options)
  options = options or {}
  local size = 64

  local bgColor = options.backgroundColor or {red = 0.1, green = 0.1, blue = 0.1, alpha = 1.0}
  local textColor = options.textColor or {white = 1.0}
  local fontSize = options.fontSize or 12

  -- Handle hex colors
  if bgColor.hex then
    local hex = bgColor.hex:gsub("#", "")
    bgColor = {
      red = tonumber(hex:sub(1, 2), 16) / 255,
      green = tonumber(hex:sub(3, 4), 16) / 255,
      blue = tonumber(hex:sub(5, 6), 16) / 255,
      alpha = 1.0,
    }
  end
  if textColor.hex then
    local hex = textColor.hex:gsub("#", "")
    textColor = {
      red = tonumber(hex:sub(1, 2), 16) / 255,
      green = tonumber(hex:sub(3, 4), 16) / 255,
      blue = tonumber(hex:sub(5, 6), 16) / 255,
      alpha = 1.0,
    }
  end

  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})

  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = bgColor,
    roundedRectRadii = {xRadius = 6, yRadius = 6},
  })

  -- Handle multi-line text
  local lines = {}
  for line in (label .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(lines, line)
  end

  local lineHeight = fontSize + 4
  local totalHeight = #lines * lineHeight
  local startY = (size - totalHeight) / 2

  for i, line in ipairs(lines) do
    canvas:insertElement({
      type = "text",
      frame = {x = 2, y = startY + (i - 1) * lineHeight, w = size - 4, h = lineHeight},
      text = line,
      textAlignment = "center",
      textColor = textColor,
      textFont = "Helvetica Bold",
      textSize = fontSize,
    })
  end

  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
end

--- Predefined icon symbols for common actions (Phosphor icon replacements)
--- These use Unicode symbols that render well at icon sizes
M.symbols = {
  ["app-window"] = "☐",      -- Window/app
  ["monitor"] = "🖥",         -- Monitor/display
  ["chat"] = "💬",            -- Chat/message
  ["translate"] = "文",       -- Translate/language
  ["speaker-high"] = "🔊",    -- Audio/speaker
  ["globe"] = "🌐",           -- Web/globe
  ["folder"] = "📁",          -- Folder
  ["file"] = "📄",            -- File
  ["terminal"] = ">_",        -- Terminal
  ["mail"] = "✉",             -- Email
  ["calendar"] = "📅",        -- Calendar
  ["search"] = "🔍",          -- Search
  ["settings"] = "⚙",         -- Settings/gear
  ["music"] = "♫",            -- Music
  ["video"] = "▶",            -- Video/play
  ["microphone"] = "🎤",      -- Microphone
  ["keyboard"] = "⌨",         -- Keyboard
}

--- Create an icon using a predefined symbol (Phosphor replacement)
--- @param name string Symbol name from M.symbols
--- @param weight string Ignored (for GridCraft API compatibility)
--- @return hs.image|nil The generated icon or nil if symbol not found
function M.symbol(name, weight)
  local sym = M.symbols[name]
  if not sym then
    -- Fall back to first letter of name
    sym = string.upper(string.sub(name or "?", 1, 1))
  end
  return M.placeholder(name, sym)
end

--- Compatibility alias for GridCraft's Icon.phosphor()
--- Creates a placeholder icon with a symbol
M.phosphor = M.symbol

--- Create an empty/transparent icon
--- @return hs.image A transparent 64x64 image
function M.empty()
  local size = 64
  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})

  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = {alpha = 0},
  })

  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
end

return M
