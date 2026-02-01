--- === hs_grid_hammer.Color ===
---
--- Color utilities for generating consistent, deterministic colors.
--- Centralizes HSL-to-RGB conversion and placeholder color generation.

local M = {}

--- Convert HSL color to RGB.
---
--- @param h number Hue (0-1)
--- @param s number Saturation (0-1)
--- @param l number Lightness (0-1)
--- @return number red (0-1)
--- @return number green (0-1)
--- @return number blue (0-1)
function M.hslToRgb(h, s, l)
  if s == 0 then
    return l, l, l  -- Achromatic (gray)
  end

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

  return hue2rgb(p, q, h + 1/3),
         hue2rgb(p, q, h),
         hue2rgb(p, q, h - 1/3)
end

--- Generate a deterministic hue from a string using a simple hash.
---
--- @param str string Input string
--- @return number Hue value (0-1)
function M.hashToHue(str)
  local hash = 0
  for i = 1, #(str or "") do
    hash = (hash * 31 + string.byte(str, i)) % 360
  end
  return hash / 360
end

--- Generate a deterministic color from a string.
--- Uses the string's hash to pick a hue with fixed saturation/lightness.
---
--- @param str string Input string to derive color from
--- @param saturation number Optional saturation (default 0.5)
--- @param lightness number Optional lightness (default 0.4)
--- @return table Color table {red, green, blue, alpha}
function M.fromString(str, saturation, lightness)
  local h = M.hashToHue(str)
  local s = saturation or 0.5
  local l = lightness or 0.4

  local r, g, b = M.hslToRgb(h, s, l)

  return {
    red = r,
    green = g,
    blue = b,
    alpha = 1.0,
  }
end

--- Parse a hex color string to color table.
---
--- @param hex string Hex color string (e.g., "#FF5733" or "FF5733")
--- @return table Color table {red, green, blue, alpha}
function M.fromHex(hex)
  hex = hex:gsub("#", "")
  return {
    red = tonumber(hex:sub(1, 2), 16) / 255,
    green = tonumber(hex:sub(3, 4), 16) / 255,
    blue = tonumber(hex:sub(5, 6), 16) / 255,
    alpha = 1.0,
  }
end

--- Create a color table with alpha applied.
---
--- @param color table Base color {red, green, blue, alpha}
--- @param alpha number Alpha multiplier (0-1)
--- @return table New color table with adjusted alpha
function M.withAlpha(color, alpha)
  return {
    red = color.red or color.white,
    green = color.green or color.white,
    blue = color.blue or color.white,
    alpha = (color.alpha or 1.0) * alpha,
  }
end

return M
