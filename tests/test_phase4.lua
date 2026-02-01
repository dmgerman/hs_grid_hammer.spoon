--- Phase 4 Tests: Full Integration / API Compatibility
--- Run with: hs.loadSpoon("hs_grid_hammer"); dofile(hs.spoons.resourcePath("tests/test_phase4.lua"))

print("\n=== Phase 4: Integration Tests ===")

-- Load the spoon
local spoon_hs_grid_hammer = hs.loadSpoon("hs_grid_hammer")
assert(spoon_hs_grid_hammer ~= nil, "Spoon loaded")
print("✓ hs.loadSpoon('hs_grid_hammer') succeeded")

-- Test spoon metadata
assert(spoon.hs_grid_hammer.name == "hs_grid_hammer", "Spoon has name")
assert(spoon.hs_grid_hammer.version ~= nil, "Spoon has version")
print("✓ Spoon metadata present: " .. spoon.hs_grid_hammer.name .. " v" .. spoon.hs_grid_hammer.version)

-- Test module exports
assert(spoon.hs_grid_hammer.Grid ~= nil, "Grid exported")
assert(spoon.hs_grid_hammer.Action ~= nil, "Action exported")
assert(spoon.hs_grid_hammer.Configuration ~= nil, "Configuration exported")
assert(spoon.hs_grid_hammer.Theme ~= nil, "Theme exported")
assert(spoon.hs_grid_hammer.IconLoader ~= nil, "IconLoader exported")
assert(spoon.hs_grid_hammer.Chooser ~= nil, "Chooser exported")
assert(spoon.hs_grid_hammer.Util ~= nil, "Util exported")
print("✓ All modules exported")

-- Test Action.new() with various types
print("\n--- Testing Action.new() ---")

local appAction = spoon.hs_grid_hammer.Action.new({
  key = "f",
  application = "Finder",
})
assert(appAction.key == "f", "App action has key")
assert(appAction.application == "Finder", "App action has application")
assert(appAction.applicationPath ~= nil, "App action has path")
assert(type(appAction.handler) == "function", "App action has handler")
print("✓ Action.new({application = 'Finder'}) works")

local fileAction = spoon.hs_grid_hammer.Action.new({
  key = "h",
  file = os.getenv("HOME"),
})
assert(fileAction.key == "h", "File action has key")
assert(fileAction.file == os.getenv("HOME"), "File action has file")
print("✓ Action.new({file = '~'}) works")

local emptyAction = spoon.hs_grid_hammer.Action.new({
  key = "x",
  empty = true,
})
assert(emptyAction.empty == true, "Empty action is empty")
print("✓ Action.new({empty = true}) works")

local customAction = spoon.hs_grid_hammer.Action.new({
  key = "c",
  description = "Custom",
  handler = function() print("Custom handler!") end,
})
assert(customAction.description == "Custom", "Custom action has description")
print("✓ Action.new({handler = fn}) works")

local spacer = spoon.hs_grid_hammer.Action.spacer()
assert(spacer.key == nil, "Spacer has no key")
print("✓ Action.spacer() works")

-- Test Configuration
print("\n--- Testing Configuration ---")
local config = spoon.hs_grid_hammer.Configuration.new()
assert(config.animationMs == 150, "Config has animationMs")
assert(config:animationSeconds() == 0.15, "Config animationSeconds() works")
print("✓ Configuration.new() works")

config:merge({animationMs = 200})
assert(config.animationMs == 200, "Config merge works")
print("✓ Configuration:merge() works")

-- Test Util functions
print("\n--- Testing Util ---")
local Util = spoon.hs_grid_hammer.Util

local finderPath = Util.findApplicationPath("Finder")
assert(finderPath ~= nil, "Found Finder path")
print("✓ Util.findApplicationPath('Finder') = " .. finderPath)

local basename = Util.getBasename("/Users/test/Documents/file.txt")
assert(basename == "file.txt", "Basename extraction works")
print("✓ Util.getBasename() works")

local mods = Util.formatModifiers({"cmd", "shift"}, "symbols")
assert(mods == "⌘⇧", "Symbol format works")
print("✓ Util.formatModifiers() works: " .. mods)

-- Test Chooser
print("\n--- Testing Chooser ---")
local testActions = {
  {
    {key = "a", description = "Action A", handler = function() end},
    {key = "b", description = "Action B", handler = function() end},
  },
}
local choices, actions = spoon.hs_grid_hammer.Chooser.fromActionTable(testActions)
assert(#choices == 2, "Chooser created 2 choices")
print("✓ Chooser.fromActionTable() works")

-- Test full Grid creation with GridCraft-compatible API
print("\n--- Testing Grid Creation ---")

local testGrid = spoon.hs_grid_hammer.Grid.new(
  {"cmd", "ctrl"}, "g",
  {
    {
      spoon.hs_grid_hammer.Action.new({key = "f", application = "Finder"}),
      spoon.hs_grid_hammer.Action.new({key = "t", application = "Terminal"}),
      spoon.hs_grid_hammer.Action.new({key = "s", application = "Safari"}),
    },
    {
      spoon.hs_grid_hammer.Action.new({key = "e", empty = true}),
      spoon.hs_grid_hammer.Action.new({
        key = "c",
        handler = function() print("Custom action executed!") end,
        description = "Custom"
      }),
      spoon.hs_grid_hammer.Action.spacer(),
    },
  },
  "Integration Test Grid"
)

assert(testGrid ~= nil, "Grid created")
assert(testGrid.modal ~= nil, "Grid has modal")
assert(testGrid.renderer ~= nil, "Grid has renderer")
assert(testGrid.keyMap:count() == 5, "Grid keyMap has 5 keys (excluding spacer)")
print("✓ Grid.new() with full action table works")
print("  KeyMap entries: " .. testGrid.keyMap:count())
print("  Valid keys: " .. testGrid.keyMap:validKeysString())

-- Visual test
print("\n--- Visual Integration Test ---")
print("Showing grid for 4 seconds...")
print("Try pressing: F (Finder), T (Terminal), S (Safari), C (Custom)")
print("Or press Escape / Cmd+Ctrl+G to close")

testGrid:start()

hs.timer.doAfter(4, function()
  if testGrid.isShowing then
    testGrid:stop()
    print("\n--- Auto-closed after 4 seconds ---")
  end

  print("\n=== Phase 4 Tests Complete ===")
  print("All API compatibility tests passed!")
end)
