--- Phase 1 Tests: Core Infrastructure
--- Run with: hs.loadSpoon("hs_grid_hammer"); dofile(hs.spoons.resourcePath("tests/test_phase1.lua"))

local spoonPath = hs.spoons.resourcePath("")

-- Test Theme.lua
print("\n=== Testing Theme.lua ===")
local Theme = dofile(spoonPath .. "Theme.lua")
assert(Theme.default.cellWidth == 100, "Theme has cellWidth")
assert(Theme.default.cellHeight == 100, "Theme has cellHeight")
assert(Theme.default.iconSize == 64, "Theme has iconSize")
assert(Theme.default.backgroundColor.alpha == 0.1, "Theme has backgroundColor")
print("✓ Theme.lua loads and has expected values")

-- Test Theme.new() with overrides
local customTheme = Theme.new({cellWidth = 150})
assert(customTheme.cellWidth == 150, "Custom theme has override")
assert(customTheme.cellHeight == 100, "Custom theme inherits defaults")
print("✓ Theme.new() merges overrides correctly")

-- Test KeyMap.lua
print("\n=== Testing KeyMap.lua ===")
local KeyMap = dofile(spoonPath .. "KeyMap.lua")
local km = KeyMap.new()

-- Test basic add/lookup
km:add({}, "e", {name = "test1"})
km:add({"cmd"}, "e", {name = "test2"})
km:add({"cmd", "shift"}, "e", {name = "test3"})
km:add({"shift", "cmd"}, "x", {name = "test4"})  -- Different mod order

assert(km:lookup({}, "e").name == "test1", "Plain key lookup")
assert(km:lookup({"cmd"}, "e").name == "test2", "Cmd+key lookup")
assert(km:lookup({"cmd", "shift"}, "e").name == "test3", "Cmd+Shift+key lookup")
assert(km:lookup({"shift", "cmd"}, "e").name == "test3", "Mod order independent (lookup)")
assert(km:lookup({}, "x") == nil, "Missing key returns nil")
print("✓ KeyMap add/lookup works")

-- Test has()
assert(km:has({}, "e") == true, "has() returns true for bound key")
assert(km:has({}, "z") == false, "has() returns false for unbound key")
print("✓ KeyMap.has() works")

-- Test count()
assert(km:count() == 4, "count() returns correct number")
print("✓ KeyMap.count() works")

-- Test validKeysString()
local validStr = km:validKeysString()
assert(validStr:find("E") ~= nil, "validKeysString contains E")
assert(validStr:find("Cmd") ~= nil, "validKeysString contains Cmd")
print("✓ KeyMap.validKeysString() works: " .. validStr)

-- Test CanvasRenderer.lua (visual test)
print("\n=== Testing CanvasRenderer.lua ===")
local CanvasRenderer = dofile(spoonPath .. "CanvasRenderer.lua")

local testActions = {
  {
    {key = "q", keyId = "1x1", description = "Test Q"},
    {key = "w", keyId = "1x2", description = "Test W"},
    {key = "e", keyId = "1x3", description = "Test E"},
  },
  {
    {key = "a", keyId = "2x1", description = "Test A"},
    {key = "s", keyId = "2x2", description = "Test S", empty = true},
    {key = "d", keyId = "2x3", description = "Test D"},
  },
}

local renderer = CanvasRenderer.new(testActions, Theme.default)

-- Test dimensions
local rows, cols = renderer:gridDimensions()
assert(rows == 2, "Grid has 2 rows")
assert(cols == 3, "Grid has 3 cols")
print("✓ CanvasRenderer.gridDimensions() works")

local width, height = renderer:canvasSize()
assert(width > 0, "Canvas has width")
assert(height > 0, "Canvas has height")
print(string.format("✓ CanvasRenderer.canvasSize() = %dx%d", width, height))

-- Visual test
print("\n=== Visual Test ===")
print("Showing 2x3 grid for 3 seconds...")
renderer:show()
hs.timer.doAfter(3, function()
  renderer:hide()
  print("✓ CanvasRenderer show/hide complete")
  print("\n=== Phase 1 Tests Complete ===")
end)
