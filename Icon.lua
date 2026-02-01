--- === hs_grid_hammer.Icon ===
---
--- Icon utilities for creating hs.image icons.
--- Replaces GridCraft's HTML-based icons with native images.
---
--- This module is the single source for all icon generation, including
--- placeholder icons. Other modules should call these functions rather
--- than duplicating rendering logic.

local Color = dofile(hs.spoons.resourcePath("Color.lua"))
local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))

local M = {}

--------------------------------------------------------------------------------
-- Icon loading functions
--------------------------------------------------------------------------------

--- Load icon from a PNG/image file
--- @param filePath string Path to the image file
--- @param size number|nil Optional size (default from theme)
--- @return hs.image|nil The loaded image or nil
function M.fromFile(filePath, size)
  if not filePath then return nil end

  size = size or Theme.default.iconSize
  local image = hs.image.imageFromPath(filePath)
  if image then
    return image:setSize({w = size, h = size})
  end
  return nil
end

--- Get icon for a macOS application or file
--- @param path string Path to app bundle or file
--- @param size number|nil Optional size (default from theme)
--- @return hs.image|nil The icon image or nil
function M.fromPath(path, size)
  if not path then return nil end

  size = size or Theme.default.iconSize
  local image = hs.image.iconForFile(path)
  if image then
    return image:setSize({w = size, h = size})
  end
  return nil
end

--- Get icon for an application by bundle ID
--- @param bundleID string macOS bundle identifier (e.g., "com.apple.Safari")
--- @param size number|nil Optional size (default from theme)
--- @return hs.image|nil The icon image or nil
function M.fromBundleID(bundleID, size)
  if not bundleID then return nil end

  size = size or Theme.default.iconSize
  local image = hs.image.imageFromAppBundle(bundleID)
  if image then
    return image:setSize({w = size, h = size})
  end
  return nil
end

--------------------------------------------------------------------------------
-- Placeholder icon generation
--------------------------------------------------------------------------------

--- Create a placeholder icon with colored background and symbol/letter.
--- This is the canonical implementation - other modules should call this.
---
--- @param text string Text to derive color and display character from
--- @param symbol string|nil Optional symbol to display (defaults to first letter)
--- @param options table|nil Optional settings:
---   - bgColor: Background color table {red, green, blue, alpha}
---   - size: Icon size (default from theme)
---   - font: Font name (default from theme)
---   - textRatio: Text size as ratio of icon size (default from theme)
---   - offsetRatio: Vertical offset as ratio of icon size (default from theme)
---   - cornerRadius: Corner radius (default from theme)
--- @return hs.image The generated placeholder image
function M.placeholder(text, symbol, options)
  options = options or {}
  local t = Theme.default

  local size = options.size or t.iconSize
  local font = options.font or t.placeholderFont
  local textRatio = options.textRatio or t.placeholderTextRatio
  local offsetRatio = options.offsetRatio or t.placeholderTextOffsetRatio
  local cornerRadius = options.cornerRadius or t.iconCornerRadius

  local displayChar = symbol or string.upper(string.sub(text or "?", 1, 1))
  local bgColor = options.bgColor or Color.fromString(text)

  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})

  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = bgColor,
    roundedRectRadii = {xRadius = cornerRadius, yRadius = cornerRadius},
  })

  canvas:insertElement({
    type = "text",
    frame = {x = 0, y = size * offsetRatio, w = size, h = size * (1 - offsetRatio)},
    text = displayChar,
    textAlignment = "center",
    textColor = {white = 1.0},
    textFont = font,
    textSize = size * textRatio,
  })

  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
end

--------------------------------------------------------------------------------
-- Text-based icons
--------------------------------------------------------------------------------

--- Create a text-based icon (like StreamDeck style)
--- @param label string Text to display on the icon
--- @param options table|nil Optional settings:
---   - backgroundColor: Background color (default from theme)
---   - textColor: Text color (default white)
---   - fontSize: Font size (default from theme)
---   - size: Icon size (default from theme)
--- @return hs.image The generated image
function M.fromText(label, options)
  options = options or {}
  local t = Theme.default

  local size = options.size or t.iconSize
  local bgColor = options.backgroundColor or t.textIconBackground
  local textColor = options.textColor or {white = 1.0}
  local fontSize = options.fontSize or t.textIconDefaultSize
  local cornerRadius = t.textIconCornerRadius

  -- Handle hex colors
  if bgColor.hex then
    bgColor = Color.fromHex(bgColor.hex)
  end
  if textColor.hex then
    textColor = Color.fromHex(textColor.hex)
  end

  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})

  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = bgColor,
    roundedRectRadii = {xRadius = cornerRadius, yRadius = cornerRadius},
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
      textFont = t.textIconFont,
      textSize = fontSize,
    })
  end

  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
end

--------------------------------------------------------------------------------
-- Symbol icons (Phosphor replacements)
--------------------------------------------------------------------------------

--- Predefined icon symbols for common actions
--- These use Unicode symbols that render well at icon sizes
M.symbols = {
  ["app-window"] = "☐",
  ["monitor"] = "🖥",
  ["chat"] = "💬",
  ["translate"] = "文",
  ["speaker-high"] = "🔊",
  ["globe"] = "🌐",
  ["folder"] = "📁",
  ["file"] = "📄",
  ["terminal"] = ">_",
  ["mail"] = "✉",
  ["calendar"] = "📅",
  ["search"] = "🔍",
  ["settings"] = "⚙",
  ["music"] = "♫",
  ["video"] = "▶",
  ["microphone"] = "🎤",
  ["keyboard"] = "⌨",
}

--- Create an icon using a predefined symbol (Phosphor replacement)
--- @param name string Symbol name from M.symbols
--- @param weight string|nil Ignored (for GridCraft API compatibility)
--- @return hs.image The generated icon
function M.symbol(name, weight)
  local sym = M.symbols[name]
  if not sym then
    sym = string.upper(string.sub(name or "?", 1, 1))
  end
  return M.placeholder(name, sym)
end

--- Compatibility alias for GridCraft's Icon.phosphor()
M.phosphor = M.symbol

--------------------------------------------------------------------------------
-- Utility icons
--------------------------------------------------------------------------------

--- Create an empty/transparent icon
--- @param size number|nil Optional size (default from theme)
--- @return hs.image A transparent image
function M.empty(size)
  size = size or Theme.default.iconSize
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
