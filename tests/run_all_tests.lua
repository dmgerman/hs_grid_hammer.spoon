--- Run all hs_grid_hammer tests
--- Execute in Hammerspoon console: dofile("/Users/dmg/.hammerspoon/Spoons/hs_grid_hammer.spoon/tests/run_all_tests.lua")

print("============================================")
print("hs_grid_hammer Test Suite")
print("============================================")

local basePath = "/Users/dmg/.hammerspoon/Spoons/hs_grid_hammer.spoon/"

-- Phase 1: Core infrastructure
print("\n=== Phase 1: Core Infrastructure ===")

local Theme = dofile(basePath .. "Theme.lua")
assert(Theme.default.cellWidth == 100, "Theme has cellWidth")
assert(Theme.default.cellHeight == 100, "Theme has cellHeight")
print("✓ Theme.lua loads correctly")

local CanvasRenderer = dofile(basePath .. "CanvasRenderer.lua")
local testActions = {
  {{key = "q", keyId = "1x1", description = "Test Q"}, {key = "w", keyId = "1x2", description = "Test W"}},
}
local renderer = CanvasRenderer.new(testActions, Theme.default)
local rows, cols = renderer:gridDimensions()
assert(rows == 1 and cols == 2, "Grid dimensions correct")
print("✓ CanvasRenderer.lua loads correctly")

-- Phase 4: Integration
print("\n=== Phase 4: Integration ===")

hs.loadSpoon("hs_grid_hammer")
assert(spoon.hs_grid_hammer ~= nil, "Spoon loaded")
print("✓ Spoon loaded")

assert(spoon.hs_grid_hammer.Grid ~= nil, "Grid exported")
assert(spoon.hs_grid_hammer.Action ~= nil, "Action exported")
print("✓ Public modules exported")

local appAction = spoon.hs_grid_hammer.Action.new({key = "f", application = "Finder"})
assert(appAction.applicationPath ~= nil, "App action resolved path")
assert(appAction.icon ~= nil, "App action loaded icon eagerly")
print("✓ Action.new({application}) works")

print("\n============================================")
print("All automated tests passed!")
print("============================================")
print("\nTo run visual tests, execute:")
print('  dofile(hs.spoons.resourcePath("tests/test_phase1.lua"))')
print('  dofile(hs.spoons.resourcePath("tests/test_phase2.lua"))')
print('  dofile(hs.spoons.resourcePath("tests/test_phase4.lua"))')
