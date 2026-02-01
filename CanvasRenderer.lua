--- === hs_grid_hammer.CanvasRenderer ===
---
--- Native canvas rendering for the grid.
--- Replaces GridCraft's WebView with hs.canvas for 10-100x faster rendering.

local Theme = dofile(hs.spoons.resourcePath("Theme.lua"))
local Color = dofile(hs.spoons.resourcePath("Color.lua"))

local M = {}
M.__index = M

--- Create a new CanvasRenderer
---
--- @param actionTable table 2D array of actions (rows of columns)
--- @param theme table Optional theme overrides
--- @return table CanvasRenderer instance
function M.new(actionTable, theme)
  local self = setmetatable({}, M)
  self.actionTable = actionTable
  self.theme = theme or Theme.default
  self.canvas = nil
  self.cellElements = {}  -- Map of keyId -> {bgIndex, iconIndex, hotkeyIndex, descIndex}
  return self
end

--- Calculate grid dimensions from action table
--- @return number rows, number cols, number maxCols
function M:gridDimensions()
  local rows = #self.actionTable
  local maxCols = 0
  for _, row in ipairs(self.actionTable) do
    maxCols = math.max(maxCols, #row)
  end
  return rows, maxCols
end

--- Calculate canvas size based on grid dimensions
--- @return number width, number height
function M:canvasSize()
  local rows, cols = self:gridDimensions()
  local t = self.theme

  local width = (cols * t.cellWidth) + ((cols + 1) * t.cellSpacing)
  local height = (rows * t.cellHeight) + ((rows + 1) * t.cellSpacing)

  return width, height
end

--- Get centered position on main screen
--- @return number x, number y
function M:centeredPosition()
  local width, height = self:canvasSize()
  local screen = hs.screen.mainScreen()
  local frame = screen:frame()

  local x = frame.x + (frame.w - width) / 2
  local y = frame.y + (frame.h - height) / 2

  return x, y
end

--- Build canvas elements array
--- @return table Array of canvas element definitions
function M:buildElements()
  local elements = {}
  local t = self.theme
  local width, height = self:canvasSize()

  -- 1. Background rectangle
  table.insert(elements, {
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = width, h = height},
    fillColor = t.backgroundColor,
    roundedRectRadii = {xRadius = 10, yRadius = 10},
  })

  -- 2. Cells
  local elementIndex = 2  -- Start after background
  for rowIdx, row in ipairs(self.actionTable) do
    for colIdx, action in ipairs(row) do
      local keyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)

      -- Skip no-key cells entirely
      if action.key == nil and not action.description then
        goto continue
      end

      local cellX = t.cellSpacing + (colIdx - 1) * (t.cellWidth + t.cellSpacing)
      local cellY = t.cellSpacing + (rowIdx - 1) * (t.cellHeight + t.cellSpacing)

      local isEmpty = action.empty == true
      local isNotFound = action.notFound == true
      local cellAlpha = (isEmpty or isNotFound) and t.cellEmptyAlpha or 1.0

      -- Track element indexes for this cell
      local cellIndexes = {
        bgIndex = elementIndex,
      }

      -- Cell background
      local bgColor = {
        red = t.cellBackground.red,
        green = t.cellBackground.green,
        blue = t.cellBackground.blue,
        alpha = (t.cellBackground.alpha or 1.0) * cellAlpha,
      }
      table.insert(elements, {
        id = keyId .. "_bg",
        type = "rectangle",
        action = "fill",
        frame = {x = cellX, y = cellY, w = t.cellWidth, h = t.cellHeight},
        fillColor = bgColor,
        roundedRectRadii = {xRadius = t.cellCornerRadius, yRadius = t.cellCornerRadius},
      })
      elementIndex = elementIndex + 1

      -- Cell border
      local borderColor = {
        red = t.cellBorder.red or t.cellBorder.white,
        green = t.cellBorder.green or t.cellBorder.white,
        blue = t.cellBorder.blue or t.cellBorder.white,
        alpha = (t.cellBorder.alpha or 1.0) * cellAlpha,
      }
      table.insert(elements, {
        id = keyId .. "_border",
        type = "rectangle",
        action = "stroke",
        frame = {x = cellX, y = cellY, w = t.cellWidth, h = t.cellHeight},
        strokeColor = borderColor,
        strokeWidth = t.cellBorderWidth,
        strokeDashPattern = isEmpty and {6, 4} or nil,
        roundedRectRadii = {xRadius = t.cellCornerRadius, yRadius = t.cellCornerRadius},
      })
      elementIndex = elementIndex + 1

      -- Icon placeholder (will be updated async)
      local iconX = cellX + (t.cellWidth - t.iconSize) / 2
      local iconY = cellY + t.iconTopMargin
      cellIndexes.iconIndex = elementIndex

      if action.icon then
        -- If action already has an hs.image, use it
        table.insert(elements, {
          id = keyId .. "_icon",
          type = "image",
          frame = {x = iconX, y = iconY, w = t.iconSize, h = t.iconSize},
          image = action.icon,
          imageAlpha = cellAlpha,
        })
      else
        -- Placeholder: colored rectangle with first letter
        local placeholderColor = self:placeholderColor(action.description or action.key or "?")
        local letter = self:firstLetter(action.description or action.key or "?")

        table.insert(elements, {
          id = keyId .. "_icon_bg",
          type = "rectangle",
          action = "fill",
          frame = {x = iconX, y = iconY, w = t.iconSize, h = t.iconSize},
          fillColor = placeholderColor,
          roundedRectRadii = {xRadius = 8, yRadius = 8},
          imageAlpha = cellAlpha,
        })
        elementIndex = elementIndex + 1

        table.insert(elements, {
          id = keyId .. "_icon_letter",
          type = "text",
          frame = {x = iconX, y = iconY + 12, w = t.iconSize, h = t.iconSize - 12},
          text = letter,
          textAlignment = "center",
          textColor = {white = 1.0, alpha = cellAlpha},
          textFont = "Helvetica Bold",
          textSize = 32,
        })
      end
      elementIndex = elementIndex + 1

      -- Hotkey label (bottom-left)
      if action.key then
        local hotkeyText = self:formatHotkey(action.mods, action.key)
        local textColor = (isEmpty or isNotFound) and t.textColorDimmed or t.textColor
        cellIndexes.hotkeyIndex = elementIndex

        table.insert(elements, {
          id = keyId .. "_hotkey",
          type = "text",
          frame = {
            x = cellX + t.hotkeyInsetX,
            y = cellY + t.cellHeight - t.hotkeyFontSize - t.hotkeyInsetY - 4,
            w = t.cellWidth / 2,
            h = t.hotkeyFontSize + 4,
          },
          text = hotkeyText,
          textAlignment = "left",
          textColor = textColor,
          textFont = t.hotkeyFont,
          textSize = t.hotkeyFontSize,
        })
        elementIndex = elementIndex + 1
      end

      -- Description label (bottom-right)
      if action.description and action.description ~= "" then
        local textColor = (isEmpty or isNotFound) and t.textColorDimmed or t.textColor
        cellIndexes.descIndex = elementIndex

        table.insert(elements, {
          id = keyId .. "_desc",
          type = "text",
          frame = {
            x = cellX + t.cellWidth / 2,
            y = cellY + t.cellHeight - t.descriptionFontSize - t.descriptionInsetY - 4,
            w = t.cellWidth / 2 - t.descriptionInsetX,
            h = t.descriptionFontSize + 4,
          },
          text = action.description,
          textAlignment = "right",
          textColor = textColor,
          textFont = t.descriptionFont,
          textSize = t.descriptionFontSize,
        })
        elementIndex = elementIndex + 1
      end

      self.cellElements[keyId] = cellIndexes

      ::continue::
    end
  end

  return elements
