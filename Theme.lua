--- === hs_grid_hammer.Theme ===
---
--- Visual constants for grid rendering.
--- Extracted from GridCraft CSS with canvas-compatible color formats.
---
--- All visual magic numbers are centralized here for easy customization.

local M = {}

--- Default theme matching GridCraft visual style
M.default = {
  -- Grid overlay background
  backgroundColor = {red = 0.1, green = 0.1, blue = 0.1, alpha = 0.95},
  gridCornerRadius = 10,

  -- Cell appearance
  cellBackground = {red = 0.14, green = 0.14, blue = 0.14, alpha = 0.9},
  cellBorder = {white = 0.67, alpha = 1.0},
  cellBorderWidth = 2,
  cellWidth = 100,
  cellHeight = 100,
  cellSpacing = 16,
  cellCornerRadius = 6,

  -- Selection highlight
  cellSelected = {red = 0.63, green = 0.63, blue = 0.63, alpha = 1.0},

  -- Empty cell styling
  cellEmptyAlpha = 0.5,

  -- Icon settings
  iconSize = 64,
  iconTopMargin = 6,
  iconCornerRadius = 8,

  -- Placeholder icon settings (colored rect with letter)
  placeholderFont = "Helvetica Bold",
  placeholderTextRatio = 0.5,      -- Text size as ratio of icon size
  placeholderTextOffsetRatio = 0.2, -- Vertical offset as ratio of icon size

  -- Text icon settings (multi-line text icons)
  textIconCornerRadius = 6,
  textIconFont = "Helvetica Bold",
  textIconDefaultSize = 12,
  textIconBackground = {red = 0.1, green = 0.1, blue = 0.1, alpha = 1.0},

  -- Text colors
  textColor = {white = 1.0, alpha = 1.0},
  textColorDimmed = {white = 0.5, alpha = 1.0},

  -- Hotkey label (bottom-left of cell)
  hotkeyFont = "Helvetica Bold",
  hotkeyFontSize = 14,
  hotkeyInsetX = 6,
  hotkeyInsetY = 4,

  -- Description label (bottom-right of cell)
  descriptionFont = "Helvetica Neue",
  descriptionFontSize = 10,
  descriptionInsetX = 6,
  descriptionInsetY = 4,

  -- Animation
  fadeTime = 0.15,
  animationDelay = 0.05,
}

--- Create a new theme by merging overrides with defaults
--- @param overrides table|nil Optional table of values to override
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
