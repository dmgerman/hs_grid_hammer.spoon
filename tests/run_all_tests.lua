--- Run all hs_grid_hammer tests
--- Execute in Hammerspoon console: dofile("/Users/dmg/.hammerspoon/Spoons/hs_grid_hammer.spoon/tests/run_all_tests.lua")

print("============================================")
print("hs_grid_hammer Test Suite")
print("============================================")

-- Helper to run test file and catch errors
local function runTest(name, path)
  print(string.format("\n>>> Running %s...", name))
  local ok, err = pcall(function()
    dofile(path)
  end)
  if not ok then
    print(string.format("FAILED: %s", err))
    return false
  end
  return true
end

local basePath = "/Users/dmg/.hammerspoon/Spoons/hs_grid_hammer.spoon/"

-- Run Phase 1 tests (non-visual parts only for automated testing)
print("\n=== Phase 1: Core Infrastructure ===")

local Theme = dofile(basePath .. "Theme.lua")
assert(Theme.default.cellWidth == 100, "Theme has cellWidth")
assert(Theme.default.cellHeight == 100, "Theme has cellHeight")
print("✓ Theme.lua loads correctly")

local KeyMap = dofile(basePath .. "KeyMap.lua")
local km = KeyMap.new()
km:add({}, "e", {name = "test1"})
km:add({"cmd"}, "e", {name = "test2"})
km:add({"cmd", "shift"}, "e", {name = "test3"})
assert(km:lookup({}, "e").name == "test1", "Plain key lookup")
assert(km:lookup({"cmd"}, "e").name == "test2", "Cmd+key lookup")
assert(km:lookup({"shift", "cmd"}, "e").name == "test3", "Mod order independent")
assert(km:lookup({}, "x") == nil, "Missing key returns nil")
print("✓ KeyMap.lua O(1) lookup works")

local CanvasRenderer = dofile(basePath .. "CanvasRenderer.lua")
local testActions = {
  {{key = "q", keyId = "1x1", description = "Test Q"}, {key = "w", keyId = "1x2", description = "Test W"}},
}
local renderer = CanvasRenderer.new(testActions, Theme.default)
local rows, cols = renderer:gridDimensions()
assert(rows == 1 and cols == 2, "Grid dimensions correct")
print("✓ CanvasRenderer.lua loads correctly")

-- Run Phase 3 tests (IconLoader)
print("\n=== Phase 3: IconLoader ===")
local IconLoader = dofile(basePath .. "IconLoader.lua")
IconLoader.clear()

local placeholder = IconLoader.placeholder("Test")
assert(placeholder ~= nil, "Placeholder generated")
print("✓ IconLoader.placeholder() works")

-- Run Phase 4 tests (Integration)
print("\n=== Phase 4: Integration ===")

hs.loadSpoon("hs_grid_hammer")
assert(spoon.hs_grid_hammer ~= nil, "Spoon loaded")
print("✓ Spoon loaded")

assert(spoon.hs_grid_hammer.Grid ~= nil, "Grid exported")
assert(spoon.hs_grid_hammer.Action ~= nil, "Action exported")
print("✓ All modules exported")

local appAction = spoon.hs_grid_hammer.Action.new({key = "f", application = "Finder"})
assert(appAction.applicationPath ~= nil, "App action resolved path")
print("✓ Action.new({application}) works")

local Util = spoon.hs_grid_hammer.Util
assert(Util.findApplicationPath("Finder") ~= nil, "Found Finder")
print("✓ Util.findApplicationPath() works")

print("\n============================================")
print("All automated tests passed!")
print("============================================")
print("\nTo run visual tests, execute:")
print('  dofile(hs.spoons.resourcePath("tests/test_phase1.lua"))')
print('  dofile(hs.spoons.resourcePath("tests/test_phase2.lua"))')
print('  dofile(hs.spoons.resourcePath("tests/test_phase4.lua"))')
