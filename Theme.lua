--- === hs_grid_hammer.Theme ===
---
--- Visual constants for grid rendering.
--- Extracted from GridCraft CSS with canvas-compatible color formats.

local M = {}

--- Default theme matching GridCraft visual style
M.default = {
  -- Background for the entire grid overlay
  backgroundColor = {red = 0.1, green = 0.1, blue = 0.1, alpha = 0.95},

  -- Cell appearance
  cellBackground = {red = 0.14, green = 0.14, blue = 0.14, alpha = 0.9},  -- rgba(36,36,36,0.9)
  cellBorder = {white = 0.67, alpha = 1.0},  -- rgb(172,172,172)
  cellBorderWidth = 2,
  cellWidth = 100,
  cellHeight = 100,
  cellSpacing = 16,  -- 1em ≈ 16px
  cellCornerRadius = 6,

  -- Selection highlight (instant color change)
  cellSelected = {red = 0.63, green = 0.63, blue = 0.63, alpha = 1.0},  -- rgba(160,160,160,1)

  -- Empty cell styling (dimmed)
  cellEmptyAlpha = 0.5,
  cellEmptyBorderDashed = true,

  -- Icon
  iconSize = 64,
  iconTopMargin = 6,

  -- Text colors
  textColor = {white = 1.0, alpha = 1.0},
  textColorDimmed = {white = 0.5, alpha = 1.0},

  -- Hotkey label (bottom-left)
  hotkeyFont = "Helvetica Bold",
  hotkeyFontSize = 14,
  hotkeyInsetX = 6,
  hotkeyInsetY = 4,

  -- Description label (bottom-right)
  descriptionFont = "Helvetica Neue",
  descriptionFontSize = 10,
  descriptionInsetX = 6,
  descriptionInsetY = 4,

  -- Animation
  fadeTime = 0.15,
}

--- Create a new theme by merging overrides with defaults
--- @param overrides table Optional table of values to override
--- @return table New theme with overrides applied
function M.new(overrides)
  if not overrides then
    return M.default
  end

  local theme = {}
  for k, v in pairs(M.default) do
    theme[k] = v
  end
  for k, v in pairs(overrides) do
    theme[k] = v
  end
  return theme
end

return M
