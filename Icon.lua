--- === hs_grid_hammer.Icon ===
---
--- Icon generation and loading. Canvas-generated icons (symbol/fromText)
--- are memoized by input so identical calls return the same hs.image.

local Color = dofile(hs.spoons.resourcePath("Color.lua"))
local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))

local M = {}

--------------------------------------------------------------------------------
-- macOS-loaded icons (no cache — caller stores result in action.icon)
--------------------------------------------------------------------------------

function M.fromFile(filePath, size)
  if not filePath then return nil end
  size = size or Theme.default.iconSize
  local image = hs.image.imageFromPath(filePath)
  return image and image:setSize({w = size, h = size}) or nil
end

function M.fromPath(path, size)
  if not path then return nil end
  size = size or Theme.default.iconSize
  local image = hs.image.iconForFile(path)
  return image and image:setSize({w = size, h = size}) or nil
end

function M.fromBundleID(bundleID, size)
  if not bundleID then return nil end
  size = size or Theme.default.iconSize
  local image = hs.image.imageFromAppBundle(bundleID)
  return image and image:setSize({w = size, h = size}) or nil
end

--------------------------------------------------------------------------------
-- Canvas-generated icons (memoized)
--------------------------------------------------------------------------------

--- Create a placeholder icon: colored rect + centered character.
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

--- Multi-line text icon (StreamDeck-style).
local function buildTextIcon(label, options)
  options = options or {}
  local t = Theme.default

  local size = options.size or t.iconSize
  local bgColor = options.backgroundColor or t.textIconBackground
  local textColor = options.textColor or {white = 1.0}
  local fontSize = options.fontSize or t.textIconDefaultSize
  local cornerRadius = t.textIconCornerRadius

  if bgColor.hex then bgColor = Color.fromHex(bgColor.hex) end
  if textColor.hex then textColor = Color.fromHex(textColor.hex) end

  local canvas = hs.canvas.new({x = 0, y = 0, w = size, h = size})
  canvas:insertElement({
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = size, h = size},
    fillColor = bgColor,
    roundedRectRadii = {xRadius = cornerRadius, yRadius = cornerRadius},
  })

  local lines = {}
  for line in (label .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(lines, line)
  end

  local lineSpacing = t.textIconLineSpacing
  local margin = t.textIconMargin
  local lineHeight = fontSize + lineSpacing
  local startY = (size - #lines * lineHeight) / 2

  for i, line in ipairs(lines) do
    canvas:insertElement({
      type = "text",
      frame = {x = margin, y = startY + (i - 1) * lineHeight, w = size - margin * 2, h = lineHeight},
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

local textCache = {}
function M.fromText(label, options)
  if options then return buildTextIcon(label, options) end
  local cached = textCache[label]
  if cached then return cached end
  local image = buildTextIcon(label, nil)
  textCache[label] = image
  return image
end

--------------------------------------------------------------------------------
-- Symbol icons (Phosphor replacements)
--------------------------------------------------------------------------------

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

local symbolCache = {}
function M.symbol(name)
  local cached = symbolCache[name]
  if cached then return cached end
  local sym = M.symbols[name] or string.upper(string.sub(name or "?", 1, 1))
  local image = M.placeholder(name, sym)
  symbolCache[name] = image
  return image
end

M.phosphor = M.symbol  -- GridCraft compatibility

return M