end

--- Generate a deterministic placeholder color from a string
--- @param str string Input string (usually description or key)
--- @return table Color table
function M:placeholderColor(str)
  return Color.fromString(str)
end

--- Get first letter of a string (uppercase)
--- @param str string Input string
--- @return string First letter uppercase
function M:firstLetter(str)
  if not str or str == "" then return "?" end
  return string.upper(string.sub(str, 1, 1))
end

--- Format hotkey for display
--- @param mods table Modifier keys
--- @param key string The key
--- @return string Formatted hotkey like "Cmd+E" or "E"
function M:formatHotkey(mods, key)
  local result = ""
  if mods and #mods > 0 then
    local modMap = {cmd = "⌘", ctrl = "⌃", alt = "⌥", shift = "⇧", fn = "fn"}
    for _, mod in ipairs(mods) do
      result = result .. (modMap[string.lower(mod)] or mod)
    end
  end
  return result .. string.upper(key)
end

--- Build and show the canvas
function M:show()
  if self.canvas then
    self.canvas:delete()
  end

  local width, height = self:canvasSize()
  local x, y = self:centeredPosition()

  self.canvas = hs.canvas.new({x = x, y = y, w = width, h = height})
  self.canvas:level("overlay")
  self.canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

  local elements = self:buildElements()
  for _, element in ipairs(elements) do
    self.canvas:insertElement(element)
  end

  self.canvas:show(self.theme.fadeTime)
end

--- Hide and delete the canvas
function M:hide()
  if self.canvas then
    self.canvas:delete(self.theme.fadeTime)
    self.canvas = nil
  end
end

--- Update a cell's icon image
--- @param keyId string The cell's key ID
--- @param image hs.image The new icon image
function M:updateIcon(keyId, image)
  if not self.canvas then return end

  local indexes = self.cellElements[keyId]
  if not indexes or not indexes.iconIndex then return end

  -- Find elements by ID and update
  local iconBgId = keyId .. "_icon_bg"
  local iconLetterId = keyId .. "_icon_letter"
  local iconId = keyId .. "_icon"

  -- Remove placeholder elements if they exist
  for i = #self.canvas, 1, -1 do
    local el = self.canvas[i]
    if el and (el.id == iconBgId or el.id == iconLetterId) then
      self.canvas:removeElement(i)
    end
  end

  -- Find position for the icon
  local t = self.theme
  for rowIdx, row in ipairs(self.actionTable) do
    for colIdx, action in ipairs(row) do
      local cellKeyId = action.keyId or string.format("%dx%d", rowIdx, colIdx)
      if cellKeyId == keyId then
        local cellX = t.cellSpacing + (colIdx - 1) * (t.cellWidth + t.cellSpacing)
        local cellY = t.cellSpacing + (rowIdx - 1) * (t.cellHeight + t.cellSpacing)
        local iconX = cellX + (t.cellWidth - t.iconSize) / 2
        local iconY = cellY + t.iconTopMargin

        self.canvas:insertElement({
          id = iconId,
          type = "image",
          frame = {x = iconX, y = iconY, w = t.iconSize, h = t.iconSize},
          image = image,
        })
        return
      end
    end
  end
end

--- Highlight a cell (for selection feedback)
--- @param keyId string The cell's key ID
function M:highlightCell(keyId)
  -- Selection highlight is disabled per user request
  -- This method is kept as a no-op for API compatibility
end

return M
